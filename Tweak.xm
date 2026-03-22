#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

static NSString * const kTargetProductID = @"lifeSale";

// 原始方法指针
static void (*original_paymentQueue_updatedTransactions)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *);

// 获取当前顶层视图控制器（兼容 iOS 13+）
static UIViewController *getTopViewController(void) {
    UIViewController *topVC = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        topVC = window.rootViewController;
                        break;
                    }
                }
                if (topVC) break;
            }
        }
    } else {
        topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

// 新方法实现
static void hook_paymentQueue_updatedTransactions(id self, SEL _cmd, SKPaymentQueue *queue, NSArray<SKPaymentTransaction *> *transactions) {
    // 调用原始方法，确保内购流程正常
    original_paymentQueue_updatedTransactions(self, _cmd, queue, transactions);

    // 遍历交易，检测目标产品
    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kTargetProductID]) {
            // 写入 UserDefaults 激活 Pro 状态（根据实际键名调整）
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PayLock.payForever"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // 尝试调用激活方法（如果存在）
            Class paymentControllerClass = NSClassFromString(@"V2_PurchaseController");
            if (paymentControllerClass) {
                UIViewController *topVC = getTopViewController();
                if ([topVC isKindOfClass:paymentControllerClass]) {
                    SEL applySelector = NSSelectorFromString(@"ApplyFreeMember");
                    if ([topVC respondsToSelector:applySelector]) {
                        // 使用 objc_msgSend 避免 performSelector 内存泄漏警告
                        ((void (*)(id, SEL))objc_msgSend)(topVC, applySelector);
                    }
                }
            }
            break;
        }
    }
}

// 动态库入口（构造函数）
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
        NSLog(@"[ProUnlock] Method paymentQueue:updatedTransactions: not found");
        return;
    }

    // 安全地转换函数指针类型
    original_paymentQueue_updatedTransactions = (void (*)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *))method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)hook_paymentQueue_updatedTransactions);
    NSLog(@"[ProUnlock] Pro unlock dylib loaded successfully");
}