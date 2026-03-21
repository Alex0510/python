#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^VerifyReceiptCompletion)(id result, id error);

// ========== 1. 伪造本地收据文件 ==========
// 先创建一个假的收据文件路径，并写入假数据
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

// Hook NSBundle 返回假收据 URL
%hook NSBundle
- (NSURL *)appStoreReceiptURL {
    %log;
    if (!fakeReceiptPath) createFakeReceipt();
    return [NSURL fileURLWithPath:fakeReceiptPath];
}
%end

// ========== 2. Hook 收据验证类 ==========
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
                    @"quantity": @1
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

%hook InAppReceiptVerificator
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        ((VerifyReceiptCompletion)completion)(@{@"status": @(0)}, nil);
    }
}
%end

// ========== 3. 阻止交易上报 ==========
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

// ========== 4. 强制完成购买（如果应用使用 StoreKit）==========
%hook SKPaymentQueue
- (void)addPayment:(SKPayment *)payment {
    %log;
    // 直接模拟购买成功，跳过真实支付流程
    // 创建一个假交易，并通知观察者
    SKPaymentTransaction *fakeTransaction = [[SKPaymentTransaction alloc] init];
    [fakeTransaction setValue:payment.productIdentifier forKey:@"payment.productIdentifier"]; // 注意：实际可能需要正确设置
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPaymentQueueRestoreCompletedTransactionsFinishedNotification object:self];
    // 注意：这里简化处理，实际可能需要调用观察者的 updatedTransactions 方法
}
%end

%hook SKPaymentTransaction
- (SKPaymentTransactionState)transactionState {
    return SKPaymentTransactionStatePurchased;
}
- (SKPayment *)payment {
    return nil; // 避免调用
}
%end

// ========== 5. 修改 UserDefaults 读取 ==========
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

// ========== 6. Hook 产品查询，使 Pro 产品标记为已购买 ==========
%hook SKProductsRequest
- (void)start {
    %log;
    // 不实际启动，直接返回假产品数据
    // 注意：需要模拟 SKProductsResponse，包含 Pro 产品
}
%end

%hook SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    %log;
    // 修改 response.products，如果包含 Pro 产品则标记
    // 但这里无法直接修改，需要在返回前 hook
    // 我们选择更简单的方法：如果应用使用本地判断，则不必此步
}
%end

// ========== 7. 如果应用有自己的购买管理器类 ==========
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
    %log;
    // 强制写入 UserDefaults
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPlus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"Plus" forKey:@"purchaseLevel"];
    [[NSUserDefaults standardUserDefaults] setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 确保假收据存在
    if (!fakeReceiptPath) createFakeReceipt();
    return %orig;
}
%end

// ========== 初始化 ==========
%ctor {
    // 立即创建假收据并写入偏好设置
    createFakeReceipt();
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:YES forKey:@"isPro"];
    [def setBool:YES forKey:@"isPlus"];
    [def setObject:@"Plus" forKey:@"purchaseLevel"];
    [def setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [def synchronize];
    NSLog(@"✅ ProUnlock dylib loaded and fake receipt created.");
}