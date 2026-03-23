// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 声明DDSettingVipExpireCell类
@interface DDSettingVipExpireCell : UITableViewCell
@property (nonatomic, strong) UILabel *expireLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UILabel *fomzLabel;
@property (nonatomic, strong) UIImageView *fomzImageView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *crowImageView;
- (void)setExpireDate:(id)arg1;
- (void)updateVipStatus;
@end

// 声明DDVipViewController类
@interface DDVipViewController : UIViewController
@property (nonatomic, strong) NSString *monthPriceString;
@property (nonatomic, strong) NSString *yearsPriceString;
@property (nonatomic, strong) NSString *foreverPriceString;
@property (nonatomic, strong) UIButton *payButton;
@property (nonatomic, strong) UIButton *recoveryButton;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *monthItemView;
@property (nonatomic, strong) UIView *yearsItemView;
@property (nonatomic, strong) UIView *foreverItemView;
- (void)onPayButtonTouch;
- (void)onRecoveryButtonTouch;
- (void)updateVipStatus;
- (BOOL)isVipActive;
- (BOOL)checkVipStatus;
@end

// 声明VIP管理类（如果存在）
@interface DDVipManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)isVip;
- (BOOL)isPro;
- (BOOL)isFomzPro;
- (id)vipExpireDate;
- (void)setVipStatus:(BOOL)status;
@end

// 声明AppDelegate
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

// 使用更底层的方法：Method Swizzling
static void (*original_setText)(id self, SEL _cmd, NSString *text);
static void replaced_setText(id self, SEL _cmd, NSString *text) {
    // 拦截UILabel的setText方法，如果是VIP相关的文本就替换
    NSString *originalText = text;
    
    // 获取当前label的父视图链
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:NSClassFromString(@"DDSettingVipExpireCell")]) {
            // 如果是VIP过期cell中的label，替换文本
            if ([originalText containsString:@"到期时间"] || 
                [originalText containsString:@"expire"] ||
                [originalText containsString:@"Expire"]) {
                original_setText(self, _cmd, @"到期时间: 2999年12月29日");
                return;
            }
            if ([originalText containsString:@"Fomz"] || 
                [originalText containsString:@"Pro"] ||
                [originalText containsString:@"会员"]) {
                original_setText(self, _cmd, @"已升级 Fomz Pro");
                return;
            }
            break;
        }
        view = [view superview];
    }
    
    original_setText(self, _cmd, originalText);
}

%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    // 延迟执行，确保subviews已创建
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 遍历所有subview找label
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subview;
                NSString *text = label.text;
                if (text && [text containsString:@"到期时间"]) {
                    label.text = @"到期时间: 2999年12月29日";
                } else if (text && [text containsString:@"Fomz"]) {
                    label.text = @"已升级 Fomz Pro";
                } else if (text && text.length > 0 && [text containsString:@"Pro"]) {
                    label.text = @"已升级 Fomz Pro";
                }
            }
        }
    });
}

- (void)layoutSubviews {
    %orig;
    
    // 每次布局时更新
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            if (text && [text containsString:@"到期时间"]) {
                label.text = @"到期时间: 2999年12月29日";
            } else if (text && [text containsString:@"Fomz"]) {
                label.text = @"已升级 Fomz Pro";
            } else if (text && text.length > 0 && ([text containsString:@"Pro"] || [text containsString:@"会员"])) {
                label.text = @"已升级 Fomz Pro";
            }
        }
    }
}

%end

%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    
    // 立即修改
    [self performSelector:@selector(forceUpdateVipStatus) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(forceUpdateVipStatus) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(forceUpdateVipStatus) withObject:nil afterDelay:1.0];
}

- (void)forceUpdateVipStatus {
    // 修改价格
    if ([self respondsToSelector:@selector(setMonthPriceString:)]) {
        [self setMonthPriceString:@"永久免费"];
    }
    if ([self respondsToSelector:@selector(setYearsPriceString:)]) {
        [self setYearsPriceString:@"永久免费"];
    }
    if ([self respondsToSelector:@selector(setForeverPriceString:)]) {
        [self setForeverPriceString:@"永久免费"];
    }
    
    // 修改按钮
    if (self.payButton) {
        [self.payButton setTitle:@"已激活永久会员" forState:UIControlStateNormal];
        [self.payButton setEnabled:NO];
        [self.payButton setAlpha:0.5];
        [self.payButton setUserInteractionEnabled:NO];
    }
    
    // 隐藏恢复按钮
    if (self.recoveryButton) {
        [self.recoveryButton setHidden:YES];
    }
    
    // 修改提示文本
    if (self.contentLabel) {
        self.contentLabel.text = @"您已是永久Pro会员，享受全部功能";
        self.contentLabel.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:1.0];
    }
    
    // 禁用套餐选择
    if (self.monthItemView) {
        self.monthItemView.alpha = 0.5;
        self.monthItemView.userInteractionEnabled = NO;
    }
    if (self.yearsItemView) {
        self.yearsItemView.alpha = 0.5;
        self.yearsItemView.userInteractionEnabled = NO;
    }
    if (self.foreverItemView) {
        self.foreverItemView.alpha = 0.5;
        self.foreverItemView.userInteractionEnabled = NO;
    }
}

- (void)onPayButtonTouch {
    // 完全拦截支付
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是永久会员，无需重复购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onRecoveryButtonTouch {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复成功" 
                                                                   message:@"您的永久会员已恢复" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)isVipActive {
    return YES;
}

- (BOOL)checkVipStatus {
    return YES;
}

%end

// Hook VIP Manager
%hook DDVipManager

+ (instancetype)sharedManager {
    DDVipManager *manager = %orig;
    return manager;
}

- (BOOL)isVip {
    return YES;
}

- (BOOL)isPro {
    return YES;
}

- (BOOL)isFomzPro {
    return YES;
}

- (id)vipExpireDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter dateFromString:@"2999-12-29"];
}

- (void)setVipStatus:(BOOL)status {
    // 忽略设置
}

%end

// Hook NSUserDefaults
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro", @"isPremium", @"hasUnlockedPro", @"vipEnabled", @"proEnabled"];
    if ([vipKeys containsObject:defaultName]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate", @"proExpireDate", @"vipExpiration"];
    if ([expireKeys containsObject:defaultName]) {
        return @"2999-12-29";
    }
    return %orig;
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"vipType"]) {
        return 1; // 1代表永久
    }
    if ([defaultName isEqualToString:@"vipLevel"]) {
        return 9999;
    }
    return %orig;
}

%end

// Hook AppDelegate
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 设置所有VIP相关的UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro", @"isPremium", @"hasUnlockedPro", @"vipEnabled", @"proEnabled"];
    for (NSString *key in vipKeys) {
        [defaults setBool:YES forKey:key];
    }
    
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate", @"proExpireDate", @"vipExpiration"];
    for (NSString *key in expireKeys) {
        [defaults setObject:@"2999-12-29" forKey:key];
    }
    
    [defaults setInteger:1 forKey:@"vipType"];
    [defaults setInteger:9999 forKey:@"vipLevel"];
    [defaults synchronize];
    
    return result;
}

%end

// 初始化函数
%ctor {
    @autoreleasepool {
        // 立即修改UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isVip"];
        [defaults setBool:YES forKey:@"isPro"];
        [defaults setBool:YES forKey:@"isFomzPro"];
        [defaults setBool:YES forKey:@"isPremium"];
        [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
        [defaults setInteger:1 forKey:@"vipType"];
        [defaults synchronize];
        
        // 使用Method Swizzling拦截UILabel的setText
        Class labelClass = [UILabel class];
        Method originalMethod = class_getInstanceMethod(labelClass, @selector(setText:));
        method_setImplementation(originalMethod, (IMP)replaced_setText);
        original_setText = (void(*)(id, SEL, NSString*))method_getImplementation(originalMethod);
        
        NSLog(@"✅ Fomz Pro Unlock Tweak Loaded - All VIP features unlocked");
    }
}