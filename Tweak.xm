// Tweak.xm

#import <UIKit/UIKit.h>

static UIWindow *floatingWindow = nil;

static void showAlert(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (!rootVC) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

static void enableInfiniteResources() {
    // 仅显示提示，不做任何实际修改，确保不崩溃
    showAlert(@"功能开发中，请等待后续更新");
}

%hook AppController

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL ret = %orig;
    
    // 延迟创建悬浮窗
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (floatingWindow) return;
        
        CGFloat size = 50;
        CGFloat margin = 10;
        CGFloat x = [UIScreen mainScreen].bounds.size.width - size - margin;
        CGFloat y = 100;
        CGRect frame = CGRectMake(x, y, size, size);
        
        floatingWindow = [[UIWindow alloc] initWithFrame:frame];
        floatingWindow.windowLevel = UIWindowLevelAlert + 1;
        floatingWindow.backgroundColor = [UIColor clearColor];
        floatingWindow.hidden = NO;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, size, size);
        button.backgroundColor = [UIColor redColor];
        button.layer.cornerRadius = size / 2;
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOffset = CGSizeMake(2, 2);
        button.layer.shadowOpacity = 0.5;
        [button setTitle:@"🐦" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [floatingWindow addSubview:button];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [button addGestureRecognizer:pan];
    });
    
    return ret;
}

- (void)floatingButtonTapped:(UIButton *)sender {
    enableInfiniteResources();
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:gesture.view.superview];
        gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                          gesture.view.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:gesture.view.superview];
    }
}

%end

%ctor {
    // 可选初始化
}