#import <UIKit/UIKit.h>

#pragma mark - 开关

static BOOL kVIP = YES;
static BOOL kCoin = YES;
static BOOL kStep = YES;

#pragma mark - Window

static UIWindow *KeyWindow() {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) return w;
    }
    return [UIApplication sharedApplication].keyWindow;
}

#pragma mark - 日志

@interface HLog : NSObject
@property(nonatomic,strong) UITextView *tv;
+ (instancetype)g;
- (void)log:(NSString *)s;
@end

@implementation HLog

+ (instancetype)g {
    static HLog *x;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        x = [HLog new];
    });
    return x;
}

- (void)log:(NSString *)s {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.tv) return;
        NSString *old = self.tv.text ?: @"";
        self.tv.text = [old stringByAppendingFormat:@"\n%@", s];
    });
}

@end

#pragma mark - 悬浮UI

@interface HView : UIView
@property(nonatomic,strong) UIView *panel;
@end

@implementation HView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100,200,60,60)];
    self.backgroundColor = [UIColor redColor];
    self.layer.cornerRadius = 30;

    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = self.bounds;
    [b setTitle:@"H" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:b];

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

    if (self.panel) {
        [self.panel removeFromSuperview];
        self.panel = nil;
        return;
    }

    UIWindow *w = KeyWindow();
    if (!w) return;

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(20,100,260,300)];
    self.panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];

    NSArray *arr = @[@"VIP", @"金币", @"步数"];

    for (int i = 0; i < arr.count; i++) {

        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(20, 20 + i*50, 200, 40);
        [b setTitle:arr[i] forState:UIControlStateNormal];
        b.tag = i;
        [b addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        [self.panel addSubview:b];
    }

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(10,180,240,100)];
    tv.backgroundColor = [UIColor blackColor];
    tv.textColor = [UIColor greenColor];
    tv.font = [UIFont systemFontOfSize:10];
    [self.panel addSubview:tv];

    [HLog g].tv = tv;

    [w addSubview:self.panel];
}

- (void)toggle:(UIButton *)b {

    if (b.tag == 0) kVIP = !kVIP;
    if (b.tag == 1) kCoin = !kCoin;
    if (b.tag == 2) kStep = !kStep;

    [[HLog g] log:[NSString stringWithFormat:@"切换:%ld",(long)b.tag]];
}

@end

#pragma mark - 万能字段Hook

%hook NSDictionary

- (id)objectForKey:(id)key {

    id val = %orig;

    if (![key isKindOfClass:[NSString class]]) return val;

    NSString *k = [(NSString *)key lowercaseString];

    if (kVIP && [k containsString:@"vip"]) {
        [[HLog g] log:@"VIP"];
        return @(1);
    }

    if (kCoin && ([k containsString:@"coin"] || [k containsString:@"gold"])) {
        [[HLog g] log:@"金币"];
        return @(999999);
    }

    if (kStep && [k containsString:@"step"]) {
        [[HLog g] log:@"步数"];
        return @(999);
    }

    return val;
}

%end

#pragma mark - 网络日志（稳定写法）

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    [[HLog g] log:request.URL.absoluteString];

    NSURLSessionDataTask *task =
    %orig(request, completionHandler);

    return task;
}

%end

#pragma mark - 注入入口

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        UIWindow *w = KeyWindow();
        if (!w) return;

        HView *v = [[HView alloc] init];
        [w addSubview:v];

        [[HLog g] log:@"加载成功"];
    });
}

%end