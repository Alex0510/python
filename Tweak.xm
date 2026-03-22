// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

// ============================================
// 辅助函数 - 只保留使用的
// ============================================

static void FomzPro_SetVipStatus(id obj, BOOL status) {
    SEL sel = NSSelectorFromString(@"setVipStatus:");
    if (obj && [obj respondsToSelector:sel]) {
        NSNumber *value = [NSNumber numberWithBool:status];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [obj performSelector:sel withObject:value];
        #pragma clang diagnostic pop
    }
}

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

- (BOOL)proAccessGranted {
    return YES;
}

- (long long)vipExpiredTs {
    return 4092599349;
}

%end

// ============================================
// Hook DDLoginManager - 如果类存在
// ============================================

%group FomzProGroup

%hook DDLoginManager

+ (id)sharedInstance {
    return %orig;
}

- (BOOL)vipStatus {
    return YES;
}

- (long long)vipExpiredTs {
    return 4092599349;
}

- (void)setVipStatus:(BOOL)status {
    %orig(YES);
}

- (BOOL)isVip {
    return YES;
}

- (BOOL)isPro {
    return YES;
}

%end

%end

// ============================================
// 构造函数
// ============================================
%ctor {
    NSLog(@"FomzPro Loaded - Pro Features Unlocked");
    
    // 尝试加载 DDLoginManager hook
    Class loginManagerClass = NSClassFromString(@"DDLoginManager");
    if (loginManagerClass) {
        %init(FomzProGroup);
        NSLog(@"FomzPro: DDLoginManager hooked successfully");
    } else {
        NSLog(@"FomzPro: DDLoginManager not found, using fallback");
    }
    
    // 延迟设置 VIP 状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        Class loginManagerClass2 = NSClassFromString(@"DDLoginManager");
        if (loginManagerClass2) {
            SEL sharedSel = NSSelectorFromString(@"sharedInstance");
            id loginManager = nil;
            if ([loginManagerClass2 respondsToSelector:sharedSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                loginManager = [loginManagerClass2 performSelector:sharedSel];
                #pragma clang diagnostic pop
            }
            if (loginManager) {
                FomzPro_SetVipStatus(loginManager, YES);
                NSLog(@"FomzPro: VIP Status Activated");
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" 
                                                            object:nil 
                                                          userInfo:@{@"isVip": @YES}];
    });
}