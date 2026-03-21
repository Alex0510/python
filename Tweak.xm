#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 定义 Block 类型（简化，使用 id 接收任意参数）
typedef void (^VerifyReceiptCompletion)(id result, id error);

%hook SwiftyStoreKit

// 根据实际方法名调整，这里假设存在 - (void)verifyReceipt:(id)completion
- (void)verifyReceipt:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{
            @"status": @(0),
            @"receipt": @{
                @"bundle_id": @"com.sugarmo.ScrollClip",
                @"in_app": @[]
            }
        };
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

// 如果存在 - (void)verifyReceipt:(id)receiptData completion:(id)completion
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{@"status": @(0)};
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

%end

%hook InAppReceiptVerificator

- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{@"status": @(0)};
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

%end

%hook APMInAppPurchaseTransactionReporter

- (void)reportTransactionWithProductID:(id)productID
                         transactionID:(id)transactionID
                 originalTransactionID:(id)originalTransactionID
                   webOrderLineItemID:(id)webOrderLineItemID
                           productType:(id)productType
                          isFreeTrial:(bool)isFreeTrial
                  isIntroductoryOffer:(bool)isIntroductoryOffer
                      paymentQuantity:(long long)paymentQuantity
                          purchaseDate:(id)purchaseDate
                 originalPurchaseDate:(id)originalPurchaseDate
           subscriptionExpirationDate:(id)subscriptionExpirationDate
                     cancellationDate:(id)cancellationDate
                          environment:(id)environment
                           isVerified:(bool)isVerified {
    %log;
    // 阻止上报交易信息
    return;
}

%end

%ctor {
    // 设置 UserDefaults 中的 Pro 状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isPurchased"];
    [defaults setObject:@"pro" forKey:@"purchasedProductID"];
    [defaults synchronize];
    NSLog(@"ProUnlock: Set UserDefaults Pro flags.");
}