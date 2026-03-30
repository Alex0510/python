// UnlockPro_Enhanced.m
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>

#pragma mark - 通用返回 YES 的 IMP
static BOOL alwaysYES() {
    return YES;
}

static BOOL alwaysYESWithObject(id self, SEL _cmd, id obj) {
    return YES;
}

static BOOL alwaysYESWithInteger(id self, SEL _cmd, NSInteger integer) {
    return YES;
}

static id alwaysNil(id self, SEL _cmd) {
    return nil;
}

static void logMessage(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"🔓 UnlockPro: %@", msg);
}

static void swizzleMethod(Class cls, SEL originalSelector, IMP newImp, const char *types) {
    if (!cls) return;
    Method method = class_getInstanceMethod(cls, originalSelector);
    if (method) {
        method_setImplementation(method, newImp);
        logMessage(@"Swizzled %@", NSStringFromSelector(originalSelector));
    } else {
        logMessage(@"Method not found: %@", NSStringFromSelector(originalSelector));
    }
}

static void swizzleClassMethod(Class cls, SEL originalSelector, IMP newImp, const char *types) {
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

    // 1. 尝试多种可能的 VIP 相关类
    NSArray *classNames = @[
        @"FWStoreKitManager",
        @"VipManager",
        @"ZZMemberViewController",
        @"StoreKitManager",
        @"SubscriptionManager",
        @"PurchaseManager",
        @"IAPManager"
    ];

    for (NSString *className in classNames) {
        Class cls = NSClassFromString(className);
        if (!cls) continue;
        logMessage(@"Found class: %@", className);

        // 常见的布尔判断方法
        NSArray *boolSelectors = @[
            @"isVip", @"hasSubscribed", @"isPro", @"isPremium",
            @"isSubscribed", @"isPurchased", @"hasPro", @"hasUnlocked",
            @"isSubscriptionActive", @"isUserSubscribed"
        ];
        for (NSString *selName in boolSelectors) {
            SEL sel = NSSelectorFromString(selName);
            swizzleMethod(cls, sel, (IMP)alwaysYES, "c@:");
        }
    }

    // 2. 尝试 Swift 命名空间类（根据头文件中的模式）
    NSArray *swiftClassPrefixes = @[
        @"_TtC6Follow",  // Follow 命名空间
        @"_TtC11AnyImageKit",
        @"_TtC14SwiftyStoreKit"
    ];
    NSArray *swiftClassSuffixes = @[
        @"FWStoreKitManager",
        @"VipManager",
        @"ZZMemberViewController"
    ];
    for (NSString *prefix in swiftClassPrefixes) {
        for (NSString *suffix in swiftClassSuffixes) {
            NSString *fullName = [NSString stringWithFormat:@"%@%@", prefix, suffix];
            Class cls = NSClassFromString(fullName);
            if (cls) {
                logMessage(@"Found Swift class: %@", fullName);
                // 尝试常见的布尔方法
                NSArray *selNames = @[@"isVip", @"hasSubscribed", @"isPro"];
                for (NSString *selName in selNames) {
                    SEL sel = NSSelectorFromString(selName);
                    swizzleMethod(cls, sel, (IMP)alwaysYES, "c@:");
                }
            }
        }
    }

    // 3. Hook NSUserDefaults 中可能的 VIP key
    Class userDefaults = NSClassFromString(@"NSUserDefaults");
    if (userDefaults) {
        SEL boolSel = @selector(boolForKey:);
        Method origMethod = class_getInstanceMethod(userDefaults, boolSel);
        if (origMethod) {
            IMP origImp = method_getImplementation(origMethod);
            IMP newImp = imp_implementationWithBlock(^BOOL(id self, NSString *key) {
                BOOL original = ((BOOL (*)(id, SEL, NSString *))origImp)(self, boolSel, key);
                if ([key containsString:@"vip"] || [key containsString:@"pro"] || [key containsString:@"subscription"]) {
                    logMessage(@"NSUserDefaults boolForKey: %@ -> YES (original was %d)", key, original);
                    return YES;
                }
                return original;
            });
            method_setImplementation(origMethod, newImp);
            logMessage(@"Swizzled NSUserDefaults boolForKey:");
        }
    }

    // 4. Hook SKPaymentQueue 的 canMakePayments 强制返回 NO，可能阻止购买弹窗
    Class skQueue = NSClassFromString(@"SKPaymentQueue");
    if (skQueue) {
        SEL canMakeSel = @selector(canMakePayments);
        swizzleClassMethod(skQueue, canMakeSel, (IMP)alwaysYES, "c@:");
    }

    // 5. Hook SKProductsRequest 的 start，阻止无效产品 ID 的错误
    Class skRequest = NSClassFromString(@"SKProductsRequest");
    if (skRequest) {
        SEL startSel = @selector(start);
        Method origMethod = class_getInstanceMethod(skRequest, startSel);
        if (origMethod) {
            IMP origImp = method_getImplementation(origMethod);
            IMP newImp = imp_implementationWithBlock(^(id self) {
                logMessage(@"SKProductsRequest start called, ignoring.");
                // 不真正执行，避免错误弹窗
            });
            method_setImplementation(origMethod, newImp);
            logMessage(@"Swizzled SKProductsRequest start");
        }
    }

    // 6. 尝试直接修改 UserDefaults 中的 VIP 标志（如果应用使用本地标志）
    // 这需要知道具体键名，这里仅示例
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"com.ydgn.dokacamera.isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"hasSubscribed"];
    [defaults synchronize];
    logMessage(@"Set VIP flags in NSUserDefaults");
}