#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

static NSString * const kTargetProductID = @"lifeSale";

// 原始内购回调指针
static void (*original_paymentQueue_updatedTransactions)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *);

// 获取顶层视图控制器（兼容 iOS 13+）
static UIViewController *getTopViewController(void) {
    UIViewController *topVC = nil;
    UIWindow *keyWindow = nil;

    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }

    topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

// 激活 Pro 功能的核心函数
static void activateProFeatures(void) {
    // 1. 写入 UserDefaults（覆盖所有可能键名）
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"PayLock.payForever"];
    [defaults setBool:YES forKey:@"payForever"];
    [defaults setBool:YES forKey:@"forever"];
    [defaults setBool:YES forKey:@"freeMember"];
    [defaults setBool:YES forKey:@"isFreeMember"];
    [defaults setBool:YES forKey:@"hasPro"];
    [defaults setBool:YES forKey:@"proEnabled"];
    [defaults setBool:YES forKey:@"proUnlocked"];
    [defaults synchronize];

    // 2. 尝试调用购买控制器的方法
    Class purchaseControllerClass = NSClassFromString(@"V2_PurchaseController");
    if (purchaseControllerClass) {
        UIViewController *topVC = getTopViewController();
        if ([topVC isKindOfClass:purchaseControllerClass]) {
            SEL applySelector = NSSelectorFromString(@"ApplyFreeMember");
            if ([topVC respondsToSelector:applySelector]) {
                ((void (*)(id, SEL))objc_msgSend)(topVC, applySelector);
            }
        } else {
            // 尝试类方法
            SEL classApplySelector = NSSelectorFromString(@"applyFreeMember");
            if ([purchaseControllerClass respondsToSelector:classApplySelector]) {
                ((void (*)(id, SEL))objc_msgSend)(purchaseControllerClass, classApplySelector);
            }
        }
    }

    // 3. 操作 PayLock 单例
    Class payLockClass = NSClassFromString(@"PayLock");
    if (payLockClass) {
        // 尝试获取单例
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if ([payLockClass respondsToSelector:sharedSel]) {
            id payLock = ((id (*)(id, SEL))objc_msgSend)(payLockClass, sharedSel);
            if (payLock) {
                // 尝试设置属性（枚举值可能需要整数）
                // 根据头文件，PayLock 可能是一个枚举类型，但也有可能是一个类，其中包含存储状态的方法
                SEL setForeverSel = NSSelectorFromString(@"setPayForever:");
                if ([payLock respondsToSelector:setForeverSel]) {
                    ((void (*)(id, SEL, BOOL))objc_msgSend)(payLock, setForeverSel, YES);
                }
                SEL setFreeMemberSel = NSSelectorFromString(@"setFreeMember:");
                if ([payLock respondsToSelector:setFreeMemberSel]) {
                    ((void (*)(id, SEL, BOOL))objc_msgSend)(payLock, setFreeMemberSel, YES);
                }
                // 尝试直接设置属性（如果有）
                objc_setAssociatedObject(payLock, "payForever", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }

    // 4. 触发 PaymentBarView 的 upgrade 回调（如果存在）
    UIViewController *topVC = getTopViewController();
    // 遍历视图层级查找 PaymentBarView 实例
    if (topVC.view) {
        for (UIView *subview in topVC.view.subviews) {
            if ([NSStringFromClass([subview class]) isEqualToString:@"PaymentBarView"]) {
                // 找到 PaymentBarView，尝试调用 upgrade 回调
                id barView = subview;
                SEL upgradeSelector = NSSelectorFromString(@"upgrade");
                if ([barView respondsToSelector:upgradeSelector]) {
                    void (*upgradeFunc)(id, SEL) = (void (*)(id, SEL))objc_msgSend;
                    upgradeFunc(barView, upgradeSelector);
                }
                break;
            }
        }
    }

    // 5. 触发 PaymentBar 的 upgrade 回调（如果存在）
    for (UIView *subview in topVC.view.subviews) {
        if ([NSStringFromClass([subview class]) isEqualToString:@"PaymentBar"]) {
            id bar = subview;
            SEL upgradeSelector = NSSelectorFromString(@"upgrade");
            if ([bar respondsToSelector:upgradeSelector]) {
                void (*upgradeFunc)(id, SEL) = (void (*)(id, SEL))objc_msgSend;
                upgradeFunc(bar, upgradeSelector);
            }
            break;
        }
    }
}

// 内购回调 Hook
static void hook_paymentQueue_updatedTransactions(id self, SEL _cmd, SKPaymentQueue *queue, NSArray<SKPaymentTransaction *> *transactions) {
    original_paymentQueue_updatedTransactions(self, _cmd, queue, transactions);
    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kTargetProductID]) {
            activateProFeatures();
            if (transaction.transactionState == SKPaymentTransactionStatePurchased ||
                transaction.transactionState == SKPaymentTransactionStateRestored) {
                [queue finishTransaction:transaction];
            }
            break;
        }
    }
}

// 动态库入口
__attribute__((constructor))
static void initProUnlock() {
    // 延迟执行确保应用已初始化
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        activateProFeatures();
    });

    // Hook Payment 类的内购方法
    Class paymentClass = NSClassFromString(@"Payment");
    if (paymentClass) {
        SEL originalSelector = @selector(paymentQueue:updatedTransactions:);
        Method originalMethod = class_getInstanceMethod(paymentClass, originalSelector);
        if (originalMethod) {
            original_paymentQueue_updatedTransactions = (void (*)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *))method_getImplementation(originalMethod);
            method_setImplementation(originalMethod, (IMP)hook_paymentQueue_updatedTransactions);
            NSLog(@"[ProUnlock] Payment hooked");
        }
    } else {
        NSLog(@"[ProUnlock] Payment class not found");
    }

    // 尝试 Hook PayLock 的某些方法（如果存在）
    Class payLockClass = NSClassFromString(@"PayLock");
    if (payLockClass) {
        // 假设有一个方法 `isPro` 或 `isForever`，我们可以让它永远返回 YES
        SEL checkSelector = NSSelectorFromString(@"isForever");
        if (!checkSelector) checkSelector = NSSelectorFromString(@"isPro");
        if (checkSelector && class_getInstanceMethod(payLockClass, checkSelector)) {
            Method originalMethod = class_getInstanceMethod(payLockClass, checkSelector);
            IMP newImp = imp_implementationWithBlock(^BOOL(id self) {
                return YES;
            });
            method_setImplementation(originalMethod, newImp);
            NSLog(@"[ProUnlock] PayLock method %@ hooked", NSStringFromSelector(checkSelector));
        }
    }

    // Hook V2_PurchaseController 的某些方法，防止其检查失败
    Class v2PurchaseClass = NSClassFromString(@"V2_PurchaseController");
    if (v2PurchaseClass) {
        // 假设有一个检查方法
        SEL verifySelector = NSSelectorFromString(@"verifyPurchaseStatus");
        if (verifySelector && class_getInstanceMethod(v2PurchaseClass, verifySelector)) {
            Method originalMethod = class_getInstanceMethod(v2PurchaseClass, verifySelector);
            IMP newImp = imp_implementationWithBlock(^BOOL(id self) {
                return YES;
            });
            method_setImplementation(originalMethod, newImp);
        }
    }
}