// Tweak.x
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 获取应用委托
@interface AppDelegate : UIResponder
@property (nonatomic, strong) UIWindow *window;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options;
@end

// UserInfo 类接口
@interface UserInfo : NSObject
@property (nonatomic, assign) long long vipLevel;
@property (nonatomic, assign) long long validateTime;
@property (nonatomic, assign) long long vLevel;
@property (nonatomic, assign) long long agent;
- (long long)vipLevel;
- (long long)validateTime;
- (long long)vLevel;
- (long long)agent;
@end

// User 类接口
@interface User : NSObject
@property (nonatomic, assign) long long vipLevel;
@property (nonatomic, assign) long long vLevel;
@property (nonatomic, assign) long long validateTime;
@property (nonatomic, assign) long long agent;
- (long long)vipLevel;
- (long long)validateTime;
@end

// Mission 类接口
@interface Mission : NSObject
@property (nonatomic, assign) long long limit;
@property (nonatomic, assign) long long total;
- (long long)limit;
- (long long)total;
@end

// Node 类接口
@interface Node : NSObject
@property (nonatomic, assign) long long vLevel;
@property (nonatomic, assign) long long isNode;
- (long long)vLevel;
- (long long)isNode;
@end

// HomeVC 接口
@interface HomeVC : UIViewController
- (void)viewDidLoad;
- (void)updateVipStatus;
@end

// MissionsVC 接口
@interface MissionsVC : UIViewController
- (void)getMissionStatusRequest;
@end

// OptionSettingVC 接口
@interface OptionSettingVC : UIViewController
- (void)gotoPurchaseTapped;
@end

// SettingAccountVC 接口
@interface SettingAccountVC : UIViewController
- (void)viewWillAppear:(BOOL)animated;
@end

// 辅助类
@interface VIPHelper : NSObject
+ (void)forceVIPStatus;
+ (void)updateVIPDisplay;
@end

@implementation VIPHelper

+ (void)forceVIPStatus {
    // 强制设置VIP状态到UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isVIPUser"];
    [defaults setObject:@(999) forKey:@"vipLevel"];
    [defaults setObject:@(4102444800) forKey:@"expireTime"];
    [defaults setObject:@(1) forKey:@"agent"];
    [defaults synchronize];
    
    NSLog(@"[VIPUnlocker] VIP status forced to MAX");
    
    // 发送通知更新界面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" object:nil];
}

+ (void)updateVIPDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取根视图控制器并更新显示
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            // 递归查找并更新VIP标签
            [self updateVIPLabelsInView:rootVC.view];
        }
    });
}

+ (void)updateVIPLabelsInView:(UIView *)view {
    // 查找并修改所有VIP相关标签
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            if ([text containsString:@"VIP"] || [text containsString:@"会员"] || 
                [text containsString:@"vip"] || [text containsString:@"Vip"]) {
                if ([text containsString:@"普通"] || [text containsString:@"未开通"] ||
                    [text containsString:@"已过期"]) {
                    label.text = @"VIP会员";
                    label.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
                }
            } else if ([text containsString:@"过期"] || [text containsString:@"到期"]) {
                label.text = @"永久有效";
                label.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0];
            }
        }
        [self updateVIPLabelsInView:subview];
    }
}

@end

%hook UserInfo

- (long long)vipLevel {
    return 999;
}

- (long long)validateTime {
    return 4102444800; // 2099年
}

- (long long)vLevel {
    return 999;
}

- (long long)agent {
    return 1;
}

%new
- (BOOL)isVIPUser {
    return YES;
}

%end

%hook User

- (long long)vipLevel {
    return 999;
}

- (long long)vLevel {
    return 999;
}

- (long long)validateTime {
    return 4102444800;
}

- (long long)agent {
    return 1;
}

%new
- (BOOL)isVIPUser {
    return YES;
}

%end

%hook Mission

- (long long)limit {
    return 0;
}

- (long long)total {
    return 999999;
}

%end

%hook Node

- (long long)vLevel {
    return 0;
}

- (long long)isNode {
    return 1;
}

%end

%hook HomeVC

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VIPHelper updateVIPDisplay];
        
        // 查找并更新VIP标签
        UILabel *vipLabel = [self valueForKey:@"lblVipMember"];
        if (vipLabel) {
            [vipLabel setText:@"VIP会员"];
            [vipLabel setTextColor:[UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0]];
        }
    });
}

- (void)updateVipStatus {
    UILabel *vipLabel = [self valueForKey:@"lblVipMember"];
    if (vipLabel) {
        [vipLabel setText:@"VIP会员"];
    }
}

%end

%hook MissionsVC

- (void)getMissionStatusRequest {
    %orig;
    
    // 修改任务状态
    NSMutableArray *missions = [self valueForKey:@"missionssList"];
    if (missions && [missions isKindOfClass:[NSMutableArray class]]) {
        for (id mission in missions) {
            [mission setValue:@1 forKey:@"status"];
        }
    }
}

%end

%hook OptionSettingVC

- (void)gotoPurchaseTapped {
    // 直接授予VIP权限，不打开购买页面
    [VIPHelper forceVIPStatus];
    [VIPHelper updateVIPDisplay];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"VIP功能已解锁\n所有高级功能已开放" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

%hook SettingAccountVC

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 修改会员过期日期显示
        UILabel *expiredDateLabel = [self valueForKey:@"lblExpiredDate"];
        if (expiredDateLabel) {
            [expiredDateLabel setText:@"永久有效"];
            [expiredDateLabel setTextColor:[UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0]];
        }
    });
}

%end

%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    
    // 延迟强制VIP状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VIPHelper forceVIPStatus];
        [VIPHelper updateVIPDisplay];
    });
    
    return result;
}

%end

// 构造函数，在dylib加载时执行
__attribute__((constructor))
static void init() {
    NSLog(@"[VIPUnlocker] GeminiVPN VIP Unlocker Loaded Successfully");
    
    // 立即强制VIP状态
    [VIPHelper forceVIPStatus];
    
    // 监听通知
    [[NSNotificationCenter defaultCenter] addObserverForName:@"VIPStatusChanged" 
                                                       object:nil 
                                                        queue:[NSOperationQueue mainQueue] 
                                                   usingBlock:^(NSNotification * _Nonnull note) {
        [VIPHelper updateVIPDisplay];
    }];
}