#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^VerifyReceiptCompletion)(id result, id error);

static NSString *fakeReceiptPath = nil;

// 创建假收据文件
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
    NSData *data = [NSJSONSerialization dataWithJSONObject:fakeReceiptData options:0 error:nil];
    [data writeToFile:fakeReceiptPath atomically:YES];
}

// ===== 1. 伪造本地收据 =====
%hook NSBundle
- (NSURL *)appStoreReceiptURL {
    if (!fakeReceiptPath) createFakeReceipt();
    return [NSURL fileURLWithPath:fakeReceiptPath];
}
%end

// ===== 2. 拦截收据验证 =====
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

// ===== 3. 阻止交易上报 =====
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

// ===== 4. 拦截 UserDefaults 读取 =====
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    if ([key isEqualToString:@"isPro"] ||
        [key isEqualToString:@"isPlus"] ||
        [key isEqualToString:@"isPurchased"] ||
        [key isEqualToString:@"proPurchased"]) {
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

// ===== 5. 拦截 Keychain 读取（如果应用使用 Keychain 存储购买凭证）=====
%hook KeychainWrapper
- (id)objectForKey:(NSString *)key {
    // 如果是购买相关的 key，返回假数据或 nil
    if ([key containsString:@"receipt"] || [key containsString:@"purchase"] || [key containsString:@"iap"]) {
        return nil;  // 或者返回假数据，视情况而定
    }
    return %orig;
}
%end

%hook SSKeychain  // 另一个常见的 Keychain 类
+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account {
    if ([service containsString:@"iap"] || [service containsString:@"purchase"]) {
        return nil;
    }
    return %orig;
}
%end

// ===== 6. 拦截网络请求（防止服务器验证）=====
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    // 如果请求是收据验证或购买相关的服务器地址，直接返回模拟的成功响应
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

// ===== 7. Hook 可能存在自定义购买管理类（通过运行时获取）=====
// 注意：以下类名仅为猜测，实际需要通过 class-dump 或 Frida 获取
%hook PurchaseManager
- (BOOL)isProUser { return YES; }
- (BOOL)isPlusUser { return YES; }
- (NSString *)userLevel { return @"Plus"; }
%end

%hook IAPHelper
- (BOOL)hasPurchasedProduct:(NSString *)productId {
    if ([productId containsString:@"pro"] || [productId containsString:@"plus"]) return YES;
    return %orig;
}
%end

// 可能还存在其他类，比如 ProManager, PicsewIAPManager 等
%hook ProManager
- (BOOL)isPro { return YES; }
%end

%hook PicsewIAPManager
- (BOOL)isProUser { return YES; }
%end

// ===== 8. 启动时初始化 =====
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