#import <UIKit/UIKit.h>

#pragma mark - 穿透 Window

@interface PassWindow : UIWindow
@end

@implementation PassWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];

    // 只让有交互的控件接收事件
    if ([view isKindOfClass:[UIButton class]] ||
        [view isKindOfClass:[UITextField class]] ||
        [view isKindOfClass:[UITextView class]]) {
        return view;
    }

    return nil;
}

@end

#pragma mark - 全局

static PassWindow *gWindow;
static UIView *panel;
static UIButton *ball;
static UITextView *logView;
static UITextField *input;

static BOOL isOpen = NO;
static BOOL kEnable = YES;
static NSMutableArray *logs;
static NSMutableArray *rules;

#define kRulesKey @"rules"

#pragma mark - 日志

static void addLog(NSString *log) {
    if (!logs) logs = [NSMutableArray array];

    [logs addObject:[NSString stringWithFormat:@"\n%@", log]];

    dispatch_async(dispatch_get_main_queue(), ^{
        logView.text = [logs componentsJoinedByString:@""];
        [logView scrollRangeToVisible:NSMakeRange(logView.text.length, 0)];
    });
}

#pragma mark - 规则

static void loadRules() {
    NSArray *arr = [[NSUserDefaults standardUserDefaults] objectForKey:kRulesKey];
    rules = arr ? [arr mutableCopy] : [@[@"simhaoka.com", @"t\\.me/.*"] mutableCopy];
}

static void saveRules() {
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:kRulesKey];
}

#pragma mark - 匹配

static BOOL match(NSString *url, NSString *rule) {
    if ([rule containsString:@"\\"] || [rule containsString:@".*"]) {
        NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:rule options:0 error:nil];
        return [re numberOfMatchesInString:url options:0 range:NSMakeRange(0, url.length)] > 0;
    }
    return [url containsString:rule];
}

static BOOL shouldBlock(NSURL *url) {
    NSString *u = url.absoluteString;

    for (NSString *r in rules) {
        if (match(u, r)) {
            addLog([NSString stringWithFormat:@"[BLOCK] %@", u]);
            return YES;
        }
    }
    return NO;
}

#pragma mark - UI

@interface FloatBall : UIButton
@end

@implementation FloatBall {
    CGPoint start;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 300, 60, 60)];
    self.backgroundColor = UIColor.redColor;
    self.layer.cornerRadius = 30;
    [self setTitle:@"●" forState:UIControlStateNormal];
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // 吸边
    CGFloat x = self.center.x;
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    self.center = CGPointMake(x < screenW/2 ? 30 : screenW-30, self.center.y);
}

@end

#pragma mark - 展开/收起

static void togglePanel() {
    isOpen = !isOpen;

    [UIView animateWithDuration:0.25 animations:^{
        panel.alpha = isOpen ? 1 : 0;
    }];
}

#pragma mark - 初始化 UI

static void setupUI() {
    dispatch_async(dispatch_get_main_queue(), ^{

        gWindow = [[PassWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        gWindow.windowLevel = UIWindowLevelAlert + 1;

        UIViewController *vc = [UIViewController new];
        gWindow.rootViewController = vc;
        gWindow.hidden = NO;

        // 悬浮球
        ball = [FloatBall new];
        [ball addTarget:nil action:@selector(togglePanelAction) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:ball];

        // 面板
        panel = [[UIView alloc] initWithFrame:CGRectMake(20, 100, 300, 400)];
        panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        panel.layer.cornerRadius = 10;
        panel.alpha = 0;
        [vc.view addSubview:panel];

        // 输入框
        input = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 200, 40)];
        input.backgroundColor = UIColor.whiteColor;
        input.placeholder = @"输入规则";
        [panel addSubview:input];

        UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(220, 10, 60, 40)];
        [addBtn setTitle:@"添加" forState:UIControlStateNormal];
        addBtn.backgroundColor = UIColor.blueColor;

        [addBtn addTarget:nil action:@selector(addRuleAction) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:addBtn];

        // 日志
        logView = [[UITextView alloc] initWithFrame:CGRectMake(10, 60, 280, 330)];
        logView.backgroundColor = UIColor.blackColor;
        logView.textColor = UIColor.greenColor;
        logView.editable = NO;
        [panel addSubview:logView];

    });
}

#pragma mark - Action（用 runtime 绑定）

@interface NSObject (Action)
- (void)togglePanelAction;
- (void)addRuleAction;
@end

@implementation NSObject (Action)

- (void)togglePanelAction {
    togglePanel();
}

- (void)addRuleAction {
    if (input.text.length > 0) {
        [rules addObject:input.text];
        saveRules();
        addLog([NSString stringWithFormat:@"[添加] %@", input.text]);
        input.text = @"";
    }
}

@end

#pragma mark - Hook

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    if (kEnable && shouldBlock(request.URL)) {
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"block" code:-999 userInfo:nil]);
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