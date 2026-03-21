#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/runtime.h>

// 目标应用中的类声明（仅用于编译，实际运行时存在）
@interface PaymentManager : NSObject
@property (nonatomic, assign) BOOL isVip;
- (BOOL)checkVipFromKeyChain;
- (void)verifyPurchaseWithCompletion:(void (^)(BOOL success))completion;
- (void)saveVipStatusWithIsVip:(BOOL)isVip;
- (void)saveCurrentTimestamp;
- (id)getDataFromKeychainWithKey:(id)key;
@end

@interface VIPController : UIViewController
@property (nonatomic, assign) BOOL isVip;
- (void)viewDidLoad;
- (void)applyTheme;
@end

// 确保初始化时即生效
%ctor {
    NSLog(@"ProUnlocker loaded: Unlocking VIP features...");
}

// Hook PaymentManager，始终返回 VIP 状态为 YES
%hook PaymentManager

- (BOOL)isVip {
    return YES;
}

- (BOOL)checkVipFromKeyChain {
    return YES;
}

// 拦截购买验证，直接返回成功（可选）
- (void)verifyPurchaseWithCompletion:(void (^)(BOOL success))completion {
    if (completion) {
        completion(YES);
    }
}

// 拦截保存 VIP 状态，防止被覆盖
- (void)saveVipStatusWithIsVip:(BOOL)isVip {
    // 忽略传入的 isVip，始终保存为 YES
    %orig(YES);
}

// 防止过期时间检查（如果有类似机制）
- (void)saveCurrentTimestamp {
    // 不做任何事或保存一个很大的值
    // %orig; // 如果不调用原方法，则不会更新过期时间
}

- (id)getDataFromKeychainWithKey:(id)key {
    id result = %orig;
    // 如果读取的是 VIP 相关键值，返回有效数据
    if ([key isEqualToString:@"vip_key"] || [key isEqualToString:[self keyForVip]]) {
        return @(YES);
    }
    return result;
}

%end

// Hook VIPController，确保界面上的 VIP 状态显示为已解锁
%hook VIPController

- (BOOL)isVip {
    return YES;
}

- (void)viewDidLoad {
    %orig;
    // 强制设置为 VIP 状态，并更新界面
    self.isVip = YES;
    // 可能还需要刷新界面元素，比如 VIP 标签、购买按钮等
    [self applyTheme]; // 假设这个方法会根据 VIP 状态更新界面
}

%end

// 可选：如果应用中其他地方直接访问了 PaymentManager 的单例或实例，也可以通过额外 Hook 确保所有相关方法均返回 VIP 状态