#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

static NSString * const kTargetProductID = @"lifeSale";

static void (*original_paymentQueue_updatedTransactions)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *);

// 获取当前顶层视图控制器（兼容 iOS 13+，无废弃警告）
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

static void hook_paymentQueue_updatedTransactions(id self, SEL _cmd, SKPaymentQueue *queue, NSArray<SKPaymentTransaction *> *transactions) {
    // 调用原始方法，保证内购流程正常
    original_paymentQueue_updatedTransactions(self, _cmd, queue, transactions);

    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kTargetProductID]) {
            // 写入 UserDefaults 激活 Pro 状态
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PayLock.payForever"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // 尝试调用激活方法（如果存在）
            Class purchaseControllerClass = NSClassFromString(@"V2_PurchaseController");
            if (purchaseControllerClass) {
                UIViewController *topVC = getTopViewController();
                if ([topVC isKindOfClass:purchaseControllerClass]) {
                    SEL applySelector = NSSelectorFromString(@"ApplyFreeMember");
                    if ([topVC respondsToSelector:applySelector]) {
                        ((void (*)(id, SEL))objc_msgSend)(topVC, applySelector);
                    }
                }
            }
            break;
        }
    }
}

__attribute__((constructor))
static void initProUnlock() {
    Class paymentClass = NSClassFromString(@"Payment");
    if (!paymentClass) {
        NSLog(@"[ProUnlock] Payment class not found");
        return;
    }

    SEL originalSelector = @selector(paymentQueue:updatedTransactions:);
    Method originalMethod = class_getInstanceMethod(paymentClass, originalSelector);
    if (!originalMethod) {
        NSLog(@"[ProUnlock] Method not found");
        return;
    }

    original_paymentQueue_updatedTransactions = (void (*)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *))method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)hook_paymentQueue_updatedTransactions);
    NSLog(@"[ProUnlock] Loaded successfully");
}