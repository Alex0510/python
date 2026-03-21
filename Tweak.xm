#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^VerifyReceiptCompletion)(id result, id error);
static NSString *fakeReceiptPath = nil;

static void createFakeReceipt() {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    fakeReceiptPath = [documents stringByAppendingPathComponent:@"fake_receipt"];
    NSDictionary *fakeReceiptData = @{
        @"receipt": @{
            @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
            @"in_app": @[
                @{
                    @"product_id": @"com.picsew.pro",
                    @"quantity": @1,
                    @"transaction_id": @"fake_transaction",
                    @"original_transaction_id": @"fake_original",
                    @"purchase_date": @"2024-01-01 00:00:00 Etc/GMT",
                    @"original_purchase_date": @"2024-01-01 00:00:00 Etc/GMT",
                    @"expires_date": @"2099-12-31 23:59:59 Etc/GMT"
                }
            ]
        }
    };
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:fakeReceiptData options:0 error:&error];
    [data writeToFile:fakeReceiptPath atomically:YES];
}

%hook NSBundle
- (NSURL *)appStoreReceiptURL {
    if (!fakeReceiptPath) createFakeReceipt();
    return [NSURL fileURLWithPath:fakeReceiptPath];
}
%end

%hook SwiftyStoreKit
- (void)verifyReceipt:(id)completion {
    if (completion) {
        NSDictionary *fakeReceipt = @{
            @"status": @(0),
            @"receipt": @{
                @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
                @"in_app": @[@{
                    @"product_id": @"com.picsew.pro",
                    @"quantity": @1
                }]
            }
        };
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

%hook InAppReceiptVerificator
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

%hook APMInAppPurchaseTransactionReporter
- (void)reportTransactionWithProductID:(id)productID
                         transactionID:(id)transactionID
                 originalTransactionID:(id)originalTransactionID
                   webOrderLineItemID:(id)webOrderLineItemID
                           productType:(id)productType
                          isFreeTrial:(bool)isFreeTrial
                  isIntroductoryOffer:(bool)isIntroductoryOffer
                      paymentQuantity:(long long)paymentQuantity
                          purchaseDate:(id)purchaseDate
                 originalPurchaseDate:(id)originalPurchaseDate
           subscriptionExpirationDate:(id)subscriptionExpirationDate
                     cancellationDate:(id)cancellationDate
                          environment:(id)environment
                           isVerified:(bool)isVerified {
    // 阻止上报
}
%end

%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    NSArray *proKeys = @[@"isPro", @"isPlus", @"isPurchased", @"proPurchased", @"isProUser", @"hasPro", @"proEnabled"];
    if ([proKeys containsObject:key]) {
        return YES;
    }
    return %orig;
}
- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"] || [key isEqualToString:@"userLevel"]) {
        return @"Plus";
    }
    if ([key isEqualToString:@"purchasedProducts"] || [key isEqualToString:@"iapPurchased"]) {
        return @[@"com.picsew.pro", @"com.picsew.plus"];
    }
    return %orig;
}
- (NSString *)stringForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"] || [key isEqualToString:@"userLevel"]) {
        return @"Plus";
    }
    return %orig;
}
%end

%hook KeychainWrapper
- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"receipt"] || [key containsString:@"purchase"] || [key containsString:@"iap"]) {
        return nil;
    }
    return %orig;
}
%end

%hook SSKeychain
+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account {
    if ([service containsString:@"iap"] || [service containsString:@"purchase"]) {
        return nil;
    }
    return %orig;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    if ([urlString containsString:@"apple.com/verifyReceipt"] ||
        [urlString containsString:@"picsew.com/verify"] ||
        [urlString containsString:@"api.picsew.com"]) {
        NSDictionary *fakeResponse = @{@"status": @0, @"receipt": @{}};
        NSData *fakeData = [NSJSONSerialization dataWithJSONObject:fakeResponse options:0 error:nil];
        if (completionHandler) {
            completionHandler(fakeData, nil, nil);
        }
        return nil;
    }
    return %orig;
}
%end

%hook _TtC6Picsew7Setting
- (BOOL)isProUser {
    return YES;
}
- (BOOL)isPlusUser {
    return YES;
}
- (NSString *)userLevel {
    return @"Plus";
}
- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"isPro"] || [key isEqualToString:@"isPlus"]) {
        return @YES;
    }
    if ([key isEqualToString:@"userLevel"]) {
        return @"Plus";
    }
    return %orig;
}
%end

%hook PurchaseManager
- (BOOL)isProUser { return YES; }
- (BOOL)isPlusUser { return YES; }
- (NSString *)userLevel { return @"Plus"; }
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPlus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"Plus" forKey:@"purchaseLevel"];
    [[NSUserDefaults standardUserDefaults] setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (!fakeReceiptPath) createFakeReceipt();
    return %orig;
}
%end

%ctor {
    createFakeReceipt();
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:YES forKey:@"isPro"];
    [def setBool:YES forKey:@"isPlus"];
    [def setObject:@"Plus" forKey:@"purchaseLevel"];
    [def setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [def synchronize];
    NSLog(@"✅ ProUnlock dylib loaded.");
}