#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^VerifyReceiptCompletion)(id result, id error);

// 声明可能存在的类，避免编译警告
@class SwiftyStoreKit;
@class InAppReceiptVerificator;
@class APMInAppPurchaseTransactionReporter;
@class PurchaseManager;
@class IAPHelper;
@class AppDelegate;

// ========== Hook SwiftyStoreKit ==========
%hook SwiftyStoreKit
- (void)verifyReceipt:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{
            @"status": @(0),
            @"receipt": @{
                @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
                @"in_app": @[@{
                    @"product_id": @"com.picsew.pro",
                    @"quantity": @(1)
                }]
            }
        };
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

// ========== Hook InAppReceiptVerificator ==========
%hook InAppReceiptVerificator
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

// ========== Hook APMInAppPurchaseTransactionReporter (阻止上报) ==========
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
    %log;
    // 阻止上报
}
%end

// ========== Hook NSUserDefaults (强制返回已购买状态) ==========
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    if ([key isEqualToString:@"isPro"] ||
        [key isEqualToString:@"isPlus"] ||
        [key isEqualToString:@"isPurchased"]) {
        return YES;
    }
    return %orig;
}
- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"]) {
        return @"Plus";
    }
    if ([key isEqualToString:@"purchasedProducts"]) {
        return @[@"com.picsew.pro", @"com.picsew.plus"];
    }
    return %orig;
}
- (NSString *)stringForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"]) {
        return @"Plus";
    }
    return %orig;
}
%end

// ========== 可选：Hook 可能存在购买管理类 ==========
%hook PurchaseManager
- (BOOL)isProUser { return YES; }
- (BOOL)isPlusUser { return YES; }
- (NSString *)userLevel { return @"Plus"; }
- (NSArray *)purchasedProducts { return @[@"com.picsew.pro", @"com.picsew.plus"]; }
%end

%hook IAPHelper
- (BOOL)hasPurchasedProduct:(NSString *)productId {
    if ([productId containsString:@"pro"] || [productId containsString:@"plus"]) {
        return YES;
    }
    return %orig;
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    // 启动时再次强制写入 UserDefaults
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return %orig;
}
%end

// ========== 初始化 ==========
%ctor {
    // 写入 UserDefaults
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:YES forKey:@"isPro"];
    [def setBool:YES forKey:@"isPlus"];
    [def setObject:@"Plus" forKey:@"purchaseLevel"];
    [def setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [def synchronize];
    NSLog(@"✅ ProUnlock dylib loaded.");
}