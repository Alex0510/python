// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================
// 类接口声明 - 解决前向声明问题
// ============================================

// DDLoginManager
@interface DDLoginManager : NSObject
+ (id)sharedInstance;
- (BOOL)vipStatus;
- (long long)vipExpiredTs;
- (void)setVipStatus:(BOOL)status;
@end

// DDVipViewController
@interface DDVipViewController : UIViewController
- (void)onPayButtonTouch;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
@end

// DDStoreHomeViewController
@interface DDStoreHomeViewController : UIViewController
- (void)onVipButtonTouch;
- (void)reloadData;
- (void)loadData;
- (void)viewDidLoad;
@end

// DDStoreListView
@interface DDStoreListView : NSObject
- (NSArray *)dataArray;
@end

// DDMoreFilterPopView
@interface DDMoreFilterPopView : UIView
- (void)onVipButtonTouch;
- (void)reloadData;
- (void)viewDidLoad;
@end

// DDFilterThumeListView
@interface DDFilterThumeListView : NSObject
- (NSArray *)datas;
- (BOOL)isVipFilter:(id)filter;
@end

// DDPhotoEditViewController
@interface DDPhotoEditViewController : UIViewController
- (BOOL)canUseAdjustment:(long long)adjustmentType;
- (BOOL)isVipFeature;
- (void)onSaveButtonTouch;
@end

// DDPhotoAdjustListView
@interface DDPhotoAdjustListView : NSObject
- (BOOL)isVipAdjustment:(id)adjustment;
- (void)onResetItemViewTouch;
@end

// DDFilterCell
@interface DDFilterCell : UITableViewCell
- (BOOL)isVipLocked;
- (void)onActionButtonTouch;
- (void)onIconImageViewTouchWithGesture:(id)gesture;
@end

// DDPhotoDetailViewController
@interface DDPhotoDetailViewController : UIViewController
- (BOOL)canExportVideo;
- (BOOL)canExportImage;
- (void)onShareButtonTouch;
- (void)onDownloadButtonTouch;
@end

// DDImagePickerViewController
@interface DDImagePickerViewController : UIViewController
- (BOOL)canSelectPhoto;
- (void)onNextButtonTouch;
@end

// DDPAGTemplateCreateViewController
@interface DDPAGTemplateCreateViewController : UIViewController
- (BOOL)shouldAddWatermark;
- (void)onSaveButtonTouch;
@end

// DDVideoCropManager
@interface DDVideoCropManager : NSObject
- (BOOL)canExportVideoWithoutWatermark;
- (BOOL)canExportHD;
@end

// ABTimestampSettingListView
@interface ABTimestampSettingListView : NSObject
- (BOOL)isVipFeature;
- (void)onNoneButtonTouch;
@end

// DDApplePurchaseManager
@interface DDApplePurchaseManager : NSObject
- (void)buyProductWithType:(long long)type complete:(void (^)(BOOL, id))complete;
- (void)restoreWithComplete:(void (^)(BOOL, id))complete;
@end

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
    return 4092599349; // 2099-01-01
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self performSelector:@selector(onPayButtonTouch) withObject:nil afterDelay:0.1];
    });
}

- (void)onPayButtonTouch {
    DDLoginManager *loginManager = [DDLoginManager sharedInstance];
    [loginManager setVipStatus:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

%end

// ============================================
// DDStoreHomeViewController - 商城
// ============================================
%hook DDStoreHomeViewController

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIView *vipButton = [self valueForKey:@"vipButton"];
        if (vipButton) vipButton.hidden = YES;
        UIView *vipView = [self valueForKey:@"vipView"];
        if (vipView) vipView.hidden = YES;
    });
}

- (void)onVipButtonTouch {
    DDLoginManager *loginManager = [DDLoginManager sharedInstance];
    [loginManager setVipStatus:YES];
    [self reloadData];
}

%end

// ============================================
// DDStoreListView - 商城列表
// ============================================
%hook DDStoreListView

- (NSArray *)dataArray {
    return %orig;
}

%end

// ============================================
// DDMoreFilterPopView - 滤镜弹窗
// ============================================
%hook DDMoreFilterPopView

- (void)viewDidLoad {
    %orig;
    DDLoginManager *loginManager = [DDLoginManager sharedInstance];
    [loginManager setVipStatus:YES];
}

- (void)onVipButtonTouch {
    DDLoginManager *loginManager = [DDLoginManager sharedInstance];
    [loginManager setVipStatus:YES];
    [self reloadData];
}

%end

// ============================================
// DDFilterThumeListView - 滤镜列表
// ============================================
%hook DDFilterThumeListView

- (BOOL)isVipFilter:(id)filter {
    return NO;
}

- (NSArray *)datas {
    return %orig;
}

%end

// ============================================
// DDPhotoEditViewController - 图片编辑
// ============================================
%hook DDPhotoEditViewController

- (BOOL)canUseAdjustment:(long long)adjustmentType {
    return YES;
}

- (BOOL)isVipFeature {
    return YES;
}

- (void)onSaveButtonTouch {
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
    %orig;
}

- (void)onDownloadButtonTouch {
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
    %orig;
}

%end

// ============================================
// DDPAGTemplateCreateViewController - 模板创建
// ============================================
%hook DDPAGTemplateCreateViewController

- (BOOL)shouldAddWatermark {
    return NO;
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
    if (complete) {
        complete(YES, nil);
    }
}

- (void)restoreWithComplete:(void (^)(BOOL, id))complete {
    if (complete) {
        complete(YES, nil);
    }
}

%end

// ============================================
// NSObject 扩展 - 通用VIP检查
// ============================================
%hook NSObject

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
// 构造函数
// ============================================
%ctor {
    NSLog(@"FomzPro Loaded - Pro Features Unlocked");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        DDLoginManager *loginManager = [DDLoginManager sharedInstance];
        if (loginManager) {
            [loginManager setVipStatus:YES];
            NSLog(@"FomzPro: VIP Activated");
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" 
                                                            object:nil 
                                                          userInfo:@{@"isVip": @YES}];
    });
}