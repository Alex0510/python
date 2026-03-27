#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL kEnableStep = YES;
static BOOL kEnableScore = YES;
static BOOL kEnableItem = YES;
static BOOL kEnableVIP = YES;

#pragma mark - 自动识别关键字段

BOOL isTargetKey(NSString *key) {
    NSArray *keys = @[
        @"score", @"coin", @"gold",
        @"step", @"energy",
        @"vip", @"member", @"pro"
    ];

    for (NSString *k in keys) {
        if ([[key lowercaseString] containsString:k]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Hook NSDictionary（万能入口）

%hook NSDictionary

- (id)objectForKey:(id)key {

    id value = %orig;

    if (![key isKindOfClass:[NSString class]]) return value;

    NSString *k = [(NSString *)key lowercaseString];

    if (isTargetKey(k)) {

        if ([k containsString:@"vip"] && kEnableVIP) {
            return @(1);
        }

        if (([k containsString:@"coin"] || [k containsString:@"gold"]) && kEnableScore) {
            return @(999999);
        }

        if ([k containsString:@"step"] && kEnableStep) {
            return @(999);
        }
    }

    return value;
}

%end

#pragma mark - 越狱检测绕过

%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {

    if ([path containsString:@"Cydia"] ||
        [path containsString:@"Substrate"] ||
        [path containsString:@"apt"]) {
        return NO;
    }

    return %orig;
}

%end

#pragma mark - getenv 防检测

%hook NSProcessInfo

- (NSDictionary *)environment {
    return @{};
}

%end

#pragma mark - UI 悬浮窗

@interface HackView : UIView
@end

@implementation HackView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 200, 60, 60)];

    self.backgroundColor = [UIColor redColor];
    self.layer.cornerRadius = 30;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = self.bounds;
    [btn setTitle:@"Hack" forState:UIControlStateNormal];

    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];

    UIPanGestureRecognizer *pan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];

    return self;
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint p = [g translationInView:self];
    self.center = CGPointMake(self.center.x + p.x, self.center.y + p.y);
    [g setTranslation:CGPointZero inView:self];
}

- (void)click {

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"外挂菜单"
                                        message:nil
                                 preferredStyle:1];

    [alert addAction:[UIAlertAction actionWithTitle:@"无限步数"
                                             style:0
                                           handler:^(id a){
        kEnableStep = !kEnableStep;
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"分数增强"
                                             style:0
                                           handler:^(id a){
        kEnableScore = !kEnableScore;
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"道具无限"
                                             style:0
                                           handler:^(id a){
        kEnableItem = !kEnableItem;
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"VIP解锁"
                                             style:0
                                           handler:^(id a){
        kEnableVIP = !kEnableVIP;
    }]];

    [[UIApplication sharedApplication].keyWindow.rootViewController
     presentViewController:alert animated:YES completion:nil];
}

@end

#pragma mark - 注入

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{

        UIWindow *window = [UIApplication sharedApplication].keyWindow;

        HackView *v = [[HackView alloc] init];
        [window addSubview:v];
    });
}

%end