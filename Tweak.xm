#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 定义收据验证回调 block 类型
typedef void (^VerifyReceiptCompletion)(id result, id error);

// ---------------------------------------------------------------------
// 1. 拦截 SwiftyStoreKit 的收据验证，返回伪造的成功结果
%hook SwiftyStoreKit

// 可能的方法名 1: - (void)verifyReceipt:(id)completion
- (void)verifyReceipt:(id)completion {
    %log;
    if (completion) {
        // 构造一个假的有效收据（包含 pro 产品的内购记录）
        NSDictionary *fakeReceipt = @{
            @"status": @(0),
            @"receipt": @{
                @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
                @"in_app": @[
                    @{
                        @"product_id": @"com.picsew.pro",
                        @"quantity": @(1),
                        @"transaction_id": @"fake_transaction",
                        @"original_transaction_id": @"fake_original",
                        @"purchase_date": @"2024-01-01 00:00:00 Etc/GMT",
                        @"original_purchase_date": @"2024-01-01 00:00:00 Etc/GMT",
                        @"expires_date": @"2099-12-31 23:59:59 Etc/GMT"
                    }
                ]
            }
        };
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

// 可能的方法名 2: - (void)verifyReceipt:(id)receiptData completion:(id)completion
- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{@"status": @(0)};
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

%end

// ---------------------------------------------------------------------
// 2. 拦截本地收据验证类
%hook InAppReceiptVerificator

- (void)verifyReceipt:(id)receiptData completion:(id)completion {
    %log;
    if (completion) {
        NSDictionary *fakeReceipt = @{@"status": @(0)};
        ((VerifyReceiptCompletion)completion)(fakeReceipt, nil);
    }
}

%end

// ---------------------------------------------------------------------
// 3. 阻止向服务端上报购买交易（避免服务端校验）
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
    // 什么都不做，阻止上报
}

%end

// ---------------------------------------------------------------------
// 4. 修改 UserDefaults 中所有与购买状态相关的键，强制应用认为已购买
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    // 如果 key 是任何与购买相关的，直接返回 YES
    NSArray *proKeys = @[@"isPro", @"isPlus", @"isPurchased", @"purchased", @"proPurchased"];
    if ([proKeys containsObject:defaultName]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    // 针对特定的 key 返回假数据
    if ([defaultName isEqualToString:@"purchaseLevel"]) {
        return @"Plus";
    }
    if ([defaultName isEqualToString:@"purchasedProducts"]) {
        return @[@"com.picsew.pro", @"com.picsew.plus"];
    }
    return %orig;
}

- (NSString *)stringForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"purchaseLevel"]) {
        return @"Plus";
    }
    return %orig;
}

%end

// ---------------------------------------------------------------------
// 5. 如果应用内部有专门的购买状态类，尝试直接返回 YES（基于调试信息中的 "Purchase Level = Plus" 推测）
// 下面这些类名是基于常见命名推测的，实际可能需要根据 class-dump 调整
%hook PurchasedManager  // 假设存在这样的类

- (BOOL)isProPurchased {
    return YES;
}

- (BOOL)isPlusPurchased {
    return YES;
}

- (NSString *)purchaseLevel {
    return @"Plus";
}

%end

%hook IAPManager

- (BOOL)hasPurchasedPro {
    return YES;
}

- (BOOL)isProUser {
    return YES;
}

- (NSString *)userLevel {
    return @"Plus";
}

%end

// ---------------------------------------------------------------------
// 初始化
%ctor {
    // 直接写入 UserDefaults 确保持久化
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isPlus"];
    [defaults setBool:YES forKey:@"isPurchased"];
    [defaults setObject:@"Plus" forKey:@"purchaseLevel"];
    [defaults setObject:@[@"com.picsew.pro", @"com.picsew.plus"] forKey:@"purchasedProducts"];
    [defaults synchronize];
    NSLog(@"ProUnlock: UserDefaults have been set.");
}