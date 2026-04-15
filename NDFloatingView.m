#import "NDFloatingView.h"
#import "NDManager.h"

@implementation NDFloatingView {
    UIButton *_btn;
}

+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

        NDFloatingView *view = [[NDFloatingView alloc] initWithFrame:CGRectMake(100, 200, 60, 60)];
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        view.layer.cornerRadius = 30;

        [keyWindow addSubview:view];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    _btn = [UIButton buttonWithType:UIButtonTypeSystem];
    _btn.frame = self.bounds;
    [_btn setTitle:@"新机" forState:UIControlStateNormal];
    [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [_btn addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btn];

    // 拖动
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self addGestureRecognizer:pan];

    return self;
}

- (void)move:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self];
}

- (void)action {
    // 获取当前顶层视图控制器
    UIViewController *topVC = [self topMostViewController];
    if (!topVC) {
        // 降级方案：直接清理并退出
        [self performCleanupAndExit];
        return;
    }
    
    // 显示清理中弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清理中"
                                                                   message:@"正在执行一键新机，请稍候..."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [topVC presentViewController:alert animated:YES completion:nil];
    
    // 异步执行清理操作，避免阻塞 UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NDManager shared] cleanSandbox];
        [[NDManager shared] cleanKeychain];
        [[NDManager shared] resetUserDefaults];
        
        NSLog(@"[NewDevice] 一键新机完成");
        
        // 回到主线程更新弹窗并退出
        dispatch_async(dispatch_get_main_queue(), ^{
            alert.title = @"清理完成";
            alert.message = @"一键新机已完成，应用即将退出";
            
            // 延迟0.5秒，让用户看到提示后再退出
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
        });
    });
}

// 直接清理并退出（无弹窗的降级方案）
- (void)performCleanupAndExit {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NDManager shared] cleanSandbox];
        [[NDManager shared] cleanKeychain];
        [[NDManager shared] resetUserDefaults];
        NSLog(@"[NewDevice] 一键新机完成（无弹窗降级）");
        dispatch_async(dispatch_get_main_queue(), ^{
            exit(0);
        });
    });
}

#pragma mark - Helper: 获取当前最顶层的 ViewController

- (UIViewController *)topMostViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = keyWindow.rootViewController;
    return [self topMostViewControllerFrom:rootVC];
}

- (UIViewController *)topMostViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self topMostViewControllerFrom:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self topMostViewControllerFrom:[(UITabBarController *)vc selectedViewController]];
    } else if (vc.presentedViewController) {
        return [self topMostViewControllerFrom:vc.presentedViewController];
    } else {
        return vc;
    }
}

@end