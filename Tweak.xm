#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^VerifyReceiptCompletion)(id result, id error);
static NSString *fakeReceiptPath = nil;

// 创建假收据文件（包含 Pro 购买记录）
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

// ========== 1. 伪造本地收据路径 ==========
%hook NSBundle
- (NSURL *)appStoreReceiptURL {
    if (!fakeReceiptPath) createFakeReceipt();
    return [NSURL fileURLWithPath:fakeReceiptPath];
}
%end

// ========== 2. 拦截 SwiftyStoreKit 的收据验证 ==========
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

// ========== 3. 拦截 InAppReceiptVerificator 的本地验证 ==========
%hook InAppReceiptVerificator
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

// ========== 4. 拦截交易上报 ==========
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

// ========== 5. 拦截 UserDefaults 读取 ==========
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    // 常见购买状态键
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

// ========== 6. 拦截 Keychain 读取（常见 Keychain 包装类）==========
%hook KeychainWrapper
- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"receipt"] || [key containsString:@"purchase"] || [key containsString:@"iap"]) {
        return nil; // 返回 nil 让应用认为未存储，从而使用我们伪造的收据
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

// ========== 7. 拦截网络请求（防止服务器验证）==========
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    // 如果请求是收据验证或服务器验证，返回模拟成功响应
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

// ========== 8. 拦截产品查询，使 Pro 产品返回并标记为已购买 ==========
%hook SKProductsRequest
- (void)start {
    // 不实际启动，直接返回假产品响应
    // 需要模拟 SKProductsResponse，但这里简单处理：跳过真实请求
    // 更彻底的方法是 hook SKProductsRequestDelegate 的 productsRequest:didReceiveResponse:
}
%end

%hook SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    // 修改 response.products，如果包含 Pro 产品则保留，否则添加一个假产品
    // 由于 response 是只读的，我们无法直接修改，所以选择不调用原方法，而是自己构造一个响应
    // 实际应用中，如果应用依赖产品信息，我们可以创建一个假产品对象
    // 此处简化处理，直接调用原方法，但可能仍然无法解锁 Pro
    %orig;
}
%end

// ========== 9. 模拟购买流程 ==========
%hook SKPaymentQueue
- (void)addPayment:(SKPayment *)payment {
    // 直接完成交易，模拟购买成功
    // 创建假交易并通知观察者
    SKPaymentTransaction *fakeTransaction = [[SKPaymentTransaction alloc] init];
    [fakeTransaction setValue:payment.productIdentifier forKey:@"payment.productIdentifier"];
    [fakeTransaction setValue:@(SKPaymentTransactionStatePurchased) forKey:@"transactionState"];
    // 通知观察者（应用可能监听 SKPaymentQueue 的 updatedTransactions）
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPaymentQueueRestoreCompletedTransactionsFinishedNotification object:self];
}
%end

%hook SKPaymentTransaction
- (SKPaymentTransactionState)transactionState {
    return SKPaymentTransactionStatePurchased;
}
- (SKPayment *)payment {
    return nil; // 避免进一步处理
}
%end

// ========== 10. Hook 可能存在的自定义购买管理类（根据头文件猜测）==========
// 从头文件中，我们看到 _TtC6Picsew7Setting 类，可能包含购买状态
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
%end

// 另外可能还有 _TtC6Picsew7Setting 的某些属性
%hook _TtC6Picsew7Setting
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

// 可能还有 PurchaseManager 类（虽然头文件中没有，但常见命名）
%hook PurchaseManager
- (BOOL)isProUser { return YES; }
- (BOOL)isPlusUser { return YES; }
- (NSString *)userLevel { return @"Plus"; }
%end

// ========== 11. 启动时初始化 ==========
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

// ========== 初始化 ==========
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