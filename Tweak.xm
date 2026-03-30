// UnlockPro.m
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Hook 实现

// 通用返回 YES 的 IMP
static BOOL alwaysYES() {
    return YES;
}

// 替换方法
static void swizzleMethod(Class cls, SEL originalSelector, IMP newImp) {
    Method method = class_getInstanceMethod(cls, originalSelector);
    if (method) {
        method_setImplementation(method, newImp);
        NSLog(@"✅ UnlockPro: Swizzled %@", NSStringFromSelector(originalSelector));
    } else {
        NSLog(@"⚠️ UnlockPro: Method not found - %@", NSStringFromSelector(originalSelector));
    }
}

__attribute__((constructor))
static void initialize() {
    NSLog(@"🚀 UnlockPro loaded");

    // 1. 尝试 hook FWStoreKitManager 的订阅状态判断方法
    Class fwStoreKitManager = NSClassFromString(@"FWStoreKitManager");
    if (fwStoreKitManager) {
        // 常见的方法名
        SEL possibleSelectors[] = {
            sel_registerName("hasSubscribed"),
            sel_registerName("isSubscribed"),
            sel_registerName("isVip"),
            sel_registerName("isPro")
        };
        for (int i = 0; i < sizeof(possibleSelectors)/sizeof(SEL); i++) {
            swizzleMethod(fwStoreKitManager, possibleSelectors[i], (IMP)alwaysYES);
        }
    } else {
        NSLog(@"⚠️ UnlockPro: FWStoreKitManager class not found");
    }

    // 2. 尝试 hook VipManager 的 VIP 状态判断方法
    Class vipManager = NSClassFromString(@"VipManager");
    if (vipManager) {
        SEL possibleSelectors[] = {
            sel_registerName("isVip"),
            sel_registerName("hasSubscribed"),
            sel_registerName("isPro")
        };
        for (int i = 0; i < sizeof(possibleSelectors)/sizeof(SEL); i++) {
            swizzleMethod(vipManager, possibleSelectors[i], (IMP)alwaysYES);
        }
    } else {
        NSLog(@"⚠️ UnlockPro: VipManager class not found");
    }

    // 3. 可选：直接修改 NSUserDefaults 中与 VIP 相关的键值（风险较大，谨慎使用）
    // 这里不推荐自动实现，因为可能影响其他功能
}