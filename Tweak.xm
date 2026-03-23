// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 根据实际类结构声明
@interface DDSettingVipCell : UITableViewCell
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *fomzImageView;
@property (nonatomic, strong) UILabel *fomzLabel;
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
@property (nonatomic, strong) UILabel *payDesLabel;
- (void)onPayButtonTouch;
- (void)onRecoveryButtonTouch;
- (void)updateVIPUI;
@end

// 声明VIP管理类
@interface DDVipManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)isVip;
- (BOOL)isPro;
- (BOOL)isFomzPro;
- (id)vipExpireDate;
- (id)vipInfo;
@end

// 保存原始方法指针
static void (*original_setText)(id self, SEL _cmd, NSString *text);
static BOOL isModifying = NO;

static void replaced_setText(id self, SEL _cmd, NSString *text) {
    if (isModifying) {
        original_setText(self, _cmd, text);
        return;
    }
    
    // 检查是否需要修改
    BOOL shouldModify = NO;
    NSString *newText = nil;
    
    if (text && [text containsString:@"到期时间"]) {
        shouldModify = YES;
        newText = @"到期时间: 2999年12月29日";
    } else if (text && ([text containsString:@"Fomz"] || [text containsString:@"Pro"] || [text containsString:@"会员"])) {
        shouldModify = YES;
        newText = @"已升级 Fomz Pro";
    }
    
    if (shouldModify && newText) {
        isModifying = YES;
        original_setText(self, _cmd, newText);
        isModifying = NO;
    } else {
        original_setText(self, _cmd, text);
    }
}

// Hook DDSettingVipCell
%hook DDSettingVipCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.fomzLabel) {
            self.fomzLabel.text = @"已升级 Fomz Pro";
        }
        
        // 查找并修改expireLabel（可能在subviews中）
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subview;
                if (label.text && [label.text containsString:@"到期时间"]) {
                    label.text = @"到期时间: 2999年12月29日";
                } else if (label.text && [label.text containsString:@"Fomz"]) {
                    label.text = @"已升级 Fomz Pro";
                }
            }
        }
    });
}

- (void)layoutSubviews {
    %orig;
    
    if (self.fomzLabel && ![self.fomzLabel.text isEqualToString:@"已升级 Fomz Pro"]) {
        self.fomzLabel.text = @"已升级 Fomz Pro";
    }
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if (label.text && [label.text containsString:@"到期时间"]) {
                label.text = @"到期时间: 2999年12月29日";
            }
        }
    }
}

%end

// Hook DDVipViewController
%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    
    // 延迟执行多次确保UI更新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateVIPUI];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateVIPUI];
    });
}

- (void)updateVIPUI {
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
    
    // 修改支付按钮
    if (self.payButton) {
        [self.payButton setTitle:@"已激活永久会员" forState:UIControlStateNormal];
        [self.payButton setEnabled:NO];
        [self.payButton setAlpha:0.6];
        [self.payButton setUserInteractionEnabled:NO];
    }
    
    // 隐藏恢复按钮
    if (self.recoveryButton) {
        [self.recoveryButton setHidden:YES];
        [self.recoveryButton setUserInteractionEnabled:NO];
    }
    
    // 修改提示文本
    if (self.contentLabel) {
        self.contentLabel.text = @"您已是永久Pro会员，享受全部功能";
        self.contentLabel.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:1.0];
    }
    
    if (self.payDesLabel) {
        self.payDesLabel.text = @"永久会员已激活";
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
    // 拦截恢复购买，显示成功
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复成功" 
                                                                   message:@"您的永久会员已恢复" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// Hook DDVipManager - 关键！
%hook DDVipManager

+ (instancetype)sharedManager {
    DDVipManager *manager = %orig;
    NSLog(@"✅ DDVipManager sharedManager called");
    return manager;
}

- (BOOL)isVip {
    NSLog(@"✅ isVip called - returning YES");
    return YES;
}

- (BOOL)isPro {
    NSLog(@"✅ isPro called - returning YES");
    return YES;
}

- (BOOL)isFomzPro {
    NSLog(@"✅ isFomzPro called - returning YES");
    return YES;
}

- (id)vipExpireDate {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:946684800]; // 2000-01-01
    NSLog(@"✅ vipExpireDate called - returning 2999-12-29");
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter dateFromString:@"2999-12-29"];
}

- (id)vipInfo {
    NSLog(@"✅ vipInfo called");
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"isVip"] = @YES;
    info[@"isPro"] = @YES;
    info[@"expireDate"] = @"2999-12-29";
    info[@"vipType"] = @1;
    return info;
}

%end

// Hook NSUserDefaults
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro", @"isPremium", @"hasUnlockedPro", @"vipEnabled", @"proEnabled"];
    if ([vipKeys containsObject:defaultName]) {
        NSLog(@"✅ NSUserDefaults boolForKey:%@ - returning YES", defaultName);
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate", @"proExpireDate", @"vipExpiration"];
    if ([expireKeys containsObject:defaultName]) {
        NSLog(@"✅ NSUserDefaults objectForKey:%@ - returning 2999-12-29", defaultName);
        return @"2999-12-29";
    }
    return %orig;
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"vipType"]) {
        return 1;
    }
    if ([defaultName isEqualToString:@"vipLevel"]) {
        return 9999;
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName {
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro"];
    if ([vipKeys containsObject:defaultName]) {
        NSLog(@"✅ Blocked setting %@ to %d - forcing YES", defaultName, value);
        %orig(YES, defaultName);
        return;
    }
    %orig(value, defaultName);
}

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate"];
    if ([expireKeys containsObject:defaultName]) {
        NSLog(@"✅ Blocked setting %@ - forcing 2999-12-29", defaultName);
        %orig(@"2999-12-29", defaultName);
        return;
    }
    %orig(value, defaultName);
}

%end

// Hook AppDelegate
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 强制设置所有VIP相关的UserDefaults
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
    
    NSLog(@"✅ Fomz Pro: All VIP settings applied");
    
    return result;
}

%end

%ctor {
    @autoreleasepool {
        // 立即设置UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isVip"];
        [defaults setBool:YES forKey:@"isPro"];
        [defaults setBool:YES forKey:@"isFomzPro"];
        [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
        [defaults setInteger:1 forKey:@"vipType"];
        [defaults synchronize];
        
        // Hook UILabel的setText方法
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class labelClass = [UILabel class];
            SEL selector = @selector(setText:);
            Method originalMethod = class_getInstanceMethod(labelClass, selector);
            if (originalMethod) {
                original_setText = (void(*)(id, SEL, NSString*))method_getImplementation(originalMethod);
                method_setImplementation(originalMethod, (IMP)replaced_setText);
            }
        });
        
        NSLog(@"✅ Fomz Pro Tweak Loaded - All VIP features unlocked");
        NSLog(@"✅ Bundle ID: com.imendon.fomz");
        NSLog(@"✅ VIP status forced to YES");
    }
}