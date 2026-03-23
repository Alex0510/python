// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    // 使用performSelector或KVC来安全地获取私有属性
    UILabel *expireLabel = [self valueForKey:@"expireLabel"];
    if (expireLabel && [expireLabel isKindOfClass:[UILabel class]]) {
        [expireLabel setText:@"到期时间: 2999年12月29日"];
    }
    
    UILabel *tipsLabel = [self valueForKey:@"tipsLabel"];
    if (tipsLabel && [tipsLabel isKindOfClass:[UILabel class]]) {
        [tipsLabel setText:@"已升级 Fomz Pro"];
    }
    
    UILabel *fomzLabel = [self valueForKey:@"fomzLabel"];
    if (fomzLabel && [fomzLabel isKindOfClass:[UILabel class]]) {
        [fomzLabel setText:@"PRO"];
    }
    
    UIImageView *fomzImageView = [self valueForKey:@"fomzImageView"];
    if (fomzImageView) {
        // 可选：修改图标
        [fomzImageView setAlpha:1.0];
    }
}

// 如果cell会被重用，也需要在layoutSubviews中修改
- (void)layoutSubviews {
    %orig;
    
    UILabel *expireLabel = [self valueForKey:@"expireLabel"];
    if (expireLabel && [expireLabel.text isEqualToString:@"到期时间: 2999年12月29日"] == NO) {
        [expireLabel setText:@"到期时间: 2999年12月29日"];
    }
    
    UILabel *tipsLabel = [self valueForKey:@"tipsLabel"];
    if (tipsLabel && [tipsLabel.text isEqualToString:@"已升级 Fomz Pro"] == NO) {
        [tipsLabel setText:@"已升级 Fomz Pro"];
    }
}

%end

%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    
    // 在viewDidLoad中设置，避免重复执行
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 修改价格为永久
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
        UIButton *payButton = [self valueForKey:@"payButton"];
        if (payButton && [payButton isKindOfClass:[UIButton class]]) {
            [payButton setTitle:@"已激活永久会员" forState:UIControlStateNormal];
            [payButton setEnabled:NO];
            [payButton setAlpha:0.6];
        }
        
        // 隐藏恢复按钮
        UIButton *recoveryButton = [self valueForKey:@"recoveryButton"];
        if (recoveryButton && [recoveryButton isKindOfClass:[UIButton class]]) {
            [recoveryButton setHidden:YES];
        }
        
        // 修改内容标签
        UILabel *contentLabel = [self valueForKey:@"contentLabel"];
        if (contentLabel && [contentLabel isKindOfClass:[UILabel class]]) {
            [contentLabel setText:@"您已是永久Pro会员，享受全部功能"];
        }
        
        // 如果有套餐选择视图，隐藏或禁用它们
        UIView *monthItemView = [self valueForKey:@"monthItemView"];
        if (monthItemView) {
            [monthItemView setAlpha:0.5];
            [monthItemView setUserInteractionEnabled:NO];
        }
        
        UIView *yearsItemView = [self valueForKey:@"yearsItemView"];
        if (yearsItemView) {
            [yearsItemView setAlpha:0.5];
            [yearsItemView setUserInteractionEnabled:NO];
        }
        
        UIView *foreverItemView = [self valueForKey:@"foreverItemView"];
        if (foreverItemView) {
            [foreverItemView setAlpha:0.5];
            [foreverItemView setUserInteractionEnabled:NO];
        }
    });
}

- (void)viewDidLayoutSubviews {
    %orig;
}

- (void)onPayButtonTouch {
    // 完全拦截支付点击
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是永久会员，无需重复购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onRecoveryButtonTouch {
    // 拦截恢复购买，显示成功提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复成功" 
                                                                   message:@"您的永久会员已恢复" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// 如果应用有AppDelegate，可以hook它来在启动时修改
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 在应用启动时就修改VIP状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
    [defaults setObject:@"2999-12-29" forKey:@"expireDate"];
    [defaults setObject:@"2999-12-29" forKey:@"proExpireDate"];
    [defaults setBool:YES forKey:@"isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isFomzPro"];
    [defaults setBool:YES forKey:@"isPremium"];
    [defaults setInteger:1 forKey:@"vipType"]; // 1代表永久
    [defaults setInteger:9999 forKey:@"vipLevel"];
    [defaults synchronize];
    
    return result;
}

%end

// 修改本地存储和检查方法
%ctor {
    // 立即修改UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
    [defaults setObject:@"2999-12-29" forKey:@"expireDate"];
    [defaults setObject:@"2999-12-29" forKey:@"proExpireDate"];
    [defaults setBool:YES forKey:@"isVip"];
    [defaults setBool:YES forKey:@"isPro"];
    [defaults setBool:YES forKey:@"isFomzPro"];
    [defaults setBool:YES forKey:@"isPremium"];
    [defaults setBool:YES forKey:@"hasUnlockedPro"];
    [defaults setInteger:1 forKey:@"vipType"];
    [defaults setInteger:9999 forKey:@"vipLevel"];
    [defaults synchronize];
    
    NSLog(@"✅ Fomz Pro Unlock Tweak Loaded - VIP set to permanent");
    
    // 可选：hook NSUserDefaults的读取方法，总是返回VIP状态
    Class userDefaultsClass = NSClassFromString(@"NSUserDefaults");
    if (userDefaultsClass) {
        // Hook boolForKey: 方法
        MSHookMessageEx(userDefaultsClass, @selector(boolForKey:), (IMP)&$NSUserDefaults$boolForKey$, (IMP*)&_NSUserDefaults$boolForKey$);
        
        // Hook objectForKey: 方法
        MSHookMessageEx(userDefaultsClass, @selector(objectForKey:), (IMP)&$NSUserDefaults$objectForKey$, (IMP*)&_NSUserDefaults$objectForKey$);
        
        // Hook integerForKey: 方法
        MSHookMessageEx(userDefaultsClass, @selector(integerForKey:), (IMP)&$NSUserDefaults$integerForKey$, (IMP*)&_NSUserDefaults$integerForKey$);
    }
}

// 辅助函数：NSUserDefaults hook
static BOOL (*_NSUserDefaults$boolForKey$)(id self, SEL _cmd, NSString *key);
static BOOL $NSUserDefaults$boolForKey$(id self, SEL _cmd, NSString *key) {
    NSArray *vipKeys = @[@"isVip", @"isPro", @"isFomzPro", @"isPremium", @"hasUnlockedPro"];
    if ([vipKeys containsObject:key]) {
        return YES;
    }
    return _NSUserDefaults$boolForKey$(self, _cmd, key);
}

static id (*_NSUserDefaults$objectForKey$)(id self, SEL _cmd, NSString *key);
static id $NSUserDefaults$objectForKey$(id self, SEL _cmd, NSString *key) {
    NSArray *expireKeys = @[@"vipExpireDate", @"expireDate", @"proExpireDate"];
    if ([expireKeys containsObject:key]) {
        return @"2999-12-29";
    }
    return _NSUserDefaults$objectForKey$(self, _cmd, key);
}

static NSInteger (*_NSUserDefaults$integerForKey$)(id self, SEL _cmd, NSString *key);
static NSInteger $NSUserDefaults$integerForKey$(id self, SEL _cmd, NSString *key) {
    NSArray *vipTypeKeys = @[@"vipType", @"vipLevel"];
    if ([key isEqualToString:@"vipType"]) {
        return 1;
    }
    if ([key isEqualToString:@"vipLevel"]) {
        return 9999;
    }
    return _NSUserDefaults$integerForKey$(self, _cmd, key);
}