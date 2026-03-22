#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>

static NSString * const kTargetProductID = @"lifeSale";

// 原始方法指针
static void (*original_paymentQueue_updatedTransactions)(id, SEL, SKPaymentQueue *, NSArray<SKPaymentTransaction *> *);

// 新方法实现
static void hook_paymentQueue_updatedTransactions(id self, SEL _cmd, SKPaymentQueue *queue, NSArray<SKPaymentTransaction *> *transactions) {
    // 调用原始方法，确保原有逻辑正常执行
    original_paymentQueue_updatedTransactions(self, _cmd, queue, transactions);

    // 检查是否包含目标产品
    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kTargetProductID]) {
            // 如果交易状态不是已购买，可以在此处强制模拟购买成功
            // 实际应用中通常需要调用 finishTransaction 或设置状态，但此处仅做示例
            // 假设完成购买后，应用会设置 UserDefaults 的某个键为 YES
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPro"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PayLock.payForever"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // 尝试调用激活方法（如果存在）
            Class paymentControllerClass = NSClassFromString(@"V2_PurchaseController");
            if (paymentControllerClass) {
                // 获取当前激活的控制器实例（实际可能需要遍历视图层级）
                UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                while (topVC.presentedViewController) {
                    topVC = topVC.presentedViewController;
                }
                if ([topVC isKindOfClass:paymentControllerClass]) {
                    // 调用 ApplyFreeMember 方法（无参数）
                    SEL applySelector = NSSelectorFromString(@"ApplyFreeMember");
                    if ([topVC respondsToSelector:applySelector]) {
                        [topVC performSelector:applySelector];
                    }
                }
            }
            break;
        }
    }
}

// 入口函数，在动态库加载时执行
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

    original_paymentQueue_updatedTransactions = (void *)method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)hook_paymentQueue_updatedTransactions);
    NSLog(@"[ProUnlock] Pro unlock dylib loaded successfully");
}