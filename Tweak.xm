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
        if ([loginManagerClass respondsToSelector:sharedSel]) {
            id loginManager = ((id (*)(id, SEL))objc_msgSend)(loginManagerClass, sharedSel);
            if (loginManager) {
                SEL setVipSel = NSSelectorFromString(@"setVipStatus:");
                if ([loginManager respondsToSelector:setVipSel]) {
                    ((void (*)(id, SEL, BOOL))objc_msgSend)(loginManager, setVipSel, YES);
                    NSLog(@"FomzPro: VIP activated");
                }
            }
        }
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

static void FomzPro_SetHiddenForView(id view, BOOL hidden) {
    if (view && [view respondsToSelector:@selector(setHidden:)]) {
        [view setHidden:hidden];
    }
}

// ============================================
// Hook DDSettingVipExpireCell - 修改VIP过期状态显示
// ============================================

%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)style reuseIdentifier:(NSString *)reuseIdentifier {
    %orig;
    
    // 设置 VIP 为未过期状态
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取过期标签并修改文本
        id expireLabel = FomzPro_GetValueForKey(self, @"expireLabel");
        if (expireLabel) {
            FomzPro_SetTextForLabel(expireLabel, @"永久有效");
            FomzPro_SetTextColorForLabel(expireLabel, [UIColor systemGreenColor]);
        }
        
        // 获取提示标签并修改
        id tipsLabel = FomzPro_GetValueForKey(self, @"tipsLabel");
        if (tipsLabel) {
            FomzPro_SetTextForLabel(tipsLabel, @"Pro会员");
            FomzPro_SetTextColorForLabel(tipsLabel, [UIColor systemOrangeColor]);
        }
        
        // 隐藏王冠图标（过期图标）
        id crowImageView = FomzPro_GetValueForKey(self, @"crowImageView");
        if (crowImageView) {
            FomzPro_SetHiddenForView(crowImageView, YES);
        }
        
        // 显示Pro标识
        id fomzImageView = FomzPro_GetValueForKey(self, @"fomzImageView");
        if (fomzImageView) {
            FomzPro_SetHiddenForView(fomzImageView, NO);
        }
        
        // 修改 Pro 标签文本
        id fomzLabel = FomzPro_GetValueForKey(self, @"fomzLabel");
        if (fomzLabel) {
            FomzPro_SetTextForLabel(fomzLabel, @"● 已激活");
            FomzPro_SetTextColorForLabel(fomzLabel, [UIColor systemGreenColor]);
        }
        
        // 修改背景视图样式
        id backView = FomzPro_GetValueForKey(self, @"backView");
        if (backView && [backView respondsToSelector:@selector(setBackgroundColor:)]) {
            [backView setBackgroundColor:[UIColor colorWithRed:0.95 green:0.98 blue:0.95 alpha:1.0]];
        }
    });
}

- (void)initWithCoder:(NSCoder *)coder {
    %orig;
    
    // 同样修改过期状态
    dispatch_async(dispatch_get_main_queue(), ^{
        id expireLabel = FomzPro_GetValueForKey(self, @"expireLabel");
        if (expireLabel) {
            FomzPro_SetTextForLabel(expireLabel, @"永久有效");
            FomzPro_SetTextColorForLabel(expireLabel, [UIColor systemGreenColor]);
        }
        
        id crowImageView = FomzPro_GetValueForKey(self, @"crowImageView");
        if (crowImageView) {
            FomzPro_SetHiddenForView(crowImageView, YES);
        }
        
        id fomzLabel = FomzPro_GetValueForKey(self, @"fomzLabel");
        if (fomzLabel) {
            FomzPro_SetTextForLabel(fomzLabel, @"● 已激活");
            FomzPro_SetTextColorForLabel(fomzLabel, [UIColor systemGreenColor]);
        }
    });
}

- (void)layoutSubviews {
    %orig;
    
    // 每次布局时确保显示正确
    id expireLabel = FomzPro_GetValueForKey(self, @"expireLabel");
    if (expireLabel) {
        NSString *currentText = [expireLabel performSelector:@selector(text)];
        if (currentText && [currentText containsString:@"过期"]) {
            FomzPro_SetTextForLabel(expireLabel, @"永久有效");
            FomzPro_SetTextColorForLabel(expireLabel, [UIColor systemGreenColor]);
        }
    }
    
    id crowImageView = FomzPro_GetValueForKey(self, @"crowImageView");
    if (crowImageView && !crowImageView.hidden) {
        FomzPro_SetHiddenForView(crowImageView, YES);
    }
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

- (long long)vipExpiredTs {
    return 4092599349; // 2099-01-01
}

%end

// ============================================
// 构造函数
// ============================================

%ctor {
    NSLog(@"FomzPro: DDSettingVipExpireCell tweak loaded");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        FomzPro_ActivateVIP();
    });
}