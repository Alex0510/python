// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================
// 辅助函数 - 使用运行时动态调用
// ============================================

static void FomzPro_ActivateVIP() {
    Class loginManagerClass = NSClassFromString(@"DDLoginManager");
    if (loginManagerClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        id loginManager = nil;
        
        if ([loginManagerClass respondsToSelector:sharedSel]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            loginManager = [loginManagerClass performSelector:sharedSel];
            #pragma clang diagnostic pop
        }
        
        if (loginManager) {
            SEL setVipSel = NSSelectorFromString(@"setVipStatus:");
            if ([loginManager respondsToSelector:setVipSel]) {
                NSNumber *value = [NSNumber numberWithBool:YES];
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [loginManager performSelector:setVipSel withObject:value];
                #pragma clang diagnostic pop
                NSLog(@"FomzPro: VIP activated");
            }
        }
    }
}

static void FomzPro_DismissViewController(id vc) {
    SEL dismissSel = NSSelectorFromString(@"dismissViewControllerAnimated:completion:");
    if (vc && [vc respondsToSelector:dismissSel]) {
        NSNumber *animated = [NSNumber numberWithBool:YES];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [vc performSelector:dismissSel withObject:animated withObject:nil];
        #pragma clang diagnostic pop
    }
}

static id FomzPro_GetValueForKey(id obj, NSString *key) {
    SEL valueSel = NSSelectorFromString(@"valueForKey:");
    if (obj && [obj respondsToSelector:valueSel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [obj performSelector:valueSel withObject:key];
        #pragma clang diagnostic pop
    }
    return nil;
}

static void FomzPro_SetHiddenForView(id view, BOOL hidden) {
    if (view && [view respondsToSelector:@selector(setHidden:)]) {
        [view setHidden:hidden];
    }
}

static void FomzPro_SetTextForLabel(id label, NSString *text) {
    if (label && [label respondsToSelector:@selector(setText:)]) {
        [label setText:text];
    }
}

static void FomzPro_SetTextColorForLabel(id label, UIColor *color) {
    if (label && [label respondsToSelector:@selector(setTextColor:)]) {
        [label setTextColor:color];
    }
}

// ============================================
// Hook DDVipViewController - 使用 Logos
// ============================================

%hook DDVipViewController

- (void)onPayButtonTouch {
    FomzPro_ActivateVIP();
    FomzPro_DismissViewController(self);
}

- (void)onRecoveryButtonTouch {
    FomzPro_ActivateVIP();
    FomzPro_DismissViewController(self);
}

- (void)onItemViewTouchWithGesture:(id)sender {
    FomzPro_ActivateVIP();
    FomzPro_DismissViewController(self);
}

- (void)viewDidLoad {
    %orig;
    
    // 使用运行时获取视图并修改
    dispatch_async(dispatch_get_main_queue(), ^{
        id payButton = FomzPro_GetValueForKey(self, @"payButton");
        if (payButton) {
            FomzPro_SetHiddenForView(payButton, YES);
        }
        
        id payDesLabel = FomzPro_GetValueForKey(self, @"payDesLabel");
        if (payDesLabel) {
            FomzPro_SetTextForLabel(payDesLabel, @"已解锁");
            FomzPro_SetTextColorForLabel(payDesLabel, [UIColor systemGreenColor]);
        }
        
        id contentLabel = FomzPro_GetValueForKey(self, @"contentLabel");
        if (contentLabel) {
            FomzPro_SetTextForLabel(contentLabel, @"您的账户已激活Pro会员");
        }
    });
}

- (void)viewDidLayoutSubviews {
    %orig;
    
    // 确保价格标签被修改
    id payDesLabel = FomzPro_GetValueForKey(self, @"payDesLabel");
    if (payDesLabel) {
        NSString *currentText = [payDesLabel performSelector:@selector(text)];
        if (currentText && [currentText isEqualToString:@"¥"]) {
            FomzPro_SetTextForLabel(payDesLabel, @"已解锁");
            FomzPro_SetTextColorForLabel(payDesLabel, [UIColor systemGreenColor]);
        }
    }
}

- (void)back {
    FomzPro_ActivateVIP();
    %orig;
}

%end

// ============================================
// Hook NSObject - 拦截所有VIP检查方法
// ============================================

%hook NSObject

- (BOOL)vipStatus {
    return YES;
}

- (BOOL)isVIP {
    return YES;
}

- (BOOL)isVip {
    return YES;
}

- (BOOL)isProUser {
    return YES;
}

- (BOOL)hasProPermission {
    return YES;
}

- (BOOL)isPro {
    return YES;
}

- (BOOL)canUseProFeature {
    return YES;
}

- (long long)vipExpiredTs {
    return 4092599349;
}

%end

// ============================================
// 构造函数
// ============================================

%ctor {
    NSLog(@"FomzPro: Loaded");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        FomzPro_ActivateVIP();
    });
}