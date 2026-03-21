#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 1. 定义通用 block 类型
typedef void (^VerifyCompletion)(id result, id error);

// ========== 2. Hook 所有可能涉及收据验证的类 ==========

// 2.1 SwiftyStoreKit (已知)
%hook SwiftyStoreKit
- (void)verifyReceipt:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fake = @{@"status": @0, @"receipt": @{@"in_app": @[]}};
        ((VerifyCompletion)completion)(fake, nil);
    }
}
- (void)verifyReceipt:(id)data completion:(id)completion {
    %log;
    if (completion) ((VerifyCompletion)completion)(@{@"status": @0}, nil);
}
%end

// 2.2 InAppReceiptVerificator (已知)
%hook InAppReceiptVerificator
- (void)verifyReceipt:(id)data completion:(id)completion {
    %log;
    if (completion) ((VerifyCompletion)completion)(@{@"status": @0}, nil);
}
%end

// 2.3 拦截 SKPaymentQueue 的交易处理（阻止真实购买流程）
%hook SKPaymentQueue
- (void)addPayment:(SKPayment *)payment {
    %log;
    // 直接完成交易，不实际处理
    [[SKPaymentQueue defaultQueue] finishTransaction:[[SKPaymentTransaction alloc] init]];
}
- (void)restoreCompletedTransactions {
    %log;
    // 阻止恢复购买，直接发送成功通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPaymentQueueRestoreCompletedTransactionsFinishedNotification object:self];
}
- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    %log;
    // 阻止 finish 操作
}
%end

// 2.4 拦截 SKPaymentTransaction 的状态判断
%hook SKPaymentTransaction
- (SKPaymentTransactionState)transactionState {
    %log;
    return SKPaymentTransactionStatePurchased;
}
%end

// ========== 3. Hook 可能的购买状态管理类 ==========
// 以下类名基于常见命名推测，需要根据实际应用调整

%hook PurchaseManager
- (BOOL)isProUser { return YES; }
- (BOOL)isPlusUser { return YES; }
- (NSString *)userLevel { return @"Plus"; }
- (NSArray *)purchasedProducts { return @[@"com.picsew.pro", @"com.picsew.plus"]; }
%end

%hook IAPHelper
- (BOOL)hasPurchasedProduct:(NSString *)productId {
    if ([productId containsString:@"pro"] || [productId containsString:@"plus"]) return YES;
    return %orig;
}
%end

%hook AppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)app {
    %log;
    // 在启动后强行设置状态
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    %orig;
}
%end

// ========== 4. 拦截 UserDefaults 读取 ==========
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    if ([key isEqualToString:@"isPro"] || [key isEqualToString:@"isPlus"] || [key isEqualToString:@"isPurchased"]) {
        return YES;
    }
    return %orig;
}
- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"]) return @"Plus";
    if ([key isEqualToString:@"purchasedProducts"]) return @[@"com.picsew.pro", @"com.picsew.plus"];
    return %orig;
}
- (NSString *)stringForKey:(NSString *)key {
    if ([key isEqualToString:@"purchaseLevel"]) return @"Plus";
    return %orig;
}
%end

// ========== 5. 拦截 Keychain 读取（假设使用 Keychain 存储购买凭证） ==========
%hook KeychainWrapper
- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"receipt"] || [key containsString:@"purchase"]) {
        // 返回假数据，可以是之前保存的 fake receipt
        return nil; // 或返回假数据
    }
    return %orig;
}
%end

// 初始化
%ctor {
    // 设置 UserDefaults
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:YES forKey:@"isPro"];
    [def setBool:YES forKey:@"isPlus"];
    [def setObject:@"Plus" forKey:@"purchaseLevel"];
    [def setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [def synchronize];
    
    // 打印日志，便于确认 dylib 加载
    NSLog(@"✅ ProUnlock dylib loaded.");
}