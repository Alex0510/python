// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Tweak.xm
%hook DDSettingVipExpireCell

- (void)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    %orig;
    
    // 修改VIP过期标签
    if (self.$__lazy_storage_$_expireLabel) {
        [self.$__lazy_storage_$_expireLabel setText:@"到期时间: 2999年12月29日"];
    }
    if (self.$__lazy_storage_$_tipsLabel) {
        [self.$__lazy_storage_$_tipsLabel setText:@"已升级 Fomz Pro"];
    }
}

%end

%hook DDVipViewController

- (void)viewDidLayoutSubviews {
    %orig;
    
    // 修改价格为永久
    self.monthPriceString = @"永久免费";
    self.yearsPriceString = @"永久免费";
    self.foreverPriceString = @"永久免费";
    
    // 修改支付按钮
    [self.$__lazy_storage_$_payButton setTitle:@"已激活永久会员" forState:UIControlStateNormal];
    [self.$__lazy_storage_$_payButton setEnabled:NO];
    
    // 隐藏恢复按钮
    [self.$__lazy_storage_$_recoveryButton setHidden:YES];
}

- (void)onPayButtonTouch {
    // 拦截支付点击，显示提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"您已是永久会员，无需重复购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// 修改本地存储
%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"2999-12-29" forKey:@"vipExpireDate"];
    [defaults setBool:YES forKey:@"isVip"];
    [defaults setBool:YES forKey:@"isFomzPro"];
    [defaults synchronize];
}