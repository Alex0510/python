// Tweak.xm
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%hook DDLoginManager

// 返回VIP状态为YES
- (BOOL)vipStatus {
    return YES;
}

// 返回远期过期时间（2099年）
- (long long)vipExpiredTs {
    return 4092599349; // 2099-01-01 00:00:00
}

// 强制更新VIP状态
- (void)setVipStatus:(BOOL)status {
    %orig(YES);
}

%end

%hook DDVipViewController

// 跳过VIP购买页面，直接返回成功
- (void)onPayButtonTouch {
    // 模拟支付成功
    [self performSelector:@selector(paymentSuccess) withObject:nil afterDelay:0.1];
}

- (void)paymentSuccess {
    // 更新VIP状态
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    
    // 关闭页面
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // 显示成功弹窗
    DDVipPaySuccessPopView *popView = [[NSClassFromString(@"DDVipPaySuccessPopView") alloc] init];
    [popView show];
}

%end

%hook DDStoreHomeViewController

// 跳过VIP检查，显示所有内容
- (void)onVipButtonTouch {
    // 直接授予VIP，不跳转购买页
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    
    // 刷新界面
    [self reloadData];
}

// 返回VIP按钮隐藏状态为YES（不显示VIP按钮）
- (BOOL)shouldShowVipButton {
    return NO;
}

%end

%hook DDStoreListView

// 返回所有数据，不过滤VIP内容
- (id)dataArray {
    id originalData = %orig;
    return originalData; // 返回完整数据，不过滤
}

%end

%hook DDMoreFilterPopView

// 跳过VIP检查，显示所有滤镜
- (void)onVipButtonTouch {
    // 直接授予VIP
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    [self reloadData];
}

%end

%hook DDApplePurchaseManager

// 拦截内购，直接返回成功
- (void)buyProductWithType:(long long)type complete:(id)complete {
    // 模拟购买成功
    if (complete) {
        void (^completion)(BOOL success, id error) = complete;
        completion(YES, nil);
    }
}

%end

// 修改VIP检查宏或方法（如果存在）
%hook DDPhotoEditViewController

// 允许VIP功能
- (BOOL)isVipFeature {
    return YES;
}

%end

// 修改滤镜类VIP检查
%hook DDFilterCell

// 跳过VIP锁定的滤镜
- (BOOL)isVipLocked {
    return NO;
}

- (void)onActionButtonTouch {
    // 直接使用，不检查VIP
    %orig;
}

%end

// 修改导出功能（如果有VIP限制）
%hook DDPhotoDetailViewController

- (BOOL)canExportVideo {
    return YES;
}

- (BOOL)canExportImage {
    return YES;
}

%end

// 修改水印（如果有VIP去除水印功能）
%hook DDPAGTemplateCreateViewController

- (BOOL)shouldAddWatermark {
    return NO; // VIP无水印
}

%end

// 修改时间戳功能（VIP功能）
%hook ABTimestampSettingListView

- (BOOL)isVipFeature {
    return YES;
}

%end

// 构造函数
%ctor {
    // 在应用启动时直接设置VIP状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        Class loginManagerClass = NSClassFromString(@"DDLoginManager");
        if (loginManagerClass) {
            id loginManager = [loginManagerClass performSelector:@selector(sharedInstance)];
            if (loginManager) {
                [loginManager setVipStatus:YES];
            }
        }
    });
}