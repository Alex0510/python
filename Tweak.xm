#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 声明需要用到的类
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
// 可选：也 hook 购买方法
- (void)purchaseWithProductId:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion;
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
        NSDate *farFuture = [NSDate distantFuture];
        NSDate *now = [NSDate date];
        completion(YES, YES, farFuture, now, nil);
    }
}

- (void)syncAndCheckEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion {
    if (completion) {
        NSDate *farFuture = [NSDate distantFuture];
        NSDate *now = [NSDate date];
        completion(YES, YES, farFuture, now, nil);
    }
}

- (void)resetLocalCaches {
    // 忽略清除缓存
    NSLog(@"DTPUnlock: resetLocalCaches ignored");
}

// 防止触发真实购买流程（可选）
- (void)purchaseWithProductId:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion {
    if (completion) {
        completion(YES, nil);
    }
    NSLog(@"DTPUnlock: purchase intercepted, returning success");
}

%end

%hook DTPAccessDecision

- (BOOL)hasAccess {
    return YES;
}

- (void)setHasAccess:(BOOL)hasAccess {
    %orig(YES);
}

%end

%hook DTPMainViewController

- (BOOL)dtp_hasCachedSubscriptionAccess {
    return YES;
}

- (id)dtp_evaluateAccessDecisionForContext:(id)context {
    Class decisionClass = %c(DTPAccessDecision);
    id decision = [[decisionClass alloc] init];
    [decision setHasAccess:YES];
    [decision setShouldShowPaywall:NO];
    [decision setAllowDismiss:YES];
    [decision setShouldRefreshEntitlementsSilently:NO];
    [decision setReason:@"Unlocked by dylib"];
    return decision;
}

- (void)dtp_presentSubscriptionOverlayIfNeededWithReason:(id)reason force:(BOOL)force {
    NSLog(@"DTPUnlock: Suppressed subscription overlay (reason: %@, force: %d)", reason, force);
}

- (void)dtp_refreshEntitlementsSilentlyIfPossible {
    NSLog(@"DTPUnlock: Suppressed silent entitlement refresh");
}

- (void)dtp_checkSubscriptionOrPresentOverlayAndMaybeRefresh {
    NSLog(@"DTPUnlock: Suppressed subscription check overlay");
}

%end