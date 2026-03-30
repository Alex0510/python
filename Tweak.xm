// Tweak.xm
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>

static void logMessage(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"🔓 UnlockPro: %@", msg);
}

static BOOL alwaysYES() { return YES; }

static void swizzleMethod(Class cls, SEL originalSelector, IMP newImp) {
    if (!cls) return;
    Method method = class_getInstanceMethod(cls, originalSelector);
    if (method) {
        method_setImplementation(method, newImp);
        logMessage(@"Swizzled %@", NSStringFromSelector(originalSelector));
    } else {
        logMessage(@"Method not found: %@", NSStringFromSelector(originalSelector));
    }
}

static void swizzleClassMethod(Class cls, SEL originalSelector, IMP newImp) {
    if (!cls) return;
    Method method = class_getClassMethod(cls, originalSelector);
    if (method) {
        method_setImplementation(method, newImp);
        logMessage(@"Swizzled class method %@", NSStringFromSelector(originalSelector));
    } else {
        logMessage(@"Class method not found: %@", NSStringFromSelector(originalSelector));
    }
}

__attribute__((constructor))
static void initialize() {
    logMessage(@"Loaded");

    // 1. 常见 VIP 类
    NSArray *classNames = @[
        @"FWStoreKitManager", @"VipManager", @"ZZMemberViewController",
        @"StoreKitManager", @"SubscriptionManager", @"PurchaseManager", @"IAPManager"
    ];
    for (NSString *className in classNames) {
        Class cls = NSClassFromString(className);
        if (!cls) continue;
        logMessage(@"Found class: %@", className);
        NSArray *boolSelectors = @[
            @"isVip", @"hasSubscribed", @"isPro", @"isPremium",
            @"isSubscribed", @"isPurchased", @"hasPro", @"hasUnlocked",
            @"isSubscriptionActive", @"isUserSubscribed"
        ];
        for (NSString *selName in boolSelectors) {
            SEL sel = NSSelectorFromString(selName);
            swizzleMethod(cls, sel, (IMP)alwaysYES);
        }
    }

    // 2. Swift 命名空间类
    NSArray *prefixes = @[@"_TtC6Follow", @"_TtC11AnyImageKit", @"_TtC14SwiftyStoreKit"];
    NSArray *suffixes = @[@"FWStoreKitManager", @"VipManager", @"ZZMemberViewController"];
    for (NSString *prefix in prefixes) {
        for (NSString *suffix in suffixes) {
            NSString *fullName = [NSString stringWithFormat:@"%@%@", prefix, suffix];
            Class cls = NSClassFromString(fullName);
            if (cls) {
                logMessage(@"Found Swift class: %@", fullName);
                for (NSString *selName in @[@"isVip", @"hasSubscribed", @"isPro"]) {
                    SEL sel = NSSelectorFromString(selName);
                    swizzleMethod(cls, sel, (IMP)alwaysYES);
                }
            }
        }
    }

    // 3. Hook NSUserDefaults
    Class ud = NSClassFromString(@"NSUserDefaults");
    if (ud) {
        SEL boolSel = @selector(boolForKey:);
        Method m = class_getInstanceMethod(ud, boolSel);
        if (m) {
            IMP orig = method_getImplementation(m);
            IMP new = imp_implementationWithBlock(^BOOL(id self, NSString *key) {
                BOOL original = ((BOOL (*)(id, SEL, NSString *))orig)(self, boolSel, key);
                if ([key containsString:@"vip"] || [key containsString:@"pro"] || [key containsString:@"subscription"]) {
                    logMessage(@"NSUserDefaults boolForKey: %@ -> YES (original %d)", key, original);
                    return YES;
                }
                return original;
            });
            method_setImplementation(m, new);
            logMessage(@"Swizzled NSUserDefaults boolForKey:");
        }
    }

    // 4. Hook SKPaymentQueue canMakePayments
    Class skq = NSClassFromString(@"SKPaymentQueue");
    if (skq) {
        swizzleClassMethod(skq, @selector(canMakePayments), (IMP)alwaysYES);
    }

    // 5. Hook SKProductsRequest start (阻止无效产品 ID 错误)
    Class skr = NSClassFromString(@"SKProductsRequest");
    if (skr) {
        SEL startSel = @selector(start);
        Method m = class_getInstanceMethod(skr, startSel);
        if (m) {
            IMP new = imp_implementationWithBlock(^(id self) {
                logMessage(@"SKProductsRequest start called, ignoring.");
            });
            method_setImplementation(m, new);
            logMessage(@"Swizzled SKProductsRequest start");
        }
    }

    // 6. 设置 UserDefaults VIP 标志
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"com.ydgn.dokacamera.isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"hasSubscribed"];
    [defaults synchronize];
    logMessage(@"Set VIP flags in NSUserDefaults");
}