#import "NDFloatingView.h"
#import "NDManager.h"

@implementation NDFloatingView {
    UIButton *_btn;
}

// 获取 keyWindow，支持重试
+ (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;

    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
            if (keyWindow) break;
        }
    }

    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }

    return keyWindow;
}

+ (void)show {
    // 尝试获取 keyWindow，如果没有则延迟重试
    [self tryShowWithRetryCount:0];
}

+ (void)tryShowWithRetryCount:(int)count {
    if (count > 10) { // 最多重试10次，约5秒
        NSLog(@"[ND] 无法获取 keyWindow，放弃显示悬浮窗");
        return;
    }

    UIWindow *window = [self getKeyWindow];
    if (!window || window.rootViewController == nil) {
        // 延迟0.5秒后重试
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self tryShowWithRetryCount:count + 1];
        });
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NDFloatingView *view = [[NDFloatingView alloc] initWithFrame:CGRectMake(100, 200, 60, 60)];
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        view.layer.cornerRadius = 30;

        [window addSubview:view];
        NSLog(@"[ND] 悬浮窗已显示");
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
    // 执行清理（同步）
    [[NDManager shared] cleanSandbox];
    [[NDManager shared] cleanKeychain];
    [[NDManager shared] resetUserDefaults];

    NSLog(@"[ND] 一键新机完成，即将杀进程");

    // 延迟极短时间确保日志输出，然后强制退出
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        kill(getpid(), SIGKILL);
    });
}

@end