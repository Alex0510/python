// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================
// DDLoginManager - VIP状态管理
// ============================================
%hook DDLoginManager

+ (id)sharedInstance {
    return %orig;
}

- (BOOL)vipStatus {
    return YES;
}

- (long long)vipExpiredTs {
    // 设置为2099年
    return 4092599349;
}

- (BOOL)isVip {
    return YES;
}

- (BOOL)hasProAccess {
    return YES;
}

- (void)setVipStatus:(BOOL)status {
    %orig(YES);
}

%end

// ============================================
// DDVipViewController - VIP购买页面
// ============================================
%hook DDVipViewController

- (void)viewDidLoad {
    %orig;
    // 自动授予VIP并关闭页面
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self performSelector:@selector(onPayButtonTouch) withObject:nil afterDelay:0.1];
    });
}

- (void)onPayButtonTouch {
    // 模拟支付成功
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    
    // 显示成功提示
    [self showSuccessAlert];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSuccessAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"激活成功" 
                                                                   message:@"已解锁所有Pro功能" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// ============================================
// DDStoreHomeViewController - 商城
// ============================================
%hook DDStoreHomeViewController

- (void)viewDidLoad {
    %orig;
    // 隐藏VIP按钮
    [self performSelector:@selector(hideVipButton) withObject:nil afterDelay:0.1];
}

- (void)hideVipButton {
    UIView *vipButton = [self valueForKey:@"vipButton"];
    if (vipButton) {
        vipButton.hidden = YES;
    }
    UIView *vipView = [self valueForKey:@"vipView"];
    if (vipView) {
        vipView.hidden = YES;
    }
}

- (void)onVipButtonTouch {
    // 直接授予VIP
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    
    // 刷新界面
    [self reloadData];
}

- (void)reloadData {
    // 重新加载数据
    [self performSelector:@selector(loadData)];
}

%end

// ============================================
// DDStoreListView - 商城列表
// ============================================
%hook DDStoreListView

- (NSArray *)dataArray {
    NSArray *originalData = %orig;
    // 返回所有数据，不过滤VIP内容
    return originalData;
}

- (BOOL)shouldFilterVipContent {
    return NO;
}

%end

// ============================================
// DDMoreFilterPopView - 滤镜弹窗
// ============================================
%hook DDMoreFilterPopView

- (void)viewDidLoad {
    %orig;
    // 自动授予VIP权限
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
}

- (void)onVipButtonTouch {
    // 直接授予VIP
    DDLoginManager *loginManager = [NSClassFromString(@"DDLoginManager") performSelector:@selector(sharedInstance)];
    [loginManager setVipStatus:YES];
    [self reloadData];
}

- (void)onTimestampButtonTouch {
    // 直接使用时间戳功能
    %orig;
}

%end

// ============================================
// DDFilterThumeListView - 滤镜列表
// ============================================
%hook DDFilterThumeListView

- (BOOL)isVipFilter:(id)filter {
    return NO; // 所有滤镜都不是VIP专属
}

- (NSArray *)datas {
    NSArray *data = %orig;
    // 确保所有数据都可见
    return data;
}

%end

// ============================================
// DDPhotoEditViewController - 图片编辑
// ============================================
%hook DDPhotoEditViewController

- (BOOL)canUseAdjustment:(long long)adjustmentType {
    return YES; // 所有调整功能都可用
}

- (BOOL)isVipFeature {
    return YES;
}

- (void)onSaveButtonTouch {
    // 允许保存编辑后的图片
    %orig;
}

%end

// ============================================
// DDPhotoAdjustListView - 调整列表
// ============================================
%hook DDPhotoAdjustListView

- (BOOL)isVipAdjustment:(id)adjustment {
    return NO;
}

- (void)onResetItemViewTouch {
    %orig;
}

%end

// ============================================
// DDFilterCell - 滤镜单元格
// ============================================
%hook DDFilterCell

- (BOOL)isVipLocked {
    return NO;
}

- (void)onActionButtonTouch {
    // 直接使用，不检查VIP
    %orig;
}

- (void)onIconImageViewTouchWithGesture:(id)gesture {
    %orig;
}

%end

// ============================================
// DDPhotoDetailViewController - 照片详情
// ============================================
%hook DDPhotoDetailViewController

- (BOOL)canExportVideo {
    return YES;
}

- (BOOL)canExportImage {
    return YES;
}

- (void)onShareButtonTouch {
    // 允许分享
    %orig;
}

- (void)onDownloadButtonTouch {
    // 允许下载
    %orig;
}

%end

// ============================================
// DDImagePickerViewController - 图片选择器
// ============================================
%hook DDImagePickerViewController

- (BOOL)canSelectPhoto {
    return YES;
}

- (void)onNextButtonTouch {
    // 允许继续
    %orig;
}

%end

// ============================================
// DDPAGTemplateCreateViewController - 模板创建
// ============================================
%hook DDPAGTemplateCreateViewController

- (BOOL)shouldAddWatermark {
    return NO; // VIP无水印
}

- (void)onSaveButtonTouch {
    %orig;
}

%end

// ============================================
// DDVideoCropManager - 视频裁剪
// ============================================
%hook DDVideoCropManager

- (BOOL)canExportVideoWithoutWatermark {
    return YES;
}

- (BOOL)canExportHD {
    return YES;
}

%end

// ============================================
// ABTimestampSettingListView - 时间戳设置
// ============================================
%hook ABTimestampSettingListView

- (BOOL)isVipFeature {
    return YES;
}

- (void)onNoneButtonTouch {
    %orig;
}

%end

// ============================================
// DDApplePurchaseManager - 内购管理
// ============================================
%hook DDApplePurchaseManager

- (void)buyProductWithType:(long long)type complete:(void (^)(BOOL, id))complete {
    // 模拟购买成功
    if (complete) {
        complete(YES, nil);
    }
}

- (void)restoreWithComplete:(void (^)(BOOL, id))complete {
    // 模拟恢复成功
    if (complete) {
        complete(YES, nil);
    }
}

%end

// ============================================
// 通用VIP检查方法
// ============================================
%hook NSObject (VIPCheck)

- (BOOL)isVIP {
    return YES;
}

- (BOOL)isProUser {
    return YES;
}

- (BOOL)hasProPermission {
    return YES;
}

%end

// ============================================
// 构造函数 - 应用启动时初始化
// ============================================
%ctor {
    NSLog(@"FomzPro Tweak Loaded - Unlocking Pro Features");
    
    // 延迟设置VIP状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        Class loginManagerClass = NSClassFromString(@"DDLoginManager");
        if (loginManagerClass) {
            id loginManager = [loginManagerClass performSelector:@selector(sharedInstance)];
            if (loginManager && [loginManager respondsToSelector:@selector(setVipStatus:)]) {
                [loginManager setVipStatus:YES];
                NSLog(@"FomzPro: VIP Status Activated");
            }
        }
        
        // 发送VIP状态更新通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" 
                                                            object:nil 
                                                          userInfo:@{@"isVip": @YES}];
    });
}