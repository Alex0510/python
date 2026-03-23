// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 声明DDSettingVipExpireCell类
@interface DDSettingVipExpireCell : UITableViewCell
@property (nonatomic, strong) UILabel *expireLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UILabel *fomzLabel;
@property (nonatomic, strong) UIImageView *fomzImageView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *crowImageView;
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
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *nameImageView;
@property (nonatomic, strong) UILabel *payDesLabel;
@property (nonatomic, strong) UIButton *userProtocolButton;
@property (nonatomic, strong) UIButton *priviteProtocolButton;
@property (nonatomic, strong) UIButton *vipProtocolButton;
@property (nonatomic, strong) UIView *lineView1;
@property (nonatomic, strong) UIView *lineView2;
- (void)onPayButtonTouch;
- (void)onRecoveryButtonTouch;
- (void)setMonthPriceString:(NSString *)price;
- (void)setYearsPriceString:(NSString *)price;
- (void)setForeverPriceString:(NSString *)price;
@end

// 声明AppDelegate
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    // 直接访问属性
    if (self.expireLabel) {
        [self.expireLabel setText:@"到期时间: 2999年12月29日"];
    }
    if (self.tipsLabel) {
        [self.tipsLabel setText:@"已升级 Fomz Pro"];
    }
    if (self.fomzLabel) {
        [self.fomzLabel setText:@"PRO"];
    }
    if (self.fomzImageView) {
        [self.fomzImageView setAlpha:1.0];
    }
}

- (void)layoutSubviews {
    %orig;
    
    // 确保每次布局时都更新文字
    if (self.expireLabel && ![self.expireLabel.text isEqualToString:@"到期时间: 2999年12月29日"]) {
        [self.expireLabel setText:@"到期时间: 2999年12月29日"];
    }
    if (self.tipsLabel && ![self.tipsLabel.text isEqualToString:@"已升级 Fomz Pro"]) {
        [self.tipsLabel setText:@"已升级 Fomz Pro"];
    }
}

%end

%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    
    // 延迟一点确保视图完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 修改价格为永久
        [self setMonthPriceString:@"永久免费"];
        [self setYearsPriceString:@"永久免费"];
        [self setForeverPriceString:@"永久免费"];
        
        // 修改支付按钮
        if (self.payButton) {
            [self.payButton setTitle:@"已激活永久会员" forState:UIControlStateNormal];
            [self.payButton setEnabled:NO];
            [self.payButton setAlpha:0.6];
        }
        
        // 隐藏恢复按钮
        if (self.recoveryButton) {
            [self.recoveryButton setHidden:YES];
        }
        
        // 修改内容标签
        if (self.contentLabel) {
            [self.contentLabel setText:@"您已是永久Pro会员，享受全部功能"];
        }
        
        // 禁用套餐选择
        if (self.monthItemView) {
            [self.monthItemView setAlpha:0.5];
            [self.monthItemView setUserInteractionEnabled:NO];
        }
        if (self.yearsItemView) {
            [self.yearsItemView setAlpha:0.5];
            [self.yearsItemView setUserInteractionEnabled:NO];
        }
        if (self.foreverItemView) {
            [self.foreverItemView setAlpha:0.5];
            [self.foreverItemView setUserInteractionEnabled:NO];
        }
    });
}

- (void)viewDidLayoutSubviews {
    %orig;
}

- (void)onPayButtonTouch {
    // 拦截支付点击
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是永久会员，无需重复购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onRecoveryButtonTouch {
    // 拦截恢复购买
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复成功" 
                                                                   message:@"您的永久会员已恢复" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 修改UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
    [defaults setObject:@"2999-12-29" forKey:@"expireDate"];
    [defaults setBool:YES forKey:@"isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isFomzPro"];
    [defaults setBool:YES forKey:@"isPremium"];
    [defaults setInteger:1 forKey:@"vipType"];
    [defaults synchronize];
    
    return result;
}

%end

// 初始化函数
%ctor {
    @autoreleasepool {
        // 立即修改UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
        [defaults setObject:@"2999-12-29" forKey:@"expireDate"];
        [defaults setBool:YES forKey:@"isVip"];
        [defaults setBool:YES forKey:@"isPro"];
        [defaults setBool:YES forKey:@"isFomzPro"];
        [defaults setBool:YES forKey:@"isPremium"];
        [defaults setInteger:1 forKey:@"vipType"];
        [defaults synchronize];
        
        NSLog(@"✅ Fomz Pro Unlock Tweak Loaded");
    }
}