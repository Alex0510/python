#import "NDFloatingView.h"
#import "NDManager.h"

@implementation NDFloatingView {
    UIButton *_btn;
}

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
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self getKeyWindow];

        NDFloatingView *view = [[NDFloatingView alloc] initWithFrame:CGRectMake(100, 200, 60, 60)];
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        view.layer.cornerRadius = 30;

        [window addSubview:view];
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

    [[NDManager shared] cleanSandbox];
    [[NDManager shared] cleanKeychain];
    [[NDManager shared] resetUserDefaults];

    NSLog(@"[ND] 一键新机完成");

    // 强制杀进程
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        kill(getpid(), SIGKILL);
    });
}

@end