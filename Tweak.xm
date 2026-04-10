#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
- (void)purchaseWithProductId:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion;
@end

@interface DTPMainViewController : UIViewController
- (BOOL)dtp_hasCachedSubscriptionAccess;
- (void)dtp_presentSubscriptionOverlayIfNeededWithReason:(id)reason force:(BOOL)force;
- (void)dtp_refreshEntitlementsSilentlyIfPossible;
- (void)dtp_checkSubscriptionOrPresentOverlayAndMaybeRefresh;
@end

%hook DTPStoreKitHelper

- (void)checkEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion {
    if (completion) {
        completion(YES, YES, [NSDate distantFuture], [NSDate date], nil);
    }
}

- (void)syncAndCheckEntitlementWithCompletion:(void (^)(BOOL hasLifetime, BOOL hasSubscription, NSDate *expiry, NSDate *signedDate, NSError *error))completion {
    if (completion) {
        completion(YES, YES, [NSDate distantFuture], [NSDate date], nil);
    }
}

- (void)resetLocalCaches {
    // ignore
}

- (void)purchaseWithProductId:(NSString *)productId completion:(void (^)(BOOL success, NSError *error))completion {
    if (completion) {
        completion(YES, nil);
    }
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

- (void)dtp_presentSubscriptionOverlayIfNeededWithReason:(id)reason force:(BOOL)force {
    // suppress
}

- (void)dtp_refreshEntitlementsSilentlyIfPossible {
    // suppress
}

- (void)dtp_checkSubscriptionOrPresentOverlayAndMaybeRefresh {
    // suppress
}

%end