#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
// 1. 修改闪照 Cell 的外观，使其与普通照片一致
// ============================================================
%hook Qing_ios.QMessageDetailOtherFlashImageCell

- (void)setItemModel:(id)model {
    %orig;

    // 通过 KVC 获取私有子视图
    UIView *rootView = [self valueForKey:@"rootView"];
    UIImageView *contentImg = [self valueForKey:@"contentImgView"];
    UIImageView *stateIcon = [self valueForKey:@"stateIconImgView"];
    UILabel *stateLabel = [self valueForKey:@"stateLab"];

    if (rootView) {
        // 隐藏闪电图标和“点击查看”文字
        stateIcon.hidden = YES;
        stateLabel.hidden = YES;
        rootView.backgroundColor = [UIColor clearColor];

        // 让内容图片填充整个 rootView
        if (contentImg) {
            contentImg.frame = rootView.bounds;
            contentImg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            contentImg.contentMode = UIViewContentModeScaleAspectFill; // 与普通照片一致
        }
    }
}

- (void)layoutSubviews {
    %orig;

    // 再次确保图片视图的 frame 正确（防止布局变化导致错位）
    UIView *rootView = [self valueForKey:@"rootView"];
    UIImageView *contentImg = [self valueForKey:@"contentImgView"];
    if (rootView && contentImg) {
        contentImg.frame = rootView.bounds;
    }
}

%end

// ============================================================
// 2. 拦截闪照 Cell 的点击，改用自定义预览（绕过闪照控制器）
// ============================================================
%hook Qing_ios.QMessageDetailController

- (void)cellHandleTap:(UITapGestureRecognizer *)gesture {
    // 查找被点击的 Cell
    UIView *view = gesture.view;
    UITableViewCell *cell = nil;
    while (view && ![view isKindOfClass:[UITableViewCell class]]) {
        view = view.superview;
    }
    cell = (UITableViewCell *)view;

    // 判断是否为闪照 Cell
    if (cell && [cell isKindOfClass:NSClassFromString(@"Qing_ios.QMessageDetailOtherFlashImageCell")]) {
        // 获取图片
        UIImageView *contentImg = [cell valueForKey:@"contentImgView"];
        UIImage *image = contentImg.image;

        // 若图片尚未加载完成，可尝试从模型获取 URL 异步加载（此处略）
        if (!image) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"图片尚未加载" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (topVC.presentedViewController) topVC = topVC.presentedViewController;
            [topVC presentViewController:alert animated:YES completion:nil];
            return;
        }

        // 创建自定义图片预览控制器
        UIViewController *previewVC = [[UIViewController alloc] init];
        previewVC.modalPresentationStyle = UIModalPresentationFullScreen;

        UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        imgView.frame = [UIScreen mainScreen].bounds;
        imgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        previewVC.view = imgView;
        previewVC.view.backgroundColor = [UIColor blackColor];

        // 添加关闭按钮
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        closeBtn.frame = CGRectMake(20, 40, 60, 30);
        [closeBtn addTarget:previewVC action:@selector(dismissViewControllerAnimated:completion:) forControlEvents:UIControlEventTouchUpInside];
        [previewVC.view addSubview:closeBtn];

        // 获取顶层控制器并 present
        UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topVC.presentedViewController) topVC = topVC.presentedViewController;
        [topVC presentViewController:previewVC animated:YES completion:nil];

        return; // 拦截完成，不再执行原方法
    }

    // 其他情况（普通照片、文字等）调用原方法
    %orig;
}

%end

// ============================================================
// 3. （可选）若因故仍进入闪照控制器，移除防截屏层
// ============================================================
%hook Qing_ios.QMessageFlashPhotoController

- (void)viewDidLoad {
    %orig;

    // 移除 ScreenshotPreventingView
    for (UIView *subview in self.view.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"ScreenshotPreventing"]) {
            [subview removeFromSuperview];
            break;
        }
    }
}

%end