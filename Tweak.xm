#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

static NSString * const kTargetProductID = @"lifeSale";

static void (*original_paymentQueue_updatedTransactions)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *);

// 获取顶层视图控制器（兼容 iOS 13+，无警告）
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
    // 1. 写入所有可能的 UserDefaults 键
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"PayLock.payForever"];
    [defaults setBool:YES forKey:@"payForever"];
    [defaults setBool:YES forKey:@"forever"];
    [defaults setBool:YES forKey:@"freeMember"];
    [defaults setBool:YES forKey:@"isFreeMember"];
    [defaults setBool:YES forKey:@"hasPro"];
    [defaults setBool:YES forKey:@"proEnabled"];
    [defaults synchronize];

    // 2. 尝试调用激活方法
    Class purchaseControllerClass = NSClassFromString(@"V2_PurchaseController");
    if (purchaseControllerClass) {
        UIViewController *topVC = getTopViewController();
        if ([topVC isKindOfClass:purchaseControllerClass]) {
            SEL applySelector = NSSelectorFromString(@"ApplyFreeMember");
            if ([topVC respondsToSelector:applySelector]) {
                ((void (*)(id, SEL))objc_msgSend)(topVC, applySelector);
            }
        } else {
            // 如果当前没有 PurchaseController，尝试通过类方法调用（如果存在）
            SEL classApplySelector = NSSelectorFromString(@"applyFreeMember");
            if ([purchaseControllerClass respondsToSelector:classApplySelector]) {
                ((void (*)(id, SEL))objc_msgSend)(purchaseControllerClass, classApplySelector);
            }
        }
    }

    // 3. 尝试刷新其他可能的单例状态
    Class payLockClass = NSClassFromString(@"PayLock");
    if (payLockClass) {
        // 假设有一个 sharedInstance 方法
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if ([payLockClass respondsToSelector:sharedSel]) {
            id payLock = ((id (*)(id, SEL))objc_msgSend)(payLockClass, sharedSel);
            if (payLock) {
                // 尝试设置属性
                SEL setForeverSel = NSSelectorFromString(@"setPayForever:");
                if ([payLock respondsToSelector:setForeverSel]) {
                    ((void (*)(id, SEL, BOOL))objc_msgSend)(payLock, setForeverSel, YES);
                }
                SEL setFreeMemberSel = NSSelectorFromString(@"setFreeMember:");
                if ([payLock respondsToSelector:setFreeMemberSel]) {
                    ((void (*)(id, SEL, BOOL))objc_msgSend)(payLock, setFreeMemberSel, YES);
                }
            }
        }
    }
}

// 内购回调 Hook
static void hook_paymentQueue_updatedTransactions(id self, SEL _cmd, SKPaymentQueue *queue, NSArray<SKPaymentTransaction *> *transactions) {
    // 先调用原始方法，保证内购流程完整性
    original_paymentQueue_updatedTransactions(self, _cmd, queue, transactions);

    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kTargetProductID]) {
            activateProFeatures();

            // 模拟完成交易（如果原始方法没有 finish）
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
    // 延迟一小段时间执行，确保应用已完全启动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        activateProFeatures();
    });

    // Hook Payment 类
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
}