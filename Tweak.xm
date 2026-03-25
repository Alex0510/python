#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - 全局

static BOOL kEnable = YES;
static NSMutableArray *gLogs;
static NSMutableArray *gRules;
static UIWindow *gWindow;
static UITextView *gTextView;
static UITextField *gInput;

#define kRulesKey @"URLBlockRules"

#pragma mark - 日志

static void addLog(NSString *log) {
    if (!gLogs) gLogs = [NSMutableArray array];

    NSString *line = [NSString stringWithFormat:@"\n%@", log];
    [gLogs addObject:line];

    dispatch_async(dispatch_get_main_queue(), ^{
        gTextView.text = [gLogs componentsJoinedByString:@""];
        [gTextView scrollRangeToVisible:NSMakeRange(gTextView.text.length, 0)];
    });
}

#pragma mark - 规则存储

static void saveRules() {
    [[NSUserDefaults standardUserDefaults] setObject:gRules forKey:kRulesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void loadRules() {
    NSArray *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kRulesKey];

    if (saved) {
        gRules = [saved mutableCopy];
    } else {
        gRules = [@[
            @"simhaoka.com/phone/index",
            @"https://t\\.me/.*"
        ] mutableCopy];
    }
}

#pragma mark - URL 匹配

static BOOL matchRule(NSString *url, NSString *rule) {
    // 正则
    if ([rule containsString:@"\\"] || [rule containsString:@".*"]) {
        NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:rule options:0 error:nil];

        NSUInteger matches = [regex numberOfMatchesInString:url options:0 range:NSMakeRange(0, url.length)];
        return matches > 0;
    }

    // 普通匹配
    return [url containsString:rule];
}

static BOOL shouldBlockURL(NSURL *url) {
    if (!url) return NO;

    NSString *urlStr = url.absoluteString;

    for (NSString *rule in gRules) {
        if (matchRule(urlStr, rule)) {
            addLog([NSString stringWithFormat:@"[BLOCK] %@", urlStr]);
            return YES;
        }
    }

    return NO;
}

#pragma mark - 悬浮按钮

@interface FloatBtn : UIButton
@end

@implementation FloatBtn {
    CGPoint start;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 200, 60, 60)];
    self.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.8];
    self.layer.cornerRadius = 30;
    [self setTitle:@"ON" forState:UIControlStateNormal];
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    start = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint p = [[touches anyObject] locationInView:self];
    self.center = CGPointMake(self.center.x + p.x - start.x,
                              self.center.y + p.y - start.y);
}

@end

#pragma mark - UI

static void setupUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gWindow) return;

        gWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        gWindow.windowLevel = UIWindowLevelAlert + 1;

        UIViewController *vc = [UIViewController new];
        gWindow.rootViewController = vc;
        gWindow.hidden = NO;

        // 按钮
        FloatBtn *btn = [FloatBtn new];
        [vc.view addSubview:btn];

        [btn addTarget:[NSBlockOperation blockOperationWithBlock:^{
            kEnable = !kEnable;
            [btn setTitle:(kEnable ? @"ON" : @"OFF") forState:UIControlStateNormal];
            addLog(kEnable ? @"[状态] 开启" : @"[状态] 关闭");
        }] action:@selector(main) forControlEvents:UIControlEventTouchUpInside];

        // 输入框
        gInput = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, 260, 40)];
        gInput.backgroundColor = UIColor.whiteColor;
        gInput.placeholder = @"输入规则 (支持正则)";
        [vc.view addSubview:gInput];

        UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(290, 100, 60, 40)];
        addBtn.backgroundColor = UIColor.blueColor;
        [addBtn setTitle:@"添加" forState:UIControlStateNormal];

        [addBtn addTarget:[NSBlockOperation blockOperationWithBlock:^{
            NSString *rule = gInput.text;
            if (rule.length > 0) {
                [gRules addObject:rule];
                saveRules();
                addLog([NSString stringWithFormat:@"[添加规则] %@", rule]);
                gInput.text = @"";
            }
        }] action:@selector(main) forControlEvents:UIControlEventTouchUpInside];

        [vc.view addSubview:addBtn];

        // 日志
        gTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 160, 330, 400)];
        gTextView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        gTextView.textColor = UIColor.greenColor;
        gTextView.editable = NO;

        [vc.view addSubview:gTextView];
    });
}

#pragma mark - Hook

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    if (kEnable && shouldBlockURL(request.URL)) {

        if (completionHandler) {
            NSError *err = [NSError errorWithDomain:@"block" code:-999 userInfo:nil];
            completionHandler(nil, nil, err);
        }

        return nil;
    }

    return %orig;
}

%end

#pragma mark - 入口

%ctor {
    loadRules();
    setupUI();
}