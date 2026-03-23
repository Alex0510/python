#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================================
// 类声明
// ============================================================

@interface UTUser : NSObject
@property (nonatomic, copy) NSString *memberid;
@property (nonatomic, assign) int membertime;
@property (nonatomic, assign) int memberdate;
@property (nonatomic, assign) float point;
@property (nonatomic, assign) float limitkbps;
@property (nonatomic, assign) float limitkbytes;
@property (nonatomic, assign) float daykbytes;
@end

@interface UTUserModel : NSObject
@property (nonatomic, strong) UTUser *user;
@end

@interface UTUserModelManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, strong) UTUserModel *model;
- (BOOL)isVip;
- (BOOL)isVipExpired;
- (id)dateVipExpire;
- (unsigned long long)memberLevel;
- (BOOL)isVipTrialStage;
- (BOOL)hasBinded;
@end

@interface UTTrialManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)canApplyTrialVip;
- (BOOL)doApplyTrialVip;
- (BOOL)isTrialVip;
- (int)remainSeconds;
@end

@interface UTVpnModelManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) unsigned long long vpnState;
@property (nonatomic, assign) BOOL vpnGlobalMode;
@property (nonatomic, assign) BOOL vpnGameAccelerated;
@end

@interface UTStoreViewController : UIViewController
- (void)clickToPay;
@end

@interface UTHomeViewController : UIViewController
@property (nonatomic, strong) UILabel *labelVipInfo;
@property (nonatomic, strong) UILabel *labelLineSelected;
@property (nonatomic, strong) UILabel *labelTrafficToday;  // 今日流量标签
@property (nonatomic, strong) UIView *viewExtraInfo;
- (void)uiRefresh;
- (BOOL)showTrialOrPayInfoForFreeMember;
@end

@interface UTMeViewController : UIViewController
@property (nonatomic, strong) UILabel *labelMemberInfo;
- (void)uiRefresh;
@end

// ============================================================
// 常量定义
// ============================================================

static const float INFINITE_TRAFFIC = 999999999.0f;
static const float INFINITE_POINT = 9999999.0f;
static const int VIP_DAYS = 36500;
static const int VIP_DATE = 20991231;

// ============================================================
// Hook实现
// ============================================================

%group UnlockVIP

// 核心VIP判断 - 只修改VIP状态，不修改流量
%hook UTUserModelManager

- (BOOL)isVip {
    return YES;
}

- (BOOL)isVipExpired {
    return NO;
}

- (id)dateVipExpire {
    return [NSDate distantFuture];
}

- (unsigned long long)memberLevel {
    return 3;
}

- (BOOL)isVipTrialStage {
    return NO;
}

- (BOOL)hasBinded {
    return YES;
}

%end

// 用户数据 - 只修改VIP相关数据，不修改流量限制
%hook UTUser

- (int)membertime {
    return VIP_DAYS;
}

- (int)memberdate {
    return VIP_DATE;
}

// 不修改limitkbps - 保持原样，让应用自己计算速度限制
// 不修改limitkbytes - 保持原样
// 不修改daykbytes - 保持原样，让应用自己统计每日流量

- (float)point {
    return INFINITE_POINT;
}

- (NSString *)memberid {
    return @"vip_ultimate";
}

%end

// 试用管理
%hook UTTrialManager

- (BOOL)canApplyTrialVip {
    return NO;
}

- (BOOL)doApplyTrialVip {
    return NO;
}

- (BOOL)isTrialVip {
    return NO;
}

- (int)remainSeconds {
    return 0;
}

%end

// VPN模式
%hook UTVpnModelManager

- (BOOL)vpnGlobalMode {
    return YES;
}

- (BOOL)vpnGameAccelerated {
    return YES;
}

%end

// 商店拦截
%hook UTStoreViewController

- (void)clickToPay {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是VIP会员，无需购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// 首页UI修改 - 只修改VIP相关文字，不修改流量显示
%hook UTHomeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            [self uiRefresh];
        } @catch (NSException *e) {
            NSLog(@"HomeVC refresh error: %@", e);
        }
    });
}

- (void)uiRefresh {
    %orig;
    
    @try {
        // 只修改VIP相关的文字，不修改流量
        if (self.labelVipInfo) {
            self.labelVipInfo.text = @"VIP会员 · 永久有效";
        }
        if (self.labelLineSelected) {
            self.labelLineSelected.text = @"专属VIP线路";
        }
        if (self.viewExtraInfo) {
            self.viewExtraInfo.hidden = YES;
        }
        
        // 注意：不修改 labelTrafficToday 的文字，让应用自己显示真实流量
        // 如果应用自己会显示流量，我们不应该覆盖它
    } @catch (NSException *e) {
        NSLog(@"UI refresh error: %@", e);
    }
}

- (BOOL)showTrialOrPayInfoForFreeMember {
    return NO;
}

%end

// 我的页面UI修改
%hook UTMeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            [self uiRefresh];
        } @catch (NSException *e) {
            NSLog(@"MeVC refresh error: %@", e);
        }
    });
}

- (void)uiRefresh {
    %orig;
    
    @try {
        if (self.labelMemberInfo) {
            self.labelMemberInfo.text = @"钻石会员 · 永久有效";
        }
    } @catch (NSException *e) {
        NSLog(@"UI refresh error: %@", e);
    }
}

%end

%end

// ============================================================
// 初始化
// ============================================================

%ctor {
    NSLog(@"========================================");
    NSLog(@"SpeedCN VIP Unlocker Loaded!");
    NSLog(@"VIP功能已解锁 - 永久会员");
    NSLog(@"========================================");
    
    @try {
        %init(UnlockVIP);
    } @catch (NSException *exception) {
        NSLog(@"Failed to init hooks: %@", exception);
    }
}