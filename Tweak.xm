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
@end

// 声明DDVipViewController类 - 添加updateVIPUI方法声明
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
- (void)updateVIPUI;  // 添加这个方法声明
@end

// 声明VIP管理类
@interface DDVipManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)isVip;
- (BOOL)isPro;
- (BOOL)isFomzPro;
- (id)vipExpireDate;
@end

// 保存原始方法指针
static void (*original_setText)(id self, SEL _cmd, NSString *text);
static BOOL isModifying = NO;

// 新的setText实现 - 修复无限递归
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
    } else if (text && ([text containsString:@"Fomz"] || [text containsString:@"Pro"])) {
        shouldModify = YES;
        newText = @"已升级 Fomz Pro";
    } else if (text && [text containsString:@"会员"]) {
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

%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.expireLabel) {
            self.expireLabel.text = @"到期时间: 2999年12月29日";
        }
        if (self.tipsLabel) {
            self.tipsLabel.text = @"已升级 Fomz Pro";
        }
        if (self.fomzLabel) {
            self.fomzLabel.text = @"PRO";
        }
    });
}

- (void)layoutSubviews {
    %orig;
    
    if (self.expireLabel && ![self.expireLabel.text isEqualToString:@"到期时间: 2999年12月29日"]) {
        self.expireLabel.text = @"到期时间: 2999年12月29日";
    }
    if (self.tipsLabel && ![self.tipsLabel.text isEqualToString:@"已升级 Fomz Pro"]) {
        self.tipsLabel.text = @"已升级 Fomz Pro";
    }
}

%end

%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    
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
    }
    
    // 修改提示文本
    if (self.contentLabel) {
        self.contentLabel.text = @"您已是永久Pro会员，享受全部功能";
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

%end

// Hook NSUserDefaults
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro", @"isPremium", @"hasUnlockedPro"];
    if ([vipKeys containsObject:defaultName]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate", @"proExpireDate"];
    if ([expireKeys containsObject:defaultName]) {
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

%end

// Hook AppDelegate
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 设置VIP状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isFomzPro"];
    [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
    [defaults setInteger:1 forKey:@"vipType"];
    [defaults synchronize];
    
    return result;
}

%end

%ctor {
    @autoreleasepool {
        // 设置UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isVip"];
        [defaults setBool:YES forKey:@"isPro"];
        [defaults setBool:YES forKey:@"isFomzPro"];
        [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
        [defaults synchronize];
        
        // 安全地hook UILabel的setText方法
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class labelClass = [UILabel class];
            SEL selector = @selector(setText:);
            Method originalMethod = class_getInstanceMethod(labelClass, selector);
            if (originalMethod) {
                original_setText = (void(*)(id, SEL, NSString*))method_getImplementation(originalMethod);
                method_setImplementation(originalMethod, (IMP)replaced_setText);
                NSLog(@"✅ Fomz Pro Tweak Loaded - UILabel hooked");
            }
        });
        
        NSLog(@"✅ Fomz Pro Tweak Loaded Successfully");
    }
}