#import "NDFloatingView.h"
#import "NDManager.h"

@implementation NDFloatingView {
    UIButton *_btn;
}

+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
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

    NSLog(@"[NewDevice] 开始一键新机");

    // 1. 清数据
    [[NDManager shared] cleanSandbox];
    [[NDManager shared] cleanKeychain];
    [[NDManager shared] resetUserDefaults];

    // 2. 生成新设备（如果你用了终极版 NDConfig）
    if ([NSClassFromString(@"NDConfig") respondsToSelector:@selector(shared)]) {
        id config = [NSClassFromString(@"NDConfig") performSelector:@selector(shared)];
        if ([config respondsToSelector:@selector(generateNewProfile)]) {
            [

@end
