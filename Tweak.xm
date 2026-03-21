#import <Foundation/Foundation.h>

%hook APMInAppPurchaseItem

// 永远返回未来时间（2099年）
- (id)subscriptionExpirationDateIA5String {
    return @"2099-12-31T23:59:59Z";
}

// 防止被识别为取消订阅
- (id)cancellationDateIA5String {
    return nil;
}

// 可选：伪造购买时间
- (id)purchaseDateIA5String {
    return @"2020-01-01T00:00:00Z";
}

// 强制 productID 为 Pro（根据实际改）
- (id)productID {
    return @"pro";
}

%end