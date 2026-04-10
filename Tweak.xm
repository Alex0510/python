#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 声明需要用到的类（来自头文件）
@interface DTPAccessDecision : NSObject
@property BOOL hasAccess;
@property BOOL shouldShowPaywall;
@property BOOL allowDismiss;
@property BOOL shouldRefreshEntitlementsSilently;
@property (nonatomic, copy) NSString *reason;
- (void)setHasAccess:(BOOL)hasAccess;
- (void)setShouldShowPaywall:(BOOL)shouldShowPaywall;
- (void)setAllowDismiss:(BOOL)allowDismiss;
- (void)setShouldRefreshEntitlementsSilently:(BOOL)shouldRefreshEntitlementsSilently;
- (void)setReason:(NSString *)reason;
@end

@interface DTPStoreKitHelper : NSObject
- (void)checkEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion;
- (void)syncAndCheckEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion;
- (void)resetLocalCaches;
@end

@interface DTPMainViewController : UIViewController
- (BOOL)dtp_hasCachedSubscriptionAccess;
- (id)dtp_evaluateAccessDecisionForContext:(id)context;
- (void)dtp_presentSubscriptionOverlayIfNeededWithReason:(id)reason force:(BOOL)force;
- (void)dtp_refreshEntitlementsSilentlyIfPossible;
- (void)dtp_checkSubscriptionOrPresentOverlayAndMaybeRefresh;
@end

// ===== Hook 开始 =====

%hook DTPStoreKitHelper

// 使 checkEntitlementWithCompletion: 返回已授权状态
- (void)checkEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion {
    if (completion) {
        // 设置永久有效，到期时间为遥远的未来
        NSDate *farFuture = [NSDate distantFuture];
        NSDate *now = [NSDate date];
        completion(YES, YES, farFuture, now, nil);
    }
}

// 同样处理同步检查
- (void)syncAndCheckEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion {
    if (completion) {
        NSDate *farFuture = [NSDate distantFuture];
        NSDate *now = [NSDate date];
        completion(YES, YES, farFuture, now, nil);
    }
}

// 防止清除本地缓存（即使调用也不会影响我们的“假”状态）
- (void)resetLocalCaches {
    // 什么都不做，或者调用原方法但不影响结果（原方法可能会清除真实缓存，但我们不关心）
    // %orig; // 如果需要，可以调用原方法，但可能引起副作用，建议忽略
    NSLog(@"DTPUnlock: resetLocalCaches called - ignored");
}

%end

%hook DTPAccessDecision

// 确保 hasAccess 返回 YES
- (BOOL)hasAccess {
    return YES;
}

- (void)setHasAccess:(BOOL)hasAccess {
    // 强制设为 YES
    %orig(YES);
}

%end

%hook DTPMainViewController

// 直接返回 YES，表示已有缓存订阅
- (BOOL)dtp_hasCachedSubscriptionAccess {
    return YES;
}

// 返回一个完全授权的决策对象
- (id)dtp_evaluateAccessDecisionForContext:(id)context {
    // 获取原始类并创建实例
    Class decisionClass = %c(DTPAccessDecision);
    id decision = [[decisionClass alloc] init];
    [decision setHasAccess:YES];
    [decision setShouldShowPaywall:NO];
    [decision setAllowDismiss:YES];
    [decision setShouldRefreshEntitlementsSilently:NO];
    [decision setReason:@"Unlocked by dylib"];
    return decision;
}

// 阻止显示订阅弹窗
- (void)dtp_presentSubscriptionOverlayIfNeededWithReason:(id)reason force:(BOOL)force {
    // 完全忽略，不显示任何付费墙
    NSLog(@"DTPUnlock: Suppressed subscription overlay (reason: %@, force: %d)", reason, force);
}

// 阻止任何自动刷新检查（可选，避免网络请求）
- (void)dtp_refreshEntitlementsSilentlyIfPossible {
    // 什么都不做，保持假状态
    NSLog(@"DTPUnlock: Suppressed silent entitlement refresh");
}

// 阻止显示订阅相关的检查（例如进入应用时的弹窗）
- (void)dtp_checkSubscriptionOrPresentOverlayAndMaybeRefresh {
    // 什么都不做，直接认为已通过
    NSLog(@"DTPUnlock: Suppressed subscription check overlay");
}

%end

// 可选：额外 hook 一个工具类中的权限判断（如果存在）
%hook DTPStoreKitHelper (Private)
// 确保任何购买相关的方法也不会触发真实支付界面（安全）
- (void)purchaseWithProductId:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion {
    // 直接返回成功，避免弹出系统支付对话框
    if (completion) {
        completion(YES, nil);
    }
    NSLog(@"DTPUnlock: purchaseWithProductId intercepted, returning success without real purchase.");
}
%end

// 注意：%hook 的类名必须与运行时完全一致。Swift 类可能包含模块名，如 _TtC9DTPAIiPad17DTPStoreKitHelper
// 上面的 %hook 使用短类名，如果无效可改用完整的混淆名：
// %hook _TtC9DTPAIiPad17DTPStoreKitHelper
// %hook _TtC9DTPAIiPad14DTPProductInfo (不需要)
// 但 Logos 支持直接使用 Objective-C 类名（即使是 Swift 类也可以）