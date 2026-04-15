#import <UIKit/UIKit.h>
#import "NDFloatingView.h"

%hook UIDevice

- (NSUUID *)identifierForVendor {
    return [NSUUID UUID];
}

%end

%hook NSUUID

+ (NSUUID *)UUID {
    return %orig;
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [NDFloatingView show];
    });
}}

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
