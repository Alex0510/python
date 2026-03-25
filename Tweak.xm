#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 穿透 Window

@interface PassWindow : UIWindow
@end

@implementation PassWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];

    if ([view isKindOfClass:[UIButton class]] ||
        [view isKindOfClass:[UITextField class]] ||
        [view isKindOfClass:[UITextView class]] ||
        [view isKindOfClass:[UISwitch class]] ||
        [view isKindOfClass:[UISegmentedControl class]]) {
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
static UISwitch *enableSwitch;
static UISwitch *alertSwitch;

static BOOL isOpen = NO;
static BOOL kEnable = YES;
static BOOL blockAlerts = YES;
static NSMutableArray *logs;
static NSMutableArray *rules;

#define kRulesKey @"rules"
#define kBlockAlertsKey @"blockAlerts"
#define kEnableKey @"enable"

#pragma mark - 线程安全队列

static dispatch_queue_t logQueue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.adblocker.log", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

#pragma mark - 日志

static void addLog(NSString *log) {
    if (!log) return;
    
    dispatch_async(logQueue(), ^{
        if (!logs) {
            logs = [NSMutableArray array];
        }
        
        [logs addObject:[NSString stringWithFormat:@"\n%@", log]];
        
        if (logs.count > 500) {
            [logs removeObjectsInRange:NSMakeRange(0, 200)];
        }
        
        // 创建日志文本的副本
        NSString *logText = [logs componentsJoinedByString:@""];
        
        // 安全地更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                if (logView && logView.superview) {
                    logView.text = logText;
                    [logView scrollRangeToVisible:NSMakeRange(logView.text.length, 0)];
                }
            } @catch (NSException *exception) {
                // 静默失败，避免崩溃
                NSLog(@"AdBlocker: Failed to update log view: %@", exception);
            }
        });
    });
}

#pragma mark - 规则

static void loadRules() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *arr = [defaults objectForKey:kRulesKey];
    rules = arr ? [arr mutableCopy] : [@[@"simhaoka.com", @"t\\.me/.*"] mutableCopy];
    
    if ([defaults objectForKey:kEnableKey]) {
        kEnable = [defaults boolForKey:kEnableKey];
    }
    
    blockAlerts = [defaults boolForKey:kBlockAlertsKey];
    if (![defaults objectForKey:kBlockAlertsKey]) {
        blockAlerts = YES;
        [defaults setBool:YES forKey:kBlockAlertsKey];
    }
}

static void saveRules() {
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:kRulesKey];
}

static void saveSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:kEnable forKey:kEnableKey];
    [defaults setBool:blockAlerts forKey:kBlockAlertsKey];
}

#pragma mark - 匹配

static BOOL match(NSString *url, NSString *rule) {
    @try {
        if ([rule containsString:@"\\"] || [rule containsString:@".*"] || 
            [rule containsString:@"^"] || [rule containsString:@"$"] ||
            [rule containsString:@"+"] || [rule containsString:@"?"]) {
            NSError *error = nil;
            NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:rule options:0 error:&error];
            if (error) return NO;
            return [re numberOfMatchesInString:url options:0 range:NSMakeRange(0, url.length)] > 0;
        }
        return [url containsString:rule];
    } @catch (NSException *exception) {
        return NO;
    }
}

static BOOL shouldBlock(NSURL *url) {
    if (!kEnable || !url) return NO;
    
    NSString *u = url.absoluteString;
    if (!u) return NO;
    
    for (NSString *r in rules) {
        if (r && match(u, r)) {
            addLog([NSString stringWithFormat:@"[BLOCK] %@", u]);
            return YES;
        }
    }
    return NO;
}

#pragma mark - UI - 悬浮球

@interface FloatBall : UIButton
@end

@implementation FloatBall {
    CGPoint startPoint;
    BOOL isDragging;
}

- (instancetype)init {
    CGFloat size = 55;
    CGFloat x = UIScreen.mainScreen.bounds.size.width - size - 15;
    CGFloat y = 200;
    self = [super initWithFrame:CGRectMake(x, y, size, size)];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:0.9];
        self.layer.cornerRadius = size / 2;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 4;
        self.layer.shadowOpacity = 0.3;
        
        [self setTitle:@"⚡" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:28];
        
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)handleTap {
    if (!isDragging) {
        if (panel) {
            isOpen = !isOpen;
            [UIView animateWithDuration:0.3 animations:^{
                panel.alpha = isOpen ? 1 : 0;
                panel.transform = isOpen ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);
            }];
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isDragging = NO;
    UITouch *touch = [touches anyObject];
    startPoint = [touch locationInView:self.superview];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isDragging = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.superview];
    
    CGRect frame = self.frame;
    frame.origin.x += currentPoint.x - startPoint.x;
    frame.origin.y += currentPoint.y - startPoint.y;
    
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    
    frame.origin.x = MAX(0, MIN(frame.origin.x, screenWidth - frame.size.width));
    frame.origin.y = MAX(0, MIN(frame.origin.y, screenHeight - frame.size.height));
    
    self.frame = frame;
    startPoint = currentPoint;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (!isDragging) return;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = self.frame;
        CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        
        if (frame.origin.x + frame.size.width / 2 < screenWidth / 2) {
            frame.origin.x = 8;
        } else {
            frame.origin.x = screenWidth - frame.size.width - 8;
        }
        
        frame.origin.y = MAX(40, MIN(frame.origin.y, screenHeight - frame.size.height - 40));
        self.frame = frame;
    }];
}

@end

#pragma mark - Actions 类

@interface TweakActions : NSObject
+ (void)closePanel;
+ (void)addRule;
+ (void)clearRules;
+ (void)toggleEnable:(UISwitch *)sender;
+ (void)toggleBlockAlerts:(UISwitch *)sender;
+ (void)segmentChanged:(UISegmentedControl *)sender;
@end

@implementation TweakActions

+ (void)closePanel {
    if (isOpen && panel) {
        isOpen = NO;
        [UIView animateWithDuration:0.3 animations:^{
            panel.alpha = 0;
            panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
        }];
    }
}

+ (void)addRule {
    if (input && input.text.length > 0) {
        [rules addObject:input.text];
        saveRules();
        addLog([NSString stringWithFormat:@"[添加规则] %@", input.text]);
        input.text = @"";
        
        UITextView *ruleListView = (UITextView *)[panel viewWithTag:1001];
        if (ruleListView) {
            NSMutableString *ruleText = [NSMutableString string];
            for (int i = 0; i < rules.count; i++) {
                [ruleText appendFormat:@"%d. %@\n", i + 1, rules[i]];
            }
            ruleListView.text = ruleText.length ? ruleText : @"暂无规则";
        }
    }
}

+ (void)clearRules {
    [rules removeAllObjects];
    saveRules();
    addLog(@"已清空所有规则");
    
    UITextView *ruleListView = (UITextView *)[panel viewWithTag:1001];
    if (ruleListView) {
        ruleListView.text = @"暂无规则";
    }
}

+ (void)toggleEnable:(UISwitch *)sender {
    kEnable = sender.isOn;
    saveSettings();
    addLog([NSString stringWithFormat:@"全局屏蔽: %@", kEnable ? @"开启" : @"关闭"]);
}

+ (void)toggleBlockAlerts:(UISwitch *)sender {
    blockAlerts = sender.isOn;
    saveSettings();
    addLog([NSString stringWithFormat:@"弹窗屏蔽: %@", blockAlerts ? @"开启" : @"关闭"]);
}

+ (void)segmentChanged:(UISegmentedControl *)sender {
    UITextView *ruleListView = (UITextView *)[panel viewWithTag:1001];
    
    if (sender.selectedSegmentIndex == 0) {
        ruleListView.hidden = YES;
        logView.hidden = NO;
    } else {
        ruleListView.hidden = NO;
        logView.hidden = YES;
        
        NSMutableString *ruleText = [NSMutableString string];
        for (int i = 0; i < rules.count; i++) {
            [ruleText appendFormat:@"%d. %@\n", i + 1, rules[i]];
        }
        ruleListView.text = ruleText.length ? ruleText : @"暂无规则";
    }
}

@end

#pragma mark - 初始化 UI

static void setupUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            gWindow = [[PassWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
            gWindow.windowLevel = UIWindowLevelAlert + 100;
            gWindow.backgroundColor = [UIColor clearColor];
            gWindow.userInteractionEnabled = YES;
            gWindow.hidden = NO;
            
            UIViewController *vc = [UIViewController new];
            vc.view.backgroundColor = [UIColor clearColor];
            gWindow.rootViewController = vc;
            
            // 悬浮球
            ball = [FloatBall new];
            [vc.view addSubview:ball];
            
            // 面板
            CGFloat panelWidth = 340;
            CGFloat panelHeight = 540;
            CGFloat panelX = (UIScreen.mainScreen.bounds.size.width - panelWidth) / 2;
            CGFloat panelY = (UIScreen.mainScreen.bounds.size.height - panelHeight) / 2;
            
            panel = [[UIView alloc] initWithFrame:CGRectMake(panelX, panelY, panelWidth, panelHeight)];
            panel.backgroundColor = [[UIColor colorWithWhite:0.1 alpha:0.95] colorWithAlphaComponent:0.95];
            panel.layer.cornerRadius = 15;
            panel.alpha = 0;
            panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
            [vc.view addSubview:panel];
            
            // 标题
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 150, 30)];
            titleLabel.text = @"网络屏蔽插件";
            titleLabel.textColor = UIColor.whiteColor;
            titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [panel addSubview:titleLabel];
            
            // 关闭按钮
            UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 45, 15, 30, 30)];
            [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
            closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
            closeBtn.layer.cornerRadius = 15;
            [closeBtn addTarget:[TweakActions class] action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
            [panel addSubview:closeBtn];
            
            // 全局屏蔽开关
            UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(15, 55, panelWidth - 30, 50)];
            switchContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
            switchContainer.layer.cornerRadius = 8;
            [panel addSubview:switchContainer];
            
            UILabel *enableLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 80, 20)];
            enableLabel.text = @"全局屏蔽";
            enableLabel.textColor = UIColor.whiteColor;
            [switchContainer addSubview:enableLabel];
            
            enableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(switchContainer.frame.size.width - 65, 10, 50, 30)];
            enableSwitch.on = kEnable;
            [enableSwitch addTarget:[TweakActions class] action:@selector(toggleEnable:) forControlEvents:UIControlEventValueChanged];
            [switchContainer addSubview:enableSwitch];
            
            // 弹窗屏蔽开关
            UIView *alertContainer = [[UIView alloc] initWithFrame:CGRectMake(15, 115, panelWidth - 30, 50)];
            alertContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
            alertContainer.layer.cornerRadius = 8;
            [panel addSubview:alertContainer];
            
            UILabel *alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 100, 20)];
            alertLabel.text = @"屏蔽插件弹窗";
            alertLabel.textColor = UIColor.whiteColor;
            [alertContainer addSubview:alertLabel];
            
            alertSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(alertContainer.frame.size.width - 65, 10, 50, 30)];
            alertSwitch.on = blockAlerts;
            [alertSwitch addTarget:[TweakActions class] action:@selector(toggleBlockAlerts:) forControlEvents:UIControlEventValueChanged];
            [alertContainer addSubview:alertSwitch];
            
            // 规则输入
            UILabel *ruleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 180, 100, 25)];
            ruleLabel.text = @"添加规则";
            ruleLabel.textColor = UIColor.whiteColor;
            [panel addSubview:ruleLabel];
            
            input = [[UITextField alloc] initWithFrame:CGRectMake(15, 210, panelWidth - 100, 40)];
            input.backgroundColor = UIColor.whiteColor;
            input.layer.cornerRadius = 8;
            input.placeholder = @"域名或正则表达式";
            input.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
            input.leftViewMode = UITextFieldViewModeAlways;
            [panel addSubview:input];
            
            UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 75, 210, 60, 40)];
            [addBtn setTitle:@"添加" forState:UIControlStateNormal];
            addBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1];
            addBtn.layer.cornerRadius = 8;
            [addBtn addTarget:[TweakActions class] action:@selector(addRule) forControlEvents:UIControlEventTouchUpInside];
            [panel addSubview:addBtn];
            
            // 规则列表
            UILabel *listLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 260, 100, 25)];
            listLabel.text = @"规则列表";
            listLabel.textColor = UIColor.whiteColor;
            [panel addSubview:listLabel];
            
            UIButton *clearBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 70, 260, 55, 25)];
            [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
            clearBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1];
            clearBtn.layer.cornerRadius = 5;
            [clearBtn addTarget:[TweakActions class] action:@selector(clearRules) forControlEvents:UIControlEventTouchUpInside];
            [panel addSubview:clearBtn];
            
            // 分段选择器
            UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"日志", @"规则列表"]];
            segment.frame = CGRectMake(15, 295, panelWidth - 30, 30);
            segment.selectedSegmentIndex = 0;
            [segment addTarget:[TweakActions class] action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [panel addSubview:segment];
            
            // 日志视图
            logView = [[UITextView alloc] initWithFrame:CGRectMake(15, 335, panelWidth - 30, 190)];
            logView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
            logView.textColor = [UIColor colorWithRed:0.3 green:0.9 blue:0.3 alpha:1];
            logView.font = [UIFont fontWithName:@"Menlo" size:10];
            logView.editable = NO;
            [panel addSubview:logView];
            
            // 规则列表视图
            UITextView *ruleListView = [[UITextView alloc] initWithFrame:CGRectMake(15, 335, panelWidth - 30, 190)];
            ruleListView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
            ruleListView.textColor = UIColor.whiteColor;
            ruleListView.font = [UIFont fontWithName:@"Menlo" size:11];
            ruleListView.editable = NO;
            ruleListView.hidden = YES;
            ruleListView.tag = 1001;
            [panel addSubview:ruleListView];
            
            // 更新规则列表
            NSMutableString *ruleText = [NSMutableString string];
            for (int i = 0; i < rules.count; i++) {
                [ruleText appendFormat:@"%d. %@\n", i + 1, rules[i]];
            }
            ruleListView.text = ruleText.length ? ruleText : @"暂无规则";
            
            // 延迟添加启动日志，确保UI完全就绪
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                addLog(@"插件已启动 v1.0");
                addLog([NSString stringWithFormat:@"全局屏蔽: %@", kEnable ? @"开启" : @"关闭"]);
                addLog([NSString stringWithFormat:@"弹窗屏蔽: %@", blockAlerts ? @"开启" : @"关闭"]);
            });
            
        } @catch (NSException *exception) {
            NSLog(@"AdBlocker: Setup UI failed - %@", exception);
        }
    });
}

#pragma mark - Hook

%hook UIAlertController

- (void)viewDidLoad {
    %orig;
    
    if (blockAlerts && kEnable) {
        @try {
            NSString *title = self.title ?: @"";
            NSString *message = self.message ?: @"";
            NSString *fullText = [NSString stringWithFormat:@"%@ %@", title, message];
            
            NSArray *keywords = @[@"评分", @"评价", @"好评", @"去设置", @"打开通知", @"会员", @"VIP", @"订阅", @"优惠", @"促销", @"推荐", @"广告", @"点赞", @"分享"];
            
            BOOL shouldBlockAlert = NO;
            for (NSString *keyword in keywords) {
                if ([fullText containsString:keyword]) {
                    shouldBlockAlert = YES;
                    break;
                }
            }
            
            if (!shouldBlockAlert) {
                for (NSString *rule in rules) {
                    if ([fullText containsString:rule] || [title containsString:rule] || [message containsString:rule]) {
                        shouldBlockAlert = YES;
                        break;
                    }
                }
            }
            
            if (shouldBlockAlert) {
                addLog(@"[BLOCK ALERT] 已屏蔽应用弹窗");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:NO completion:nil];
                });
            }
        } @catch (NSException *exception) {
            // 忽略异常
        }
    }
}

%end

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (kEnable && request.URL && shouldBlock(request.URL)) {
        NSError *error = [NSError errorWithDomain:@"NetworkBlocker" 
                                             code:999 
                                         userInfo:@{NSLocalizedDescriptionKey: @"已被网络屏蔽插件拦截"}];
        if (completionHandler) {
            completionHandler(nil, nil, error);
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