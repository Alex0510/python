#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// 1. 获取 SwiftyStoreKit 的类（如果存在）
Class SwiftyStoreKitClass = nil;
Class InAppReceiptVerificatorClass = nil;
Class APMInAppPurchaseTransactionReporterClass = nil;

// 2. 定义我们需要 hook 的方法
static void (*orig_verifyReceipt)(id self, SEL _cmd, id completion);
static void (*orig_verifyReceiptVerificator)(id self, SEL _cmd, id receiptData, id completion);
static void (*orig_reportTransaction)(id self, SEL _cmd, id productID, id transactionID, ...); // 实际方法可能有不同参数

// 3. 钩子函数
void hook_verifyReceipt(id self, SEL _cmd, id completion) {
    // 直接模拟验证成功，构造一个假的收据数据
    NSLog(@"ProUnlock: SwiftyStoreKit verifyReceipt hooked, returning fake success.");
    if (completion) {
        // 假设 completion 是一个 block，参数为 (result, error)
        // 我们需要构造一个成功的 result，例如 { "status": 0, "receipt": {...} }
        NSDictionary *fakeReceipt = @{
            @"status": @(0),
            @"receipt": @{
                @"bundle_id": @"com.example.app",
                @"in_app": @[]  // 可添加假的内购记录
            }
        };
        // 调用 completion
        void (*callBlock)(id, id, id) = (void(*)(id, id, id))objc_msgSend;
        callBlock(completion, fakeReceipt, nil);
    }
}

void hook_verifyReceiptVerificator(id self, SEL _cmd, id receiptData, id completion) {
    NSLog(@"ProUnlock: InAppReceiptVerificator verifyReceipt hooked, returning success.");
    if (completion) {
        // 模拟成功
        NSDictionary *fakeReceipt = @{@"status": @(0)};
        void (*callBlock)(id, id, id) = (void(*)(id, id, id))objc_msgSend;
        callBlock(completion, fakeReceipt, nil);
    }
}

void hook_reportTransaction(id self, SEL _cmd, id productID, id transactionID, id originalTransactionID, id webOrderLineItemID, id productType, bool isFreeTrial, bool isIntroductoryOffer, long long paymentQuantity, id purchaseDate, id originalPurchaseDate, id subscriptionExpirationDate, id cancellationDate, id environment, bool isVerified) {
    NSLog(@"ProUnlock: reportTransaction hooked, skipping actual report for product: %@", productID);
    // 什么都不做，阻止上报
    return;
}

// 4. 在加载时执行
%ctor {
    // 获取 SwiftyStoreKit 类
    SwiftyStoreKitClass = objc_getClass("SwiftyStoreKit");
    if (SwiftyStoreKitClass) {
        // 这里假设 SwiftyStoreKit 有一个实例方法 verifyReceipt:completion:
        // 实际方法名需要根据 class-dump 确定，常见的是 - (void)verifyReceipt:(id)completion;
        // 这里我们使用 "verifyReceipt:" 作为方法名
        Method m = class_getInstanceMethod(SwiftyStoreKitClass, NSSelectorFromString(@"verifyReceipt:"));
        if (m) {
            orig_verifyReceipt = (void*)method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_verifyReceipt);
            NSLog(@"ProUnlock: hooked verifyReceipt:");
        } else {
            // 尝试其他可能的方法名
            m = class_getInstanceMethod(SwiftyStoreKitClass, NSSelectorFromString(@"verifyReceipt:completion:"));
            if (m) {
                orig_verifyReceipt = (void*)method_getImplementation(m);
                method_setImplementation(m, (IMP)hook_verifyReceipt);
                NSLog(@"ProUnlock: hooked verifyReceipt:completion:");
            } else {
                NSLog(@"ProUnlock: Could not find verifyReceipt method in SwiftyStoreKit");
            }
        }
    } else {
        NSLog(@"ProUnlock: SwiftyStoreKit class not found");
    }

    // 获取 InAppReceiptVerificator 类
    InAppReceiptVerificatorClass = objc_getClass("InAppReceiptVerificator");
    if (InAppReceiptVerificatorClass) {
        // 假设方法名为 - (void)verifyReceipt:(NSData *)receiptData completion:(void (^)(NSDictionary *, NSError *))completion
        Method m = class_getInstanceMethod(InAppReceiptVerificatorClass, NSSelectorFromString(@"verifyReceipt:completion:"));
        if (m) {
            orig_verifyReceiptVerificator = (void*)method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_verifyReceiptVerificator);
            NSLog(@"ProUnlock: hooked verifyReceipt:completion: in InAppReceiptVerificator");
        } else {
            NSLog(@"ProUnlock: Could not find verifyReceipt:completion: in InAppReceiptVerificator");
        }
    } else {
        NSLog(@"ProUnlock: InAppReceiptVerificator class not found");
    }

    // 获取 APMInAppPurchaseTransactionReporter 类
    APMInAppPurchaseTransactionReporterClass = objc_getClass("APMInAppPurchaseTransactionReporter");
    if (APMInAppPurchaseTransactionReporterClass) {
        // 根据头文件，该类有一个方法：
        // - (void)reportTransactionWithProductID:(id)productID transactionID:(id)transactionID originalTransactionID:(id)originalTransactionID webOrderLineItemID:(id)webOrderLineItemID productType:(id)productType isFreeTrial:(bool)isFreeTrial isIntroductoryOffer:(bool)isIntroductoryOffer paymentQuantity:(long long)paymentQuantity purchaseDate:(id)purchaseDate originalPurchaseDate:(id)originalPurchaseDate subscriptionExpirationDate:(id)subscriptionExpirationDate cancellationDate:(id)cancellationDate environment:(id)environment isVerified:(bool)isVerified
        SEL sel = NSSelectorFromString(@"reportTransactionWithProductID:transactionID:originalTransactionID:webOrderLineItemID:productType:isFreeTrial:isIntroductoryOffer:paymentQuantity:purchaseDate:originalPurchaseDate:subscriptionExpirationDate:cancellationDate:environment:isVerified:");
        Method m = class_getInstanceMethod(APMInAppPurchaseTransactionReporterClass, sel);
        if (m) {
            orig_reportTransaction = (void*)method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_reportTransaction);
            NSLog(@"ProUnlock: hooked reportTransactionWithProductID:... in APMInAppPurchaseTransactionReporter");
        } else {
            NSLog(@"ProUnlock: Could not find reportTransaction method in APMInAppPurchaseTransactionReporter");
        }
    } else {
        NSLog(@"ProUnlock: APMInAppPurchaseTransactionReporter class not found");
    }

    // 额外：修改 UserDefaults 中 Pro 状态的键，例如 "isPro" 或 "purchasedProduct"
    // 注意：需根据实际键名调整，可以通过分析应用偏好设置获得
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isPurchased"];
    [defaults setObject:@"pro" forKey:@"purchasedProductID"];
    [defaults synchronize];
    NSLog(@"ProUnlock: Set UserDefaults Pro flags.");
}