#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

/* 日志宏 */
#define LOG(fmt, ...) NSLog(@"[UnlockVIP] " fmt, ##__VA_ARGS__)

/* 强制修改 UserDefaults 中的 VIP 相关键值 */
static NSArray<NSString *> *vipKeys = @[
    @"isVip", @"vipStatus", @"userType", @"isPro",
    @"hasActiveSubscription", @"isPremiumUser", @"vipExpired"
];

/* 钩子：NSUserDefaults - 返回 VIP 标志为 YES */
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    if ([vipKeys containsObject:defaultName]) {
        LOG(@"boolForKey: %@ -> YES (forced)", defaultName);
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    id obj = %orig;
    if ([vipKeys containsObject:defaultName]) {
        if (obj == nil || [obj boolValue] == NO) {
            LOG(@"objectForKey: %@ -> forced to @YES", defaultName);
            return @YES;
        }
    }
    return obj;
}

%end

/* 钩子：AppleReceiptValidator - 让收据验证永远成功 */
/* 注意：SwiftyStoreKit 中实际的验证类可能是 _TtC14SwiftyStoreKit12InAppReceipt 等 */
/* 这里使用更通用的方式：拦截 SKPaymentQueue 的交易回调 */

%hook SKPaymentQueue

- (void)addPayment:(SKPayment *)payment {
    LOG(@"拦截支付请求: %@", payment.productIdentifier);
    // 不调用真实支付，直接模拟交易成功
    // 手动构造一个成功的交易
    SKMutablePayment *mutablePayment = (SKMutablePayment *)payment;
    // 模拟交易对象
    SKPaymentTransaction *fakeTransaction = (SKPaymentTransaction *)NSClassFromString(@"SKPaymentTransaction");
    // 由于 SKPaymentTransaction 不可直接创建，我们使用 runtime 动态创建对象
    // 简单起见：直接调用 finishTransaction 并通知 observer 交易成功
    // 实际应用中应遍历所有 observer 发送更新消息
    NSArray *observers = [self valueForKey:@"observers"];
    for (id observer in observers) {
        if ([observer respondsToSelector:@selector(paymentQueue:updatedTransactions:)]) {
            // 构造一个假的 SKPaymentTransaction
            Class transactionClass = NSClassFromString(@"SKPaymentTransaction");
            id transaction = [transactionClass alloc];
            [transaction setValue:payment forKey:@"payment"];
            [transaction setValue:@(SKPaymentTransactionStatePurchased) forKey:@"transactionState"];
            [transaction setValue:[[NSUUID UUID] UUIDString] forKey:@"transactionIdentifier"];
            [transaction setValue:[NSDate date] forKey:@"transactionDate"];
            [observer paymentQueue:self updatedTransactions:@[transaction]];
        }
    }
    // 不执行原始方法，避免真实扣款
    // %orig;
}

%end

/* 钩子：SwiftyStoreKit 的收据验证完成回调（直接调用成功）*/
/* 如果上面拦截 addPayment 已生效，下面的钩子可作为备用 */

%hook _TtC14SwiftyStoreKit12InAppReceipt

// 假设存在验证方法 - (void)verifyReceipt:(id)completion
// 实际方法名需要通过 class-dump 获取，这里演示使用 performSelector 动态调用
- (void)verifyReceipt:(id)arg1 completion:(id)arg2 {
    LOG(@"InAppReceipt verifyReceipt: 强制返回成功");
    // 如果 completion 是一个 block，直接调用 block 传入成功数据
    void (^completion)(BOOL success, id result) = arg2;
    if (completion) {
        completion(YES, @{@"status": @0, @"receipt": @{}});
    }
    // 不调用原始方法
    // return %orig;
}

%end

/* 钩子：AccountViewController - 修改 UI 显示 VIP 并隐藏升级按钮 */
%hook AccountViewController

- (void)viewDidLoad {
    %orig;
    // 强制设置 VIP 标签文本
    if ([self respondsToSelector:@selector(vipOrPoint)]) {
        UILabel *vipLabel = [self performSelector:@selector(vipOrPoint)];
        vipLabel.text = @"VIP会员";
    }
    if ([self respondsToSelector:@selector(upgradeBtn)]) {
        UIButton *upgradeBtn = [self performSelector:@selector(upgradeBtn)];
        upgradeBtn.hidden = YES;
    }
    LOG(@"AccountViewController UI 已修改");
}

%end

/* 钩子：MainTunnelViewController - 移除广告和免费限制 */
%hook MainTunnelViewController

- (void)viewDidLoad {
    %orig;
    // 隐藏广告容器
    if ([self respondsToSelector:@selector(adContainer)]) {
        UIView *adContainer = [self performSelector:@selector(adContainer)];
        adContainer.hidden = YES;
    }
    // 强制设置 isFreeLine = NO (如果有该属性)
    if ([self respondsToSelector:@selector(setIsFreeLine:)]) {
        [self performSelector:@selector(setIsFreeLine:) withObject:@NO];
    }
    LOG(@"MainTunnelViewController 已去除广告");
}

%end

/* 钩子：TunnelListController - 显示所有 VIP 节点 */
%hook TunnelListController

- (void)viewDidLoad {
    %orig;
    // 强制设置 showFree = NO 并切换到 VIP 列表
    if ([self respondsToSelector:@selector(setShowFree:)]) {
        [self performSelector:@selector(setShowFree:) withObject:@NO];
    }
    if ([self respondsToSelector:@selector(changeType:)]) {
        // 假设 changeType: 接收一个布尔参数，YES=免费，NO=VIP
        [self performSelector:@selector(changeType:) withObject:@NO];
    }
    LOG(@"TunnelListController 已强制显示 VIP 节点");
}

%end

/* 初始化 */
%ctor {
    LOG("插件加载成功，开始解锁VIP功能");
    // 可选：禁用应用内的广告SDK初始化
    // 可通过修改 GADMobileAds 的配置实现
}