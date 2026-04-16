#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Security/Security.h>
#import <os/log.h>
#import <objc/runtime.h>

// 函数声明
void DebugLog(NSString *format, ...);
static void CreateEnhancedFloatingWindow(void);
static NSDictionary *ClearKeychainData(NSString *bundleIdentifier);  // 改为返回清除结果

// 清理统计信息类
@interface CleaningStats : NSObject
@property (nonatomic, assign) NSUInteger filesDeleted;
@property (nonatomic, assign) long long bytesFreed;
@property (nonatomic, strong) NSDate *lastCleaningDate;
@property (nonatomic, assign) NSTimeInterval cleaningDuration;
@property (nonatomic, strong) NSMutableArray<NSString *> *deletedFilesLog;
@property (nonatomic, strong) NSMutableArray<NSString *> *deletedDirectoriesLog;
@property (nonatomic, strong) NSMutableArray<NSString *> *keychainLog;  // 新增：Keychain清理日志
@end

// 增强版悬浮窗类
@interface EnhancedFloatingWindow : UIWindow
@property (nonatomic, strong) UILabel *winterLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *progressOverlay;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;

- (void)showCleaningOptions;
- (void)showConfirmationDialog;
- (void)showProgressIndicator;
- (void)updateProgress:(float)progress withStatus:(NSString *)status;
- (void)hideProgressIndicator;
- (void)showCleaningResults:(CleaningStats *)stats;
- (void)showDetailedLog:(CleaningStats *)stats;
- (void)clearCacheOnly;
- (void)clearUserDataOnly;
- (void)performFullCleanWithAnimation;
- (void)clearAppDataWithProgress;
- (void)exitApplication;
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
        self.deletedFilesLog = [NSMutableArray array];
        self.deletedDirectoriesLog = [NSMutableArray array];
        self.keychainLog = [NSMutableArray array];
    }
    return self;
}

- (NSString *)generateDetailedLog {
    NSMutableString *log = [NSMutableString string];
    
    [log appendString:@"╔═══════════════════════════════════════════════════════════╗\n"];
    [log appendString:@"║                    📋 详细清理日志                        ║\n"];
    [log appendString:@"╚═══════════════════════════════════════════════════════════╝\n\n"];
    
    [log appendFormat:@"📅 清理时间: %@\n", self.lastCleaningDate];
    [log appendFormat:@"⏱ 耗时: %.2f 秒\n", self.cleaningDuration];
    [log appendFormat:@"📁 删除文件总数: %lu 个\n", (unsigned long)self.filesDeleted];
    [log appendFormat:@"💾 释放空间总计: %.2f MB (%.2f KB)\n\n", 
     self.bytesFreed / (1024.0 * 1024.0),
     self.bytesFreed / 1024.0];
    
    if (self.deletedDirectoriesLog.count > 0) {
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        [log appendString:@"🗂 清理的目录:\n"];
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        for (NSString *dir in self.deletedDirectoriesLog) {
            [log appendFormat:@"  • %@\n", dir];
        }
        [log appendString:@"\n"];
    }
    
    if (self.keychainLog.count > 0) {
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        [log appendString:@"🔐 Keychain 清理详情:\n"];
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        for (NSString *keychainEntry in self.keychainLog) {
            [log appendFormat:@"  %@\n", keychainEntry];
        }
        [log appendString:@"\n"];
    }
    
    if (self.deletedFilesLog.count > 0) {
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        [log appendFormat:@"📄 删除的文件 (共 %lu 个):\n", (unsigned long)self.deletedFilesLog.count];
        [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
        
        NSUInteger maxDisplay = MIN(self.deletedFilesLog.count, 100);
        for (NSUInteger i = 0; i < maxDisplay; i++) {
            [log appendFormat:@"  %lu. %@\n", (unsigned long)(i + 1), self.deletedFilesLog[i]];
        }
        
        if (self.deletedFilesLog.count > 100) {
            [log appendFormat:@"\n  ... 还有 %lu 个文件未显示\n", 
             (unsigned long)(self.deletedFilesLog.count - 100)];
        }
        [log appendString:@"\n"];
    }
    
    [log appendString:@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"];
    [log appendString:@"✅ 清理完成！\n"];
    
    return log;
}

@end

// 增强版悬浮窗实现
@implementation EnhancedFloatingWindow

- (instancetype)init {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect windowFrame = CGRectMake(screenBounds.size.width - 60, 100, 40, 40);

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

        self.winterLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.winterLabel.text = @"冬";
        self.winterLabel.textAlignment = NSTextAlignmentCenter;
        self.winterLabel.textColor = [UIColor whiteColor];
        self.winterLabel.font = [UIFont boldSystemFontOfSize:20];
        self.winterLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.9];
        self.winterLabel.layer.cornerRadius = 20;
        self.winterLabel.layer.masksToBounds = YES;
        [self addSubview:self.winterLabel];

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

- (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *windowScene in connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                if (windowScene.windows.count > 0) {
                    return windowScene.windows.firstObject;
                }
            }
        }
        for (UIWindowScene *windowScene in connectedScenes) {
            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0) {
                    return window;
                }
            }
        }
    } 
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
}

- (UIViewController *)findPresentingViewController {
    UIWindow *keyWindow = [self getKeyWindow];
    if (keyWindow && keyWindow.rootViewController) {
        UIViewController *rootVC = keyWindow.rootViewController;
        UIViewController *presentedVC = [self findTopViewController:rootVC];
        if (presentedVC) {
            DebugLog(@"找到合适的视图控制器: %@", NSStringFromClass([presentedVC class]));
            return presentedVC;
        }
    }
    
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

- (void)showProgressIndicator {
    if (self.progressOverlay) {
        [self hideProgressIndicator];
    }
    
    self.progressOverlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.progressOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.progressOverlay.alpha = 0.0;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 150)];
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

- (void)showCleaningResults:(CleaningStats *)stats {
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow || !keyWindow.rootViewController) {
        DebugLog(@"清理完成 - 删除文件：%lu 个，释放空间：%.2f MB，耗时：%.1f 秒",
                (unsigned long)stats.filesDeleted,
                stats.bytesFreed / (1024.0 * 1024.0),
                stats.cleaningDuration);
        [self showDetailedLog:stats];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"清理完成！\n\n📁 删除文件：%lu 个\n💾 释放空间：%.2f MB\n🔐 Keychain条目：%lu 个\n⏱ 耗时：%.1f 秒",
                        (unsigned long)stats.filesDeleted,
                        stats.bytesFreed / (1024.0 * 1024.0),
                        (unsigned long)stats.keychainLog.count,
                        stats.cleaningDuration];
    
    UIAlertController *resultAlert = [UIAlertController alertControllerWithTitle:@"✅ 清理完成"
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
    [resultAlert addAction:[UIAlertAction actionWithTitle:@"📋 查看详细日志" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showDetailedLog:stats];
    }]];
    
    [resultAlert addAction:[UIAlertAction actionWithTitle:@"立即退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    
    [keyWindow.rootViewController presentViewController:resultAlert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];
}

- (void)showDetailedLog:(CleaningStats *)stats {
    UIViewController *presentingVC = [self findPresentingViewController];
    if (!presentingVC) {
        DebugLog(@"无法显示详细日志：没有视图控制器");
        return;
    }
    
    NSString *detailedLog = [stats generateDetailedLog];
    
    UIViewController *logVC = [[UIViewController alloc] init];
    logVC.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    logVC.title = @"清理详细日志";
    
    UITextView *textView = [[UITextView alloc] initWithFrame:logVC.view.bounds];
    textView.text = detailedLog;
    textView.font = [UIFont fontWithName:@"Courier" size:12];
    textView.editable = NO;
    textView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [logVC.view addSubview:textView];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:logVC];
    
    logVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                           target:self 
                                                                                           action:@selector(dismissLogVC:)];
    logVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"分享" 
                                                                              style:UIBarButtonItemStylePlain 
                                                                             target:self 
                                                                             action:@selector(shareLog:)];
    
    objc_setAssociatedObject(logVC, "cleaningStats", stats, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [presentingVC presentViewController:navController animated:YES completion:nil];
}

- (void)dismissLogVC:(id)sender {
    UIViewController *presentingVC = [self findPresentingViewController];
    [presentingVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareLog:(id)sender {
    UIViewController *logVC = nil;
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UINavigationController *navController = (UINavigationController *)[self findPresentingViewController].presentedViewController;
        if ([navController isKindOfClass:[UINavigationController class]]) {
            logVC = navController.viewControllers.firstObject;
        }
    }
    
    if (logVC) {
        CleaningStats *stats = objc_getAssociatedObject(logVC, "cleaningStats");
        if (stats) {
            NSString *logContent = [stats generateDetailedLog];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[logContent] applicationActivities:nil];
            
            UIViewController *presentingVC = [self findPresentingViewController];
            if (presentingVC) {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    activityVC.popoverPresentationController.barButtonItem = (UIBarButtonItem *)sender;
                }
                [presentingVC presentViewController:activityVC animated:YES completion:nil];
            }
        }
    }
}

- (void)clearCacheOnly {
    [self showProgressIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CleaningStats *stats = [[CleaningStats alloc] init];
        NSDate *startTime = [NSDate date];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        [self updateProgress:0.1 withStatus:@"正在清理缓存目录..."];
        
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        [stats.deletedDirectoriesLog addObject:cachesDirectory];
        
        NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:cachesDirectory error:nil];
        
        [self updateProgress:0.3 withStatus:@"正在删除缓存文件..."];
        
        for (NSString *file in cacheFiles) {
            NSString *filePath = [cachesDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                long long fileSize = [attributes fileSize];
                stats.bytesFreed += fileSize;
                stats.filesDeleted++;
                [stats.deletedFilesLog addObject:[NSString stringWithFormat:@"[缓存] %@ (%.2f KB)", file, fileSize / 1024.0]];
                DebugLog(@"删除缓存文件: %@ (%.2f KB)", file, fileSize / 1024.0);
            }
            [fileManager removeItemAtPath:filePath error:nil];
        }
        
        [self updateProgress:0.6 withStatus:@"正在清理临时文件..."];
        
        NSString *tempDirectory = NSTemporaryDirectory();
        [stats.deletedDirectoriesLog addObject:tempDirectory];
        
        NSArray *tempFiles = [fileManager contentsOfDirectoryAtPath:tempDirectory error:nil];
        
        for (NSString *file in tempFiles) {
            NSString *filePath = [tempDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                long long fileSize = [attributes fileSize];
                stats.bytesFreed += fileSize;
                stats.filesDeleted++;
                [stats.deletedFilesLog addObject:[NSString stringWithFormat:@"[临时] %@ (%.2f KB)", file, fileSize / 1024.0]];
                DebugLog(@"删除临时文件: %@ (%.2f KB)", file, fileSize / 1024.0);
            }
            [fileManager removeItemAtPath:filePath error:nil];
        }
        
        [self updateProgress:0.9 withStatus:@"正在清理网络缓存..."];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [stats.deletedFilesLog addObject:@"[网络] 清除所有URLCache"];
        
        [self updateProgress:1.0 withStatus:@"缓存清理完成！"];
        stats.cleaningDuration = [[NSDate date] timeIntervalSinceDate:startTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressIndicator];
            [self showCleaningResults:stats];
        });
    });
}

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
        [stats.deletedFilesLog addObject:@"[设置] 清除 NSUserDefaults"];
        
        [self updateProgress:0.4 withStatus:@"正在清理用户文档..."];
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        [stats.deletedDirectoriesLog addObject:documentsDirectory];
        
        NSArray *docFiles = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        for (NSString *file in docFiles) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                long long fileSize = [attributes fileSize];
                stats.bytesFreed += fileSize;
                stats.filesDeleted++;
                [stats.deletedFilesLog addObject:[NSString stringWithFormat:@"[文档] %@ (%.2f KB)", file, fileSize / 1024.0]];
                DebugLog(@"删除文档: %@ (%.2f KB)", file, fileSize / 1024.0);
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
                    long long fileSize = [attributes fileSize];
                    stats.bytesFreed += fileSize;
                    stats.filesDeleted++;
                    [stats.deletedFilesLog addObject:[NSString stringWithFormat:@"[偏好] %@ (%.2f KB)", file, fileSize / 1024.0]];
                    DebugLog(@"删除偏好文件: %@ (%.2f KB)", file, fileSize / 1024.0);
                }
                [fileManager removeItemAtPath:filePath error:nil];
            }
        }
        
        [self updateProgress:1.0 withStatus:@"用户数据清理完成！"];
        stats.cleaningDuration = [[NSDate date] timeIntervalSinceDate:startTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressIndicator];
            [self showCleaningResults:stats];
        });
    });
}

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
        [stats.deletedFilesLog addObject:@"[设置] 清除 NSUserDefaults"];
        
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
            
            [stats.deletedDirectoriesLog addObject:directory];
            
            NSArray *files = [fileManager contentsOfDirectoryAtPath:directory error:nil];
            for (NSString *file in files) {
                NSString *filePath = [directory stringByAppendingPathComponent:file];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
                if (attributes) {
                    BOOL isDirectory = [[attributes fileType] isEqualToString:NSFileTypeDirectory];
                    long long fileSize = [attributes fileSize];
                    stats.bytesFreed += fileSize;
                    stats.filesDeleted++;
                    
                    NSString *fileType = isDirectory ? @"[目录]" : @"[文件]";
                    [stats.deletedFilesLog addObject:[NSString stringWithFormat:@"%@ %@/%@ (%.2f KB)", 
                                                      fileType, dirName, file, fileSize / 1024.0]];
                    DebugLog(@"删除: %@/%@ (%.2f KB)", dirName, file, fileSize / 1024.0);
                }
                [fileManager removeItemAtPath:filePath error:nil];
            }
            
            currentProgress += progressStep;
        }
        
        [self updateProgress:0.8 withStatus:@"正在清理Keychain数据..."];
        
        // 调用增强的 Keychain 清理函数，传入 stats 对象记录日志
        [self clearKeychainDataWithStats:stats bundleIdentifier:bundleIdentifier];
        
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
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self exitApplication];
                });
            });
        });
    });
}

// 新增：带日志记录的 Keychain 清理函数
- (void)clearKeychainDataWithStats:(CleaningStats *)stats bundleIdentifier:(NSString *)bundleIdentifier {
    DebugLog(@"开始清除Keychain数据");
    [stats.keychainLog addObject:@"========== Keychain 清理开始 =========="];
    [stats.keychainLog addObject:[NSString stringWithFormat:@"应用 Bundle ID: %@", bundleIdentifier]];
    
    // 定义 Keychain 类别及其显示名称
    NSArray *keychainClasses = @[
        @{@"class": (__bridge id)kSecClassGenericPassword, @"name": @"通用密码 (GenericPassword)"},
        @{@"class": (__bridge id)kSecClassInternetPassword, @"name": @"互联网密码 (InternetPassword)"},
        @{@"class": (__bridge id)kSecClassCertificate, @"name": @"证书 (Certificate)"},
        @{@"class": (__bridge id)kSecClassKey, @"name": @"密钥 (Key)"},
        @{@"class": (__bridge id)kSecClassIdentity, @"name": @"身份 (Identity)"}
    ];
    
    NSUInteger totalDeletedCount = 0;
    
    for (NSDictionary *classInfo in keychainClasses) {
        id keychainClass = classInfo[@"class"];
        NSString *className = classInfo[@"name"];
        
        // 查询该类别下有多少条目（仅针对当前应用）
        NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
        [query setObject:keychainClass forKey:(__bridge id)kSecClass];
        [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
        [query setObject:@YES forKey:(__bridge id)kSecReturnAttributes];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        
        // 尝试获取现有条目
        CFTypeRef result = NULL;
        OSStatus queryStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        
        if (queryStatus == errSecSuccess && result) {
            NSArray *items = (__bridge_transfer NSArray *)result;
            NSUInteger itemCount = items.count;
            
            if (itemCount > 0) {
                [stats.keychainLog addObject:[NSString stringWithFormat:@"\n📂 %@ 类别发现 %lu 个条目:", className, (unsigned long)itemCount]];
                
                // 记录每个条目的详细信息
                for (NSDictionary *item in items) {
                    NSString *itemDescription = [self describeKeychainItem:item];
                    [stats.keychainLog addObject:[NSString stringWithFormat:@"    • %@", itemDescription]];
                }
                
                // 执行删除
                NSMutableDictionary *deleteQuery = [[NSMutableDictionary alloc] init];
                [deleteQuery setObject:keychainClass forKey:(__bridge id)kSecClass];
                OSStatus deleteStatus = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
                
                if (deleteStatus == errSecSuccess) {
                    [stats.keychainLog addObject:[NSString stringWithFormat:@"    ✅ 成功删除 %lu 个 %@ 条目", (unsigned long)itemCount, className]];
                    totalDeletedCount += itemCount;
                } else {
                    [stats.keychainLog addObject:[NSString stringWithFormat:@"    ❌ 删除失败，错误码: %d", (int)deleteStatus]];
                }
            } else {
                [stats.keychainLog addObject:[NSString stringWithFormat:@"📂 %@: 无条目", className]];
            }
        } else if (queryStatus == errSecItemNotFound) {
            [stats.keychainLog addObject:[NSString stringWithFormat:@"📂 %@: 无条目", className]];
        } else {
            [stats.keychainLog addObject:[NSString stringWithFormat:@"⚠️ %@: 查询失败，错误码: %d", className, (int)queryStatus]];
        }
    }
    
    // 额外清理：针对当前应用 Bundle ID 的特定 Keychain 条目（更精确的清理）
    [stats.keychainLog addObject:@"\n========== 精确匹配清理 =========="];
    
    NSArray *servicePatterns = @[
        bundleIdentifier,
        [NSString stringWithFormat:@"%@.", bundleIdentifier],
        [NSString stringWithFormat:@"%@_", bundleIdentifier]
    ];
    
    for (NSString *pattern in servicePatterns) {
        NSMutableDictionary *specificQuery = [[NSMutableDictionary alloc] init];
        [specificQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [specificQuery setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
        [specificQuery setObject:@YES forKey:(__bridge id)kSecReturnAttributes];
        
        // 尝试匹配服务名
        [specificQuery setObject:pattern forKey:(__bridge id)kSecAttrService];
        
        CFTypeRef specificResult = NULL;
        OSStatus specificStatus = SecItemCopyMatching((__bridge CFDictionaryRef)specificQuery, &specificResult);
        
        if (specificStatus == errSecSuccess && specificResult) {
            NSArray *items = (__bridge_transfer NSArray *)specificResult;
            if (items.count > 0) {
                [stats.keychainLog addObject:[NSString stringWithFormat:@"🔍 匹配模式 '%@' 找到 %lu 个条目:", pattern, (unsigned long)items.count]];
                
                for (NSDictionary *item in items) {
                    NSString *account = [item objectForKey:(__bridge id)kSecAttrAccount] ?: @"未知";
                    [stats.keychainLog addObject:[NSString stringWithFormat:@"    • 账户: %@", account]];
                }
                
                // 删除这些条目
                NSMutableDictionary *deleteSpecificQuery = [[NSMutableDictionary alloc] init];
                [deleteSpecificQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                [deleteSpecificQuery setObject:pattern forKey:(__bridge id)kSecAttrService];
                OSStatus deleteSpecificStatus = SecItemDelete((__bridge CFDictionaryRef)deleteSpecificQuery);
                
                if (deleteSpecificStatus == errSecSuccess) {
                    [stats.keychainLog addObject:[NSString stringWithFormat:@"    ✅ 成功删除匹配 '%@' 的条目", pattern]];
                }
            }
        }
    }
    
    [stats.keychainLog addObject:[NSString stringWithFormat:@"\n========== Keychain 清理完成 =========="]];
    [stats.keychainLog addObject:[NSString stringWithFormat:@"总计删除 Keychain 条目: %lu 个", (unsigned long)totalDeletedCount]];
    
    DebugLog(@"Keychain清理完成，共删除 %lu 个条目", (unsigned long)totalDeletedCount);
}

// 辅助方法：描述 Keychain 条目
- (NSString *)describeKeychainItem:(NSDictionary *)item {
    NSMutableString *description = [NSMutableString string];
    
    NSString *account = [item objectForKey:(__bridge id)kSecAttrAccount];
    NSString *service = [item objectForKey:(__bridge id)kSecAttrService];
    NSString *server = [item objectForKey:(__bridge id)kSecAttrServer];
    NSNumber *port = [item objectForKey:(__bridge id)kSecAttrPort];
    NSString *protocol = [item objectForKey:(__bridge id)kSecAttrProtocol];
    
    if (account) {
        [description appendFormat:@"账户: %@", account];
    }
    if (service) {
        if (description.length > 0) [description appendString:@", "];
        [description appendFormat:@"服务: %@", service];
    }
    if (server) {
        if (description.length > 0) [description appendString:@", "];
        [description appendFormat:@"服务器: %@", server];
    }
    if (port) {
        if (description.length > 0) [description appendString:@", "];
        [description appendFormat:@"端口: %@", port];
    }
    if (protocol) {
        if (description.length > 0) [description appendString:@", "];
        [description appendFormat:@"协议: %@", protocol];
    }
    
    if (description.length == 0) {
        [description appendString:@"(无详细信息)"];
    }
    
    return description;
}

- (void)exitApplication {
    DebugLog(@"准备退出应用");
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        
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

// 创建增强版悬浮窗
static void CreateEnhancedFloatingWindow() {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    DebugLog(@"尝试创建增强版悬浮窗，应用: %@", bundleIdentifier);
    
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
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CreateEnhancedFloatingWindow();
        });
        return;
    }
    
    @try {
        enhancedFloatingWindow = [[EnhancedFloatingWindow alloc] init];
        if (enhancedFloatingWindow) {
            enhancedFloatingWindow.windowLevel = UIWindowLevelAlert + 100;
            enhancedFloatingWindow.hidden = NO;
            [enhancedFloatingWindow makeKeyAndVisible];
            
            [enhancedFloatingWindow setNeedsDisplay];
            [enhancedFloatingWindow layoutIfNeeded];
            
            DebugLog(@"增强版悬浮窗创建并显示成功，窗口级别: %.0f", enhancedFloatingWindow.windowLevel);
            
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

// Hook UIWindow
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

// Hook UIViewController
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

// 构造函数
%ctor {
    DebugLog(@"AppCleaner库已加载");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DebugLog(@"构造函数延迟创建悬浮窗");
        CreateEnhancedFloatingWindow();
    });
}