// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

__attribute__((constructor)) static void init() {
    Class nsObjectClass = [NSObject class];
    
    // 替换 vipStatus 方法
    SEL vipStatusSel = NSSelectorFromString(@"vipStatus");
    Method method = class_getInstanceMethod(nsObjectClass, vipStatusSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        class_addMethod(nsObjectClass, vipStatusSel, imp, "B@:");
    }
    
    // 替换 isVIP 方法
    SEL isVIPSel = NSSelectorFromString(@"isVIP");
    method = class_getInstanceMethod(nsObjectClass, isVIPSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        class_addMethod(nsObjectClass, isVIPSel, imp, "B@:");
    }
    
    // 替换 isVip 方法
    SEL isVipSel = NSSelectorFromString(@"isVip");
    method = class_getInstanceMethod(nsObjectClass, isVipSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        class_addMethod(nsObjectClass, isVipSel, imp, "B@:");
    }
    
    // 替换 isProUser 方法
    SEL isProUserSel = NSSelectorFromString(@"isProUser");
    method = class_getInstanceMethod(nsObjectClass, isProUserSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        class_addMethod(nsObjectClass, isProUserSel, imp, "B@:");
    }
    
    // 替换 hasProPermission 方法
    SEL hasProSel = NSSelectorFromString(@"hasProPermission");
    method = class_getInstanceMethod(nsObjectClass, hasProSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^BOOL(id self) { return YES; });
        class_addMethod(nsObjectClass, hasProSel, imp, "B@:");
    }
    
    // 替换 vipExpiredTs 方法
    SEL expiredSel = NSSelectorFromString(@"vipExpiredTs");
    method = class_getInstanceMethod(nsObjectClass, expiredSel);
    if (method) {
        IMP imp = imp_implementationWithBlock(^long long(id self) { return 4092599349; });
        method_setImplementation(method, imp);
    } else {
        IMP imp = imp_implementationWithBlock(^long long(id self) { return 4092599349; });
        class_addMethod(nsObjectClass, expiredSel, imp, "q@:");
    }
    
    NSLog(@"FomzPro: Loaded - All Pro features unlocked");
}