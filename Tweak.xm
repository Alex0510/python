#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================================
// 类完整声明
// ============================================================

@interface UTUser : NSObject
@property (nonatomic, copy) NSString *memberid;
@property (nonatomic, assign) int membertime;
@property (nonatomic, assign) int memberdate;
@property (nonatomic, assign) float point;
@property (nonatomic, assign) float limitkbps;
@property (nonatomic, assign) float limitkbytes;
@property (nonatomic, assign) float daykbytes;
- (void)setMemberid:(NSString *)memberid;
- (void)setMembertime:(int)membertime;
- (void)setMemberdate:(int)memberdate;
- (void)setLimitkbps:(float)limitkbps;
- (void)setLimitkbytes:(float)limitkbytes;
- (void)setDaykbytes:(float)daykbytes;
- (void)setPoint:(float)point;
@end

@interface UTUserModel : NSObject
@property (nonatomic, strong) UTUser *user;
- (void)setUser:(UTUser *)user;
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
- (void)userModelChanged:(id)sender;
- (void)update:(id)data;
- (void)userModelWriteToUserData;
- (void)userModelReadFromUserData;
@end

@interface UTTrialManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)canApplyTrialVip;
- (BOOL)doApplyTrialVip;
- (BOOL)isTrialVip;
- (int)remainSeconds;
- (void)doEndTrialVip;
@end

@interface UTVpnModelManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) unsigned long long vpnState;
@property (nonatomic, assign) BOOL vpnGlobalMode;
@property (nonatomic, assign) BOOL vpnGameAccelerated;
- (void)updateVpnState:(unsigned long long)state;
- (void)updateGlobalMode:(BOOL)mode;
- (void)updateGameAccelerated:(BOOL)accelerated;
@end

@interface UTStoreViewController : UIViewController
- (void)clickToPay;
- (void)clickCardType:(id)sender;
- (void)doPayment:(id)sender;
@end

@interface UTHomeViewController : UIViewController
@property (nonatomic, strong) UILabel *labelVipInfo;
@property (nonatomic, strong) UILabel *labelLineSelected;
@property (nonatomic, strong) UILabel *labelTrafficToday;
@property (nonatomic, strong) UIView *viewExtraInfo;
@property (nonatomic, strong) UIButton *buttonAccelerate;
- (void)uiRefresh;
- (void)doUiRefresh;
- (void)userModelChanged:(id)sender;
- (void)vpnStateChanged:(id)sender forceAnimation:(BOOL)force;
- (BOOL)showTrialOrPayInfoForFreeMember;
- (void)clickToAccelerate;
- (void)doStopVpn;
- (void)doStartVpn;
@end

@interface UTMeViewController : UIViewController
@property (nonatomic, strong) UILabel *labelMemberInfo;
@property (nonatomic, strong) UILabel *labelId;
@property (nonatomic, strong) UILabel *labelNickname;
@property (nonatomic, strong) UIImageView *imageviewAvatar;
- (void)uiRefresh;
- (void)doUiRefresh;
- (void)userModelChanged:(id)sender;
@end

@interface UTLoginViewController : UIViewController
@end

// ============================================================
// 常量定义 - 使用浮点数避免隐式转换警告
// ============================================================

#define VIP_DAYS 36500
#define VIP_DATE 20991231
#define INFINITE_TRAFFIC 999999999.0f
#define INFINITE_POINT 9999999.0f

// ============================================================
// 全局变量
// ============================================================

static BOOL hasModifiedUserData = NO;

// ============================================================
// Helper函数
// ============================================================

static UIViewController *getCurrentViewController() {
    NSArray *windows = [UIApplication sharedApplication].windows;
    UIWindow *keyWindow = nil;
    
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    
    if (!keyWindow && windows.count > 0) {
        keyWindow = windows[0];
    }
    
    return keyWindow.rootViewController;
}

static void forceRefreshUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *tabBar = (UITabBarController *)getCurrentViewController();
        if ([tabBar isKindOfClass:[UITabBarController class]]) {
            for (UIViewController *vc in tabBar.viewControllers) {
                if ([vc isKindOfClass:NSClassFromString(@"UTHomeViewController")]) {
                    UTHomeViewController *homeVC = (UTHomeViewController *)vc;
                    [homeVC uiRefresh];
                    [homeVC doUiRefresh];
                }
                if ([vc isKindOfClass:NSClassFromString(@"UTMeViewController")]) {
                    UTMeViewController *meVC = (UTMeViewController *)vc;
                    [meVC uiRefresh];
                    [meVC doUiRefresh];
                }
            }
        }
    });
}

static void fixUserData(UTUserModelManager *manager) {
    if (manager && manager.model && manager.model.user) {
        UTUser *user = manager.model.user;
        [user setMemberid:@"vip_ultimate"];
        [user setMembertime:VIP_DAYS];
        [user setMemberdate:VIP_DATE];
        [user setLimitkbps:0.0f];
        [user setLimitkbytes:0.0f];
        [user setDaykbytes:INFINITE_TRAFFIC];
        [user setPoint:INFINITE_POINT];
    }
}

// ============================================================
// Hook实现
// ============================================================

%group UnlockVIP

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

- (void)userModelReadFromUserData {
    %orig;
    fixUserData(self);
}

- (void)userModelWriteToUserData {
    fixUserData(self);
    %orig;
}

- (void)update:(id)data {
    %orig;
    fixUserData(self);
    forceRefreshUI();
}

- (void)userModelChanged:(id)sender {
    %orig;
    fixUserData(self);
    forceRefreshUI();
}

%end

%hook UTUser

- (int)membertime {
    return VIP_DAYS;
}

- (int)memberdate {
    return VIP_DATE;
}

- (float)limitkbps {
    return 0.0f;
}

- (float)limitkbytes {
    return 0.0f;
}

- (float)daykbytes {
    return INFINITE_TRAFFIC;
}

- (float)point {
    return INFINITE_POINT;
}

- (NSString *)memberid {
    return @"vip_ultimate";
}

%end

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

- (void)doEndTrialVip {
    // 不做任何事
}

%end

%hook UTVpnModelManager

- (BOOL)vpnGlobalMode {
    return YES;
}

- (BOOL)vpnGameAccelerated {
    return YES;
}

- (unsigned long long)vpnState {
    return %orig;
}

%end

%hook UTStoreViewController

- (void)clickToPay {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是VIP会员，无需购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clickCardType:(id)sender {
    // 不执行任何操作
}

- (void)doPayment:(id)sender {
    // 不执行任何操作
}

%end

%hook UTHomeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
        [self doUiRefresh];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (void)uiRefresh {
    %orig;
    
    if (self.labelVipInfo) {
        self.labelVipInfo.text = @"VIP会员 · 永久有效";
        self.labelVipInfo.textColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.2 alpha:1.0];
    }
    
    if (self.labelLineSelected) {
        self.labelLineSelected.text = @"专属VIP线路";
    }
    
    if (self.viewExtraInfo) {
        self.viewExtraInfo.hidden = YES;
    }
    
    if (self.labelTrafficToday) {
        self.labelTrafficToday.text = @"今日已用 0 MB";
    }
}

- (void)doUiRefresh {
    %orig;
    
    if (self.labelVipInfo) {
        self.labelVipInfo.text = @"VIP会员 · 永久有效";
    }
    
    if (self.labelLineSelected) {
        self.labelLineSelected.text = @"专属VIP线路";
    }
}

- (void)userModelChanged:(id)sender {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (void)vpnStateChanged:(id)sender forceAnimation:(BOOL)force {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (BOOL)showTrialOrPayInfoForFreeMember {
    return NO;
}

- (void)clickToAccelerate {
    UTUserModelManager *manager = [NSClassFromString(@"UTUserModelManager") sharedInstance];
    fixUserData(manager);
    %orig;
}

%end

%hook UTMeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (void)uiRefresh {
    %orig;
    
    if (self.labelMemberInfo) {
        self.labelMemberInfo.text = @"钻石会员 · 永久有效";
        self.labelMemberInfo.textColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.2 alpha:1.0];
    }
    
    if (self.labelId) {
        NSString *originalId = self.labelId.text;
        if (originalId && ![originalId hasSuffix:@" (VIP)"]) {
            self.labelId.text = [originalId stringByAppendingString:@" (VIP)"];
        }
    }
}

- (void)doUiRefresh {
    %orig;
    
    if (self.labelMemberInfo) {
        self.labelMemberInfo.text = @"钻石会员 · 永久有效";
    }
}

- (void)userModelChanged:(id)sender {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
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
    
    %init(UnlockVIP);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UTUserModelManager *manager = [NSClassFromString(@"UTUserModelManager") sharedInstance];
        if (manager) {
            if (!manager.model) {
                UTUserModel *model = [[NSClassFromString(@"UTUserModel") alloc] init];
                UTUser *user = [[NSClassFromString(@"UTUser") alloc] init];
                [user setMemberid:@"vip_ultimate"];
                [user setMembertime:VIP_DAYS];
                [user setMemberdate:VIP_DATE];
                [user setLimitkbps:0.0f];
                [user setLimitkbytes:0.0f];
                [user setDaykbytes:INFINITE_TRAFFIC];
                [user setPoint:INFINITE_POINT];
                [model setUser:user];
                [manager setModel:model];
            } else {
                fixUserData(manager);
            }
            [manager userModelWriteToUserData];
        }
        
        forceRefreshUI();
    });
}