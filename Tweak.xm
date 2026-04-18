#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL (*orig_boolForKey)(id self, SEL _cmd, NSString *defaultName);

static BOOL new_boolForKey(id self, SEL _cmd, NSString *defaultName) {
    // 强制隐藏广告
    if ([defaultName isEqualToString:@"isAdvertisementHiddenV2"]) {
        return YES;
    }
    return orig_boolForKey(self, _cmd, defaultName);
}

__attribute__((constructor))
static void init() {
    Class cls = NSClassFromString(@"NSUserDefaults");
    SEL sel = @selector(boolForKey:);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_boolForKey = (typeof(orig_boolForKey))method_getImplementation(method);
        method_setImplementation(method, (IMP)new_boolForKey);
        NSLog(@"[TrollFoolsAdRemover] Loaded – advertisements disabled.");
    } else {
        NSLog(@"[TrollFoolsAdRemover] Failed to hook boolForKey:");
    }
}
