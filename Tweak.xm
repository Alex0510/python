#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 全局开关

static BOOL kEnableStep = YES;
static BOOL kEnableScore = YES;
static BOOL kEnableVIP = YES;

#pragma mark - Window 获取

UIWindow *getKeyWindow() {
    UIWindow *window = nil;

    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }

    return window;
}

#pragma mark - Logger

@interface HackLogger : NSObject
@property (nonatomic, strong) UITextView *textView;
+ (instancetype)shared;
- (void)log:(NSString *)msg;
@end

@implementation HackLogger

+ (instancetype)shared {
    static HackLogger *l;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        l = [HackLogger new];
    });
    return l;
}

- (void)log:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *old = self.textView.text ?: @"";
        NSString *newStr = [old stringByAppendingFormat:@"\n%@", msg];
        self.textView.text = newStr;

        NSRange range = NSMakeRange(newStr.length - 1, 1);
        [self.textView scrollRangeToVisible:range];
    });
}

@end

#pragma mark - UI

@interface HackView : UIView
@property (nonatomic, strong) UIView *panel;
@end

@implementation HackView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 200, 60, 60)];

    self.backgroundColor = [UIColor redColor];
    self.layer.cornerRadius = 30;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = self.bounds;
    [btn setTitle:@"H" forState:UIControlStateNormal];

    [btn addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
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

- (void)togglePanel {

    if (self.panel) {
        [self.panel removeFromSuperview];
        self.panel = nil;
        return;
    }

    UIWindow *window = getKeyWindow();
    if (!window) return;

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(20, 100, 300, 400)];
    self.panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    self.panel.layer.cornerRadius = 10;

    NSArray *titles = @[@"无限步数", @"分数增强", @"VIP解锁"];

    for (int i = 0; i < titles.count; i++) {

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, 20 + i * 50, 200, 40);
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        btn.tag = i;

        [btn addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        [self.panel addSubview:btn];
    }

    UITextView *logView = [[UITextView alloc] initWithFrame:CGRectMake(10, 180, 280, 200)];
    logView.backgroundColor = [UIColor blackColor];
    logView.textColor = [UIColor greenColor];
    logView.font = [UIFont systemFontOfSize:10];

    [self.panel addSubview:logView];

    [HackLogger shared].textView = logView;

    [window addSubview:self.panel];
}

- (void)toggle:(UIButton *)btn {

    if (btn.tag == 0) kEnableStep = !kEnableStep;
    if (btn.tag == 1) kEnableScore = !kEnableScore;
    if (btn.tag == 2) kEnableVIP = !kEnableVIP;

    [[HackLogger shared] log:[NSString stringWithFormat:@"切换开关: %d", (int)btn.tag]];
}

@end

#pragma mark - Hook NSDictionary

%hook NSDictionary

- (id)objectForKey:(id)key {

    id value = %orig;

    if (![key isKindOfClass:[NSString class]]) return value;

    NSString *k = [(NSString *)key lowercaseString];

    if ([k containsString:@"vip"] && kEnableVIP) {
        [[HackLogger shared] log:@"VIP 命中"];
        return @(1);
    }

    if (([k containsString:@"coin"] || [k containsString:@"gold"]) && kEnableScore) {
        [[HackLogger shared] log:@"金币命中"];
        return @(999999);
    }

    if ([k containsString:@"step"] && kEnableStep) {
        [[HackLogger shared] log:@"步数命中"];
        return @(999);
    }

    return value;
}

%end

#pragma mark - 网络日志

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    [[HackLogger shared] log:[NSString stringWithFormat:@"URL: %@", request.URL.absoluteString]];

    return %orig(request, ^(NSData *data, NSURLResponse *res, NSError *err) {

        if (data) {
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (str.length < 200) {
                [[HackLogger shared] log:str];
            }
        }

        completionHandler(data, res, err);
    });
}

%end

#pragma mark - 注入入口

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{

        UIWindow *window = getKeyWindow();
        if (!window) return;

        HackView *v = [[HackView alloc] init];
        [window addSubview:v];

        [[HackLogger shared] log:@"插件加载成功"];
    });
}

%end