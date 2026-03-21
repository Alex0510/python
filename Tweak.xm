#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/runtime.h>

// 目标应用中的类声明（仅用于编译）
@interface PaymentManager : NSObject
@property (nonatomic, assign) BOOL isVip;
- (BOOL)checkVipFromKeyChain;
- (void)verifyPurchaseWithCompletion:(void (^)(BOOL success))completion;
- (void)saveVipStatusWithIsVip:(BOOL)isVip;
- (void)saveCurrentTimestamp;
- (id)getDataFromKeychainWithKey:(id)key;
- (id)keyForVip;
@end

@interface VIPController : UIViewController
@property (nonatomic, assign) BOOL isVip;
- (void)viewDidLoad;
- (void)applyTheme;
@end

%ctor {
    NSLog(@"AddonsPro loaded: Unlocking VIP features...");
}

%hook PaymentManager

- (BOOL)isVip {
    return YES;
}

- (BOOL)checkVipFromKeyChain {
    return YES;
}

- (void)verifyPurchaseWithCompletion:(void (^)(BOOL success))completion {
    if (completion) completion(YES);
}

- (void)saveVipStatusWithIsVip:(BOOL)isVip {
    %orig(YES);
}

- (void)saveCurrentTimestamp {
    // 不做任何事，防止过期
}

- (id)getDataFromKeychainWithKey:(id)key {
    id result = %orig;
    if ([key isEqualToString:[self keyForVip]] || [key isEqualToString:@"vip_key"]) {
        return @(YES);
    }
    return result;
}

%end

%hook VIPController

- (BOOL)isVip {
    return YES;
}

- (void)viewDidLoad {
    %orig;
    self.isVip = YES;
    [self applyTheme];
}

%end