// Tweak.xm - 纯运行时方式，无需类声明
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 辅助函数 - 安全调用方法
static void safePerformVoidMethod(id obj, SEL sel) {
    if (obj && [obj respondsToSelector:sel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [obj performSelector:sel];
        #pragma clang diagnostic pop
    }
}

static void safePerformVoidMethodWithObject(id obj, SEL sel, id param) {
    if (obj && [obj respondsToSelector:sel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [obj performSelector:sel withObject:param];
        #pragma clang diagnostic pop
    }
}

static void safeSetVipStatus(id obj, BOOL status) {
    SEL sel = NSSelectorFromString(@"setVipStatus:");
    if (obj && [obj respondsToSelector:sel]) {
        NSNumber *value = [NSNumber numberWithBool:status];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [obj performSelector:sel withObject:value];
        #pragma clang diagnostic pop
    }
}

static BOOL safeGetVipStatus(id obj) {
    SEL sel = NSSelectorFromString(@"vipStatus");
    if (obj && [obj respondsToSelector:sel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSNumber *result = [obj performSelector:sel];
        #pragma clang diagnostic pop
        return [result boolValue];
    }
    return NO;
}

// ============================================
// 动态方法替换 - 拦截所有VIP检查方法
// ============================================

// 拦截 NSObject 的通用 VIP 检查方法
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

%end

// ============================================
// 动态Hook - 使用类名字符串
// ============================================

%ctor {
    NSLog(@"FomzPro Loaded - Unlocking Pro Features");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 获取 DDLoginManager 类
        Class loginManagerClass = NSClassFromString(@"DDLoginManager");
        if (loginManagerClass) {
            // 获取 sharedInstance 方法
            SEL sharedSel = NSSelectorFromString(@"sharedInstance");
            id loginManager = nil;
            
            if ([loginManagerClass respondsToSelector:sharedSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                loginManager = [loginManagerClass performSelector:sharedSel];
                #pragma clang diagnostic pop
            }
            
            if (loginManager) {
                // 设置 VIP 状态
                safeSetVipStatus(loginManager, YES);
                NSLog(@"FomzPro: VIP Status Activated");
            }
        }
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" 
                                                            object:nil 
                                                          userInfo:@{@"isVip": @YES}];
    });
}

// ============================================
// Hook DDLoginManager - 使用动态方式
// ============================================
%hook NSObject

- (long long)vipExpiredTs {
    return 4092599349; // 2099-01-01
}

%end

// 使用 MSHookMessageEx 动态替换
#import <substrate.h>

__attribute__((constructor)) static void init() {
    // 获取 DDLoginManager 类
    Class loginManagerClass = NSClassFromString(@"DDLoginManager");
    if (loginManagerClass) {
        // 替换 vipStatus 方法
        SEL vipStatusSel = NSSelectorFromString(@"vipStatus");
        Method originalMethod = class_getInstanceMethod(loginManagerClass, vipStatusSel);
        if (originalMethod) {
            IMP imp = imp_implementationWithBlock(^BOOL(id self) {
                return YES;
            });
            method_setImplementation(originalMethod, imp);
        }
        
        // 替换 vipExpiredTs 方法
        SEL expiredSel = NSSelectorFromString(@"vipExpiredTs");
        Method expiredMethod = class_getInstanceMethod(loginManagerClass, expiredSel);
        if (expiredMethod) {
            IMP imp = imp_implementationWithBlock(^long long(id self) {
                return 4092599349;
            });
            method_setImplementation(expiredMethod, imp);
        }
        
        // 替换 setVipStatus 方法（强制设置为YES）
        SEL setVipSel = NSSelectorFromString(@"setVipStatus:");
        Method setVipMethod = class_getInstanceMethod(loginManagerClass, setVipSel);
        if (setVipMethod) {
            IMP imp = imp_implementationWithBlock(^(id self, BOOL status) {
                // 忽略传入的值，强制设置为 YES
                SEL origSel = NSSelectorFromString(@"original_setVipStatus:");
                if (!origSel) {
                    origSel = setVipSel;
                }
                void (*orig)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))method_getImplementation(setVipMethod);
                orig(self, setVipSel, YES);
            });
            method_setImplementation(setVipMethod, imp);
        }
        
        NSLog(@"FomzPro: DDLoginManager hooked");
    }
}