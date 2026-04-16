#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Security/Security.h>
#import <os/log.h>

// 函数声明
void DebugLog(NSString *format, ...);
static void CreateEnhancedFloatingWindow(void);
static void ClearKeychainData(NSString *bundleIdentifier);

// 清理统计信息类
@interface CleaningStats : NSObject
@property (nonatomic, assign) NSUInteger filesDeleted;
@property (nonatomic, assign) long long bytesFreed;
@property (nonatomic, strong) NSDate *lastCleaningDate;
@property (nonatomic, assign) NSTimeInterval cleaningDuration;
@end

// 增强版悬浮窗类
@interface EnhancedFloatingWindow : UIWindow
@property (nonatomic, strong) UILabel *winterLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *progressOverlay;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;

// 高优先级功能方法
- (void)showCleaningOptions;
- (void)showConfirmationDialog;
- (void)showProgressIndicator;
- (void)updateProgress:(float)progress withStatus:(NSString *)status;
- (void)hideProgressIndicator;
- (void)showCleaningResults:(CleaningStats *)stats;

// 清理功能方法
- (void)clearCacheOnly;
- (void)clearUserDataOnly;
- (void)performFullCleanWithAnimation;
- (void)clearAppDataWithProgress;
- (void)exitApplication;

// 原有方法
- (void)handleTap:(UITapGestureRecognizer *)gesture;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
- (void)startPulseAnimation;
- (UIWindow *)getKeyWindow;
- (UIViewController *)findPresentingViewController;
- (UIViewController *)findTopViewController:(UIViewController *)baseViewController;
@end

// 清理统计信息类实现
@implementation CleaningStats

- (instancetype)init {
    self = [super init];
    if (self) {
        self.filesDeleted = 0;
        self.bytesFreed = 0;
        self.lastCleaningDate = [NSDate date];
        self.cleaningDuration = 0.0;
    }
    return self;
}

@end

// 增强版悬浮窗实现
@implementation EnhancedFloatingWindow

- (instancetype)init {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect windowFrame = CGRectMake(screenBounds.size.width - 60, 100, 40, 40);

    // 为iOS 13+设置窗口场景
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = nil;
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                windowScene = scene;
                break;
            }
        }
        if (windowScene) {
            self = [super initWithWindowScene:windowScene];
        } else {
            self = [super initWithFrame:windowFrame];
        }
    } else {
        self = [super initWithFrame:windowFrame];
    }
    
    if (self) {
        self.frame = windowFrame;
        self.windowLevel = UIWindowLevelAlert + 100;
        self.backgroundColor = [UIColor clearColor];
        self.hidden = NO;

        self.layer.cornerRadius = 20;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.userInteractionEnabled = YES;

        // 创建显示"冬"字的标签
        self.winterLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.winterLabel.text = @"白";
        self.winterLabel.textAlignment = NSTextAlignmentCenter;
        self.winterLabel.textColor = [UIColor whiteColor];
        self.winterLabel.font = [UIFont boldSystemFontOfSize:20];
        self.winterLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.9];
        self.winterLabel.layer.cornerRadius = 20;
        self.winterLabel.layer.masksToBounds = YES;
        [self addSubview:self.winterLabel];

        // 添加手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGesture];

        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];

        [self startPulseAnimation];
        DebugLog(@"增强版悬浮窗创建成功");
    }
    return self;
}

- (void)startPulseAnimation {
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.duration = 0.5;
    pulseAnimation.fromValue = @1.0;
    pulseAnimation.toValue = @1.2;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pulseAnimation.autoreverses = YES;
    pulseAnimation.repeatCount = 3;
    [self.layer addAnimation:pulseAnimation forKey:@"pulse"];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    DebugLog(@"增强版悬浮窗被点击，显示清理选项");
    [self showCleaningOptions];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self];
}

// 获取主窗口的辅助方法 - 修复 iOS 13+ 兼容性
- (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 使用 connectedScenes API
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *windowScene in connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                // 如果没有找到 keyWindow，返回该场景的第一个窗口
                if (windowScene.windows.count > 0) {
                    return windowScene.windows.firstObject;
                }
            }
        }
        // 备用：返回任意可见窗口
        for (UIWindowScene *windowScene in connectedScenes) {
            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0) {
                    return window;
                }
            }
        }
    } 
    
    // iOS 13 以下使用旧方法
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
}

// 查找合适的视图控制器来显示弹窗
- (UIViewController *)findPresentingViewController {
    // 方法1：尝试获取主窗口的根视图控制器
    UIWindow *keyWindow = [self getKeyWindow];
    if (keyWindow && keyWindow.rootViewController) {
        UIViewController *rootVC = keyWindow.rootViewController;
        UIViewController *presentedVC = [self findTopViewController:rootVC];
        if (presentedVC) {
            DebugLog(@"找到合适的视图控制器: %@", NSStringFromClass([presentedVC class]));
            return presentedVC;
        }
    }
    
    // 方法2：遍历所有窗口寻找合适的视图控制器
    if (@available(iOS 13.0, *)) {
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *windowScene in connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.rootViewController && window != self) {
                        UIViewController *topVC = [self findTopViewController:window.rootViewController];
                        if (topVC) {
                            DebugLog(@"从窗口场景找到视图控制器: %@", NSStringFromClass([topVC class]));
                            return topVC;
                        }
                    }
                }
            }
        }
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSArray *windows = [UIApplication sharedApplication].windows;
        #pragma clang diagnostic pop
        for (UIWindow *window in windows) {
            if (window.rootViewController && window != self) {
                UIViewController *topVC = [self findTopViewController:window.rootViewController];
                if (topVC) {
                    DebugLog(@"从应用窗口找到视图控制器: %@", NSStringFromClass([topVC class]));
                    return topVC;
                }
            }
        }
    }
    
    DebugLog(@"无法找到合适的视图控制器");
    return nil;
}

// 递归查找最顶层的视图控制器
- (UIViewController *)findTopViewController:(UIViewController *)baseViewController {
    if (!baseViewController) {
        return nil;
    }
    
    if (baseViewController.presentedViewController) {
        return [self findTopViewController:baseViewController.presentedViewController];
    }
    
    if ([baseViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)baseViewController;
        return [self findTopViewController:navController.visibleViewController];
    }
    
    if ([baseViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)baseViewController;
        return [self findTopViewController:tabController.selectedViewController];
    }
    
    return baseViewController;
}

// 显示清理选项菜单
- (void)showCleaningOptions {
    DebugLog(@"开始显示清理选项菜单");
    
    UIViewController *presentingVC = [self findPresentingViewController];
    if (!presentingVC) {
        DebugLog(@"无法找到合适的视图控制器，直接执行完全清理");
        [self showConfirmationDialog];
        return;
    }
    
    UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"AppCleaner - 数据清理"
                                                                          message:@"请选择清理类型"
                                                                   preferredStyle:UIAlertControllerStyleActionSheet];
    
    [optionsAlert addAction:[UIAlertAction actionWithTitle:@"🗂 仅清理缓存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        DebugLog(@"用户选择仅清理缓存");
        [self clearCacheOnly];
    }]];
    
    [optionsAlert addAction:[UIAlertAction actionWithTitle:@"👤 清理用户数据" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        DebugLog(@"用户选择清理用户数据");
        [self clearUserDataOnly];
    }]];
    
    [optionsAlert addAction:[UIAlertAction actionWithTitle:@"💥 完全清理" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        DebugLog(@"用户选择完全清理");
        [self showConfirmationDialog];
    }]];
    
    [optionsAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        DebugLog(@"用户取消操作");
    }]];
    
    // iPad适配
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        optionsAlert.popoverPresentationController.sourceView = presentingVC.view;
        optionsAlert.popoverPresentationController.sourceRect = CGRectMake(presentingVC.view.bounds.size.width/2, presentingVC.view.bounds.size.height/2, 1, 1);
        optionsAlert.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    DebugLog(@"准备显示清理选项弹窗");
    [presentingVC presentViewController:optionsAlert animated:YES completion:^{
        DebugLog(@"清理选项弹窗显示完成");
    }];
}

// 显示确认对话框
- (void)showConfirmationDialog {
    DebugLog(@"开始显示确认对话框");
    
    UIViewController *presentingVC = [self findPresentingViewController];
    if (!presentingVC) {
        DebugLog(@"无法找到合适的视图控制器，直接执行完全清理");
        [self performFullCleanWithAnimation];
        return;
    }
    
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"⚠️ 确认清除"
                                                                          message:@"此操作将永久删除应用所有数据，包括：\n• 用户设置和偏好\n• 缓存和临时文件\n• 登录信息和密码\n• 所有本地数据\n\n此操作不可逆，确定要继续吗？"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"确认清除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        DebugLog(@"用户确认执行完全清理");
        [self performFullCleanWithAnimation];
    }]];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        DebugLog(@"用户取消完全清理");
    }]];
    
    DebugLog(@"准备显示确认对话框");
    [presentingVC presentViewController:confirmAlert animated:YES completion:^{
        DebugLog(@"确认对话框显示完成");
    }];
}

// 显示进度指示器
- (void)showProgressIndicator {
    if (self.progressOverlay) {
        [self hideProgressIndicator];
    }
    
    self.progressOverlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.progressOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.progressOverlay.alpha = 0.0;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 120)];
    containerView.center = self.progressOverlay.center;
    containerView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    containerView.layer.cornerRadius = 15;
    containerView.layer.masksToBounds = YES;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 240, 25)];
    titleLabel.text = @"AppCleaner 正在清理...";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 50, 240, 4)];
    if (@available(iOS 13.0, *)) {
        self.progressView.progressTintColor = [UIColor systemBlueColor];
    } else {
        self.progressView.progressTintColor = [UIColor blueColor];
    }
    self.progressView.trackTintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.progressView.progress = 0.0;
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 240, 35)];
    self.statusLabel.text = @"正在初始化...";
    self.statusLabel.textColor = [UIColor lightGrayColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    
    [containerView addSubview:titleLabel];
    [containerView addSubview:self.progressView];
    [containerView addSubview:self.statusLabel];
    [self.progressOverlay addSubview:containerView];
    
    UIWindow *currentWindow = [self getKeyWindow];
    if (currentWindow) {
        [currentWindow addSubview:self.progressOverlay];
        [currentWindow bringSubviewToFront:self.progressOverlay];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.progressOverlay.alpha = 1.0;
        }];
    }
}

// 更新进度
- (void)updateProgress:(float)progress withStatus:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressView) {
            [UIView animateWithDuration:0.2 animations:^{
                self.progressView.progress = progress;
            }];
        }
        if (self.statusLabel && status) {
            self.statusLabel.text = status;
        }
    });
}

// 隐藏进度指示器
- (void)hideProgressIndicator {
    if (self.progressOverlay) {
        [UIView animateWithDuration:0.3 animations:^{
            self.progressOverlay.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.progressOverlay removeFromSuperview];
            self.progressOverlay = nil;
            self.progressView = nil;
            self.statusLabel = nil;
        }];
    }
}

// 显示清理结果
- (void)showCleaningResults:(CleaningStats *)stats {
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow || !keyWindow.rootViewController) {
        DebugLog(@"清理完成 - 删除文件：%lu 个，释放空间：%.2f MB，耗时：%.1f 秒",
                (unsigned long)stats.filesDeleted,
                stats.bytesFreed / (1024.0 * 1024.0),
                stats.cleaningDuration);
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"清理完成！\n\n📁 删除文件：%lu 个\n💾 释放空间：%.2f MB\n⏱ 耗时：%.1f 秒\n\n应用将在3秒后退出",
                        (unsigned long)stats.filesDeleted,
                        stats.bytesFreed / (1024.0 * 1024.0),
                        stats.cleaningDuration];
    
    UIAlertController *resultAlert = [UIAlertController alertControllerWithTitle:@"✅ 清理完成"
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
    [resultAlert addAction:[UIAlertAction actionWithTitle:@"立即退出" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    
    [keyWindow.rootViewController presentViewController:resultAlert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];
}

// 仅清理缓存
- (void)clearCacheOnly {
    [self showProgressIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CleaningStats *stats = [[CleaningStats alloc] init];
        NSDate *startTime = [NSDate date];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        [self updateProgress:0.1 withStatus:@"正在清理缓存目录..."];
        
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:cachesDirectory error:nil];
        
        [self updateProgress:0.3 withStatus:@"正在删除缓存文件..."];
        
        for (NSString *file in cacheFiles) {
            NSString *filePath = [cachesDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                stats.bytesFreed += [attributes fileSize];
                stats.filesDeleted++;
            }
            [fileManager removeItemAtPath:filePath error:nil];
        }
        
        [self updateProgress:0.6 withStatus:@"正在清理临时文件..."];
        
        NSString *tempDirectory = NSTemporaryDirectory();
        NSArray *tempFiles = [fileManager contentsOfDirectoryAtPath:tempDirectory error:nil];
        
        for (NSString *file in tempFiles) {
            NSString *filePath = [tempDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                stats.bytesFreed += [attributes fileSize];
                stats.filesDeleted++;
            }
            [fileManager removeItemAtPath:filePath error:nil];
        }
        
        [self updateProgress:0.9 withStatus:@"正在清理网络缓存..."];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
        [self updateProgress:1.0 withStatus:@"缓存清理完成！"];
        stats.cleaningDuration = [[NSDate date] timeIntervalSinceDate:startTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressIndicator];
            [self showCleaningResults:stats];
            
            // 延迟2秒后自动退出应用
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self exitApplication];
            });
        });
    });
}

// 仅清理用户数据
- (void)clearUserDataOnly {
    [self showProgressIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CleaningStats *stats = [[CleaningStats alloc] init];
        NSDate *startTime = [NSDate date];
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        [self updateProgress:0.1 withStatus:@"正在清理用户设置..."];
        
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self updateProgress:0.4 withStatus:@"正在清理用户文档..."];
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSArray *docFiles = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        for (NSString *file in docFiles) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                stats.bytesFreed += [attributes fileSize];
                stats.filesDeleted++;
            }
            [fileManager removeItemAtPath:filePath error:nil];
        }
        
        [self updateProgress:0.7 withStatus:@"正在清理应用偏好设置..."];
        
        NSString *preferencesPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Preferences"];
        NSArray *prefFiles = [fileManager contentsOfDirectoryAtPath:preferencesPath error:nil];
        
        for (NSString *file in prefFiles) {
            if ([file hasPrefix:bundleIdentifier] && [file hasSuffix:@".plist"]) {
                NSString *filePath = [preferencesPath stringByAppendingPathComponent:file];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
                if (attributes) {
                    stats.bytesFreed += [attributes fileSize];
                    stats.filesDeleted++;
                }
                [fileManager removeItemAtPath:filePath error:nil];
            }
        }
        
        [self updateProgress:1.0 withStatus:@"用户数据清理完成！"];
        stats.cleaningDuration = [[NSDate date] timeIntervalSinceDate:startTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressIndicator];
            [self showCleaningResults:stats];
            
            // 延迟2秒后自动退出应用
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self exitApplication];
            });
        });
    });
}

// 执行完全清理（带动画）
- (void)performFullCleanWithAnimation {
    [self showProgressIndicator];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformConcat(
                CGAffineTransformMakeScale(0.1, 0.1),
                CGAffineTransformMakeRotation(M_PI)
            );
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self clearAppDataWithProgress];
        }];
    }];
}

// 带进度的完全清理
- (void)clearAppDataWithProgress {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CleaningStats *stats = [[CleaningStats alloc] init];
        NSDate *startTime = [NSDate date];
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        [self updateProgress:0.05 withStatus:@"正在初始化清理..."];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        sync();
        
        [self updateProgress:0.1 withStatus:@"正在清理用户设置..."];
        
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self updateProgress:0.2 withStatus:@"正在清理文档目录..."];
        
        NSArray *directoriesToClean = @[
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject,
            NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject,
            NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject,
            NSTemporaryDirectory()
        ];
        
        float progressStep = 0.6 / directoriesToClean.count;
        float currentProgress = 0.2;
        
        for (NSString *directory in directoriesToClean) {
            NSString *dirName = [directory lastPathComponent];
            [self updateProgress:currentProgress withStatus:[NSString stringWithFormat:@"正在清理 %@ 目录...", dirName]];
            
            NSArray *files = [fileManager contentsOfDirectoryAtPath:directory error:nil];
            for (NSString *file in files) {
                NSString *filePath = [directory stringByAppendingPathComponent:file];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
                if (attributes) {
                    stats.bytesFreed += [attributes fileSize];
                    stats.filesDeleted++;
                }
                [fileManager removeItemAtPath:filePath error:nil];
            }
            
            currentProgress += progressStep;
        }
        
        [self updateProgress:0.8 withStatus:@"正在清理Keychain数据..."];
        ClearKeychainData(bundleIdentifier);
        
        [self updateProgress:0.9 withStatus:@"正在执行延迟清除..."];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSString *directory in directoriesToClean) {
                NSArray *files = [fileManager contentsOfDirectoryAtPath:directory error:nil];
                for (NSString *file in files) {
                    NSString *filePath = [directory stringByAppendingPathComponent:file];
                    [fileManager removeItemAtPath:filePath error:nil];
                }
            }
            
            [self updateProgress:1.0 withStatus:@"清理完成！"];
            stats.cleaningDuration = [[NSDate date] timeIntervalSinceDate:startTime];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressIndicator];
                [self showCleaningResults:stats];
                
                // 延迟2秒后自动退出应用
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self exitApplication];
                });
            });
        });
    });
}

// 退出应用方法
- (void)exitApplication {
    DebugLog(@"准备退出应用");
    
    // 隐藏悬浮窗
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        
        // 延迟0.5秒后退出应用
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            DebugLog(@"应用即将退出");
            exit(0);
        });
    }];
}

@end

// 全局变量
static EnhancedFloatingWindow *enhancedFloatingWindow = nil;

// 日志函数
void DebugLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"🔥AppCleaner: %@", message);
}

// Keychain清理函数
static void ClearKeychainData(NSString *bundleIdentifier) {
    DebugLog(@"开始清除Keychain数据");
    
    NSArray *keychainClasses = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];
    
    for (id keychainClass in keychainClasses) {
        NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
        [query setObject:keychainClass forKey:(__bridge id)kSecClass];
        
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecSuccess) {
            DebugLog(@"成功清除 %@ 类型的keychain数据", keychainClass);
        }
    }
}

// 创建增强版悬浮窗
static void CreateEnhancedFloatingWindow() {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    DebugLog(@"尝试创建增强版悬浮窗，应用: %@", bundleIdentifier);
    
    // 检查是否为系统应用，跳过系统应用
    if ([bundleIdentifier hasPrefix:@"com.apple."]) {
        DebugLog(@"跳过系统应用: %@", bundleIdentifier);
        return;
    }
    
    if (enhancedFloatingWindow) {
        DebugLog(@"增强版悬浮窗已存在，检查可见性");
        if (enhancedFloatingWindow.hidden) {
            enhancedFloatingWindow.hidden = NO;
            [enhancedFloatingWindow makeKeyAndVisible];
            DebugLog(@"重新显示已存在的悬浮窗");
        }
        return;
    }
    
    // 确保在主线程中创建
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CreateEnhancedFloatingWindow();
        });
        return;
    }
    
    @try {
        enhancedFloatingWindow = [[EnhancedFloatingWindow alloc] init];
        if (enhancedFloatingWindow) {
            // 设置更高的窗口级别确保显示在最前面
            enhancedFloatingWindow.windowLevel = UIWindowLevelAlert + 100;
            enhancedFloatingWindow.hidden = NO;
            [enhancedFloatingWindow makeKeyAndVisible];
            
            // 强制刷新显示
            [enhancedFloatingWindow setNeedsDisplay];
            [enhancedFloatingWindow layoutIfNeeded];
            
            DebugLog(@"增强版悬浮窗创建并显示成功，窗口级别: %.0f", enhancedFloatingWindow.windowLevel);
            
            // 验证窗口是否真的可见
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (enhancedFloatingWindow && !enhancedFloatingWindow.hidden) {
                    DebugLog(@"悬浮窗显示验证成功");
                } else {
                    DebugLog(@"悬浮窗显示验证失败，尝试重新显示");
                    if (enhancedFloatingWindow) {
                        enhancedFloatingWindow.hidden = NO;
                        [enhancedFloatingWindow makeKeyAndVisible];
                    }
                }
            });
        } else {
            DebugLog(@"悬浮窗创建失败");
        }
    } @catch (NSException *exception) {
        DebugLog(@"创建悬浮窗时发生异常: %@", exception.reason);
    }
}

// Hook应用启动
%hook UIApplication

- (BOOL)_didFinishLaunching {
    BOOL result = %orig;
    DebugLog(@"应用启动完成，准备创建增强版悬浮窗");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CreateEnhancedFloatingWindow();
    });
    
    return result;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    DebugLog(@"应用变为活跃状态");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!enhancedFloatingWindow) {
            DebugLog(@"应用活跃时创建悬浮窗");
            CreateEnhancedFloatingWindow();
        }
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    DebugLog(@"应用完成启动 (didFinishLaunchingWithOptions)");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CreateEnhancedFloatingWindow();
    });
    
    return result;
}

%end

// Hook UIWindow 来确保在窗口显示时创建悬浮窗
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DebugLog(@"主窗口显示，尝试创建悬浮窗");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CreateEnhancedFloatingWindow();
        });
    });
}

%end

// Hook UIViewController 来在视图控制器加载时创建悬浮窗
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DebugLog(@"视图控制器出现，尝试创建悬浮窗");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CreateEnhancedFloatingWindow();
        });
    });
}

%end

// 构造函数，在库加载时立即尝试创建悬浮窗
%ctor {
    DebugLog(@"AppCleaner库已加载");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DebugLog(@"构造函数延迟创建悬浮窗");
        CreateEnhancedFloatingWindow();
    });
}
