#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================================
// 类完整声明（避免前向声明问题）
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
@property (nonatomic, strong) UIView *viewExtraInfo;
- (void)uiRefresh;
- (void)viewDidLoad;
- (BOOL)showTrialOrPayInfoForFreeMember;
@end

@interface UTMeViewController : UIViewController
@property (nonatomic, strong) UILabel *labelMemberInfo;
@property (nonatomic, strong) UIImageView *imageviewMemberLv;
- (void)viewDidLoad;
@end

@interface UTGateModelManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, strong) id model;
- (BOOL)updateNormalGates:(id)gates;
- (unsigned long long)getUserSelectedHost:(id *)host andName:(id *)name;
@end

@interface UTGateModel : NSObject
@property (nonatomic, strong) NSArray *normalGates;
@end

// ============================================================
// Helper函数获取当前窗口（兼容iOS 13+）
// ============================================================

static UIViewController *getCurrentViewController() {
    UIWindow *keyWindow = nil;
    
    // iOS 13+ 兼容方式
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    return keyWindow.rootViewController;
}

static void showAlert(NSString *title, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *rootVC = getCurrentViewController();
    if (rootVC) {
        [rootVC presentViewController:alert animated:YES completion:nil];
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

%end

%hook UTUser

- (int)membertime {
    return 36500;
}

- (int)memberdate {
    return 20991231;
}

- (float)limitkbps {
    return 0.0f;
}

- (float)limitkbytes {
    return 0.0f;
}

- (float)daykbytes {
    return 999999999.0f;
}

- (float)point {
    return 9999999.0f;
}

- (NSString *)memberid {
    return @"vip_ultimate";
}

%end

%hook UTTrialManager

- (BOOL)canApplyTrialVip {
    return YES;
}

- (BOOL)doApplyTrialVip {
    return YES;
}

- (BOOL)isTrialVip {
    return NO;
}

- (int)remainSeconds {
    return 315360000;
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
    return 2;
}

%end

%hook UTStoreViewController

- (void)clickToPay {
    showAlert(@"提示", @"VIP功能已解锁，无需购买");
}

%end

%hook UTHomeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uiRefresh];
    });
}

- (void)uiRefresh {
    %orig;
    
    if (self.labelVipInfo) {
        self.labelVipInfo.text = @"VIP会员 · 永久有效";
    }
    
    if (self.labelLineSelected) {
        self.labelLineSelected.text = @"专属VIP线路";
    }
    
    if (self.viewExtraInfo) {
        self.viewExtraInfo.hidden = YES;
    }
}

- (BOOL)showTrialOrPayInfoForFreeMember {
    return NO;
}

%end

%hook UTMeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.labelMemberInfo) {
            self.labelMemberInfo.text = @"钻石会员 · 永久有效";
        }
    });
}

%end

%hook UTGateModelManager

- (BOOL)updateNormalGates:(id)gates {
    BOOL result = %orig;
    
    @try {
        id gateModel = self.model;
        if (gateModel && [gateModel respondsToSelector:@selector(setNormalGates:)]) {
            NSMutableArray *normalGates = [NSMutableArray arrayWithArray:[gateModel valueForKey:@"normalGates"]];
            // 添加VIP专属网关
            id vipGate = [NSClassFromString(@"UTGate") new];
            if (vipGate) {
                [vipGate setValue:@"vip.accelerate.com" forKey:@"host"];
                [vipGate setValue:@"VIP专属线路" forKey:@"name"];
                [normalGates addObject:vipGate];
                [gateModel setValue:normalGates forKey:@"normalGates"];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"UTGateModelManager exception: %@", exception);
    }
    
    return result;
}

%end

%end

// ============================================================
// 初始化
// ============================================================

%ctor {
    NSLog(@"========================================");
    NSLog(@"SpeedCN VIP Unlocker Loaded!");
    NSLog(@"VIP功能已解锁");
    NSLog(@"========================================");
    
    %init(UnlockVIP);
    
    // 延迟触发UI刷新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootVC = getCurrentViewController();
        if ([rootVC respondsToSelector:@selector(uiRefresh)]) {
            [rootVC performSelector:@selector(uiRefresh)];
        }
    });
}