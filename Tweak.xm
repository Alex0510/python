#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 穿透 Window

@interface PassWindow : UIWindow
@end

@implementation PassWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];

    // 只让有交互的控件接收事件
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

#pragma mark - 前置声明

static void togglePanel(void);
static void addLog(NSString *log);

#pragma mark - 日志

static void addLog(NSString *log) {
    if (!logs) logs = [NSMutableArray array];

    [logs addObject:[NSString stringWithFormat:@"\n%@", log]];
    
    if (logs.count > 500) {
        [logs removeObjectsInRange:NSMakeRange(0, 200)];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (logView) {
            logView.text = [logs componentsJoinedByString:@""];
            [logView scrollRangeToVisible:NSMakeRange(logView.text.length, 0)];
        }
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
    if ([rule containsString:@"\\"] || [rule containsString:@".*"] || 
        [rule containsString:@"^"] || [rule containsString:@"$"] ||
        [rule containsString:@"+"] || [rule containsString:@"?"]) {
        NSError *error = nil;
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:rule options:0 error:&error];
        if (error) {
            return NO;
        }
        return [re numberOfMatchesInString:url options:0 range:NSMakeRange(0, url.length)] > 0;
    }
    return [url containsString:rule];
}

static BOOL shouldBlock(NSURL *url) {
    if (!kEnable) return NO;
    
    NSString *u = url.absoluteString;
    
    for (NSString *r in rules) {
        if (match(u, r)) {
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
        togglePanel();
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
    
    if (frame.origin.x < 0) frame.origin.x = 0;
    if (frame.origin.x > screenWidth - frame.size.width) frame.origin.x = screenWidth - frame.size.width;
    if (frame.origin.y < 0) frame.origin.y = 0;
    if (frame.origin.y > screenHeight - frame.size.height) frame.origin.y = screenHeight - frame.size.height;
    
    self.frame = frame;
    startPoint = currentPoint;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    if (!isDragging) return;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = self.frame;
        CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
        
        if (frame.origin.x + frame.size.width / 2 < screenWidth / 2) {
            frame.origin.x = 8;
        } else {
            frame.origin.x = screenWidth - frame.size.width - 8;
        }
        
        CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
        if (frame.origin.y < 40) frame.origin.y = 40;
        if (frame.origin.y > screenHeight - frame.size.height - 40) {
            frame.origin.y = screenHeight - frame.size.height - 40;
        }
        
        self.frame = frame;
    }];
}

@end

#pragma mark - 展开/收起

static void togglePanel() {
    isOpen = !isOpen;

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        panel.alpha = isOpen ? 1 : 0;
        panel.transform = isOpen ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);
    } completion:nil];
    
    if (isOpen) {
        [panel.superview bringSubviewToFront:panel];
    }
}

#pragma mark - Action 函数

static void addRuleAction(void) {
    if (input.text.length > 0) {
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

static void clearRulesAction(void) {
    [rules removeAllObjects];
    saveRules();
    addLog(@"已清空所有规则");
    
    UITextView *ruleListView = (UITextView *)[panel viewWithTag:1001];
    if (ruleListView) {
        ruleListView.text = @"暂无规则";
    }
}

static void toggleEnableAction(UISwitch *sender) {
    kEnable = sender.isOn;
    saveSettings();
    addLog([NSString stringWithFormat:@"全局屏蔽: %@", kEnable ? @"开启" : @"关闭"]);
}

static void toggleBlockAlertsAction(UISwitch *sender) {
    blockAlerts = sender.isOn;
    saveSettings();
    addLog([NSString stringWithFormat:@"弹窗屏蔽: %@", blockAlerts ? @"开启" : @"关闭"]);
}

static void segmentChangedAction(UISegmentedControl *sender) {
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

static void closePanelAction(void) {
    if (isOpen) {
        togglePanel();
    }
}

#pragma mark - 初始化 UI

static void setupUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        gWindow = [[PassWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        gWindow.windowLevel = UIWindowLevelAlert + 100;
        gWindow.backgroundColor = [UIColor clearColor];
        gWindow.userInteractionEnabled = YES;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = [UIColor clearColor];
        gWindow.rootViewController = vc;
        gWindow.hidden = NO;

        ball = [FloatBall new];
        [vc.view addSubview:ball];

        CGFloat panelWidth = 340;
        CGFloat panelHeight = 540;
        CGFloat panelX = (UIScreen.mainScreen.bounds.size.width - panelWidth) / 2;
        CGFloat panelY = (UIScreen.mainScreen.bounds.size.height - panelHeight) / 2;
        
        panel = [[UIView alloc] initWithFrame:CGRectMake(panelX, panelY, panelWidth, panelHeight)];
        panel.backgroundColor = [[UIColor colorWithWhite:0.1 alpha:0.95] colorWithAlphaComponent:0.95];
        panel.layer.cornerRadius = 15;
        panel.layer.shadowColor = UIColor.blackColor.CGColor;
        panel.layer.shadowOffset = CGSizeMake(0, 5);
        panel.layer.shadowRadius = 15;
        panel.layer.shadowOpacity = 0.3;
        panel.alpha = 0;
        panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
        [vc.view addSubview:panel];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 150, 30)];
        titleLabel.text = @"网络屏蔽插件";
        titleLabel.textColor = UIColor.whiteColor;
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [panel addSubview:titleLabel];
        
        UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 45, 15, 30, 30)];
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:20];
        closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
        closeBtn.layer.cornerRadius = 15;
        [closeBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:closeBtn];
        
        UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(15, 55, panelWidth - 30, 50)];
        switchContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
        switchContainer.layer.cornerRadius = 8;
        [panel addSubview:switchContainer];
        
        UILabel *enableLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 80, 20)];
        enableLabel.text = @"全局屏蔽";
        enableLabel.textColor = UIColor.whiteColor;
        enableLabel.font = [UIFont systemFontOfSize:14];
        [switchContainer addSubview:enableLabel];
        
        enableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(switchContainer.frame.size.width - 65, 10, 50, 30)];
        enableSwitch.on = kEnable;
        [enableSwitch addTarget:self action:@selector(toggleEnable:) forControlEvents:UIControlEventValueChanged];
        [switchContainer addSubview:enableSwitch];
        
        UIView *alertContainer = [[UIView alloc] initWithFrame:CGRectMake(15, 115, panelWidth - 30, 50)];
        alertContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
        alertContainer.layer.cornerRadius = 8;
        [panel addSubview:alertContainer];
        
        UILabel *alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 100, 20)];
        alertLabel.text = @"屏蔽插件弹窗";
        alertLabel.textColor = UIColor.whiteColor;
        alertLabel.font = [UIFont systemFontOfSize:14];
        [alertContainer addSubview:alertLabel];
        
        alertSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(alertContainer.frame.size.width - 65, 10, 50, 30)];
        alertSwitch.on = blockAlerts;
        [alertSwitch addTarget:self action:@selector(toggleBlockAlerts:) forControlEvents:UIControlEventValueChanged];
        [alertContainer addSubview:alertSwitch];
        
        UILabel *ruleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 180, 100, 25)];
        ruleLabel.text = @"添加规则";
        ruleLabel.textColor = UIColor.whiteColor;
        ruleLabel.font = [UIFont boldSystemFontOfSize:14];
        [panel addSubview:ruleLabel];
        
        input = [[UITextField alloc] initWithFrame:CGRectMake(15, 210, panelWidth - 100, 40)];
        input.backgroundColor = UIColor.whiteColor;
        input.layer.cornerRadius = 8;
        input.placeholder = @"域名或正则表达式";
        input.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        input.leftViewMode = UITextFieldViewModeAlways;
        input.font = [UIFont systemFontOfSize:14];
        [panel addSubview:input];

        UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 75, 210, 60, 40)];
        [addBtn setTitle:@"添加" forState:UIControlStateNormal];
        addBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1];
        addBtn.layer.cornerRadius = 8;
        addBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [addBtn addTarget:self action:@selector(addRule) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:addBtn];
        
        UILabel *listLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 260, 100, 25)];
        listLabel.text = @"规则列表";
        listLabel.textColor = UIColor.whiteColor;
        listLabel.font = [UIFont boldSystemFontOfSize:14];
        [panel addSubview:listLabel];
        
        UIButton *clearBtn = [[UIButton alloc] initWithFrame:CGRectMake(panelWidth - 70, 260, 55, 25)];
        [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
        clearBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        clearBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1];
        clearBtn.layer.cornerRadius = 5;
        [clearBtn addTarget:self action:@selector(clearRules) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:clearBtn];
        
        UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"日志", @"规则列表"]];
        segment.frame = CGRectMake(15, 295, panelWidth - 30, 30);
        segment.selectedSegmentIndex = 0;
        [segment addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        [panel addSubview:segment];
        
        logView = [[UITextView alloc] initWithFrame:CGRectMake(15, 335, panelWidth - 30, 190)];
        logView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
        logView.textColor = [UIColor colorWithRed:0.3 green:0.9 blue:0.3 alpha:1];
        logView.font = [UIFont fontWithName:@"Menlo" size:10];
        logView.editable = NO;
        logView.layer.cornerRadius = 8;
        [panel addSubview:logView];
        
        UITextView *ruleListView = [[UITextView alloc] initWithFrame:CGRectMake(15, 335, panelWidth - 30, 190)];
        ruleListView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
        ruleListView.textColor = UIColor.whiteColor;
        ruleListView.font = [UIFont fontWithName:@"Menlo" size:11];
        ruleListView.editable = NO;
        ruleListView.layer.cornerRadius = 8;
        ruleListView.hidden = YES;
        ruleListView.tag = 1001;
        [panel addSubview:ruleListView];
        
        NSMutableString *ruleText = [NSMutableString string];
        for (int i = 0; i < rules.count; i++) {
            [ruleText appendFormat:@"%d. %@\n", i + 1, rules[i]];
        }
        ruleListView.text = ruleText.length ? ruleText : @"暂无规则";
        
        addLog(@"插件已启动 v1.0");
        addLog([NSString stringWithFormat:@"全局屏蔽: %@", kEnable ? @"开启" : @"关闭"]);
        addLog([NSString stringWithFormat:@"弹窗屏蔽: %@", blockAlerts ? @"开启" : @"关闭"]);
    });
}

#pragma mark - Actions (使用 Logos 的 %ctor 无法直接添加方法，需要通过 Category)

@interface TweakActions : NSObject
+ (void)closePanel;
+ (void)addRule;
+ (void)clearRules;
+ (void)toggleEnable:(UISwitch *)sender;
+ (void)toggleBlockAlerts:(UISwitch *)sender;
+ (void)segmentChanged:(UISegmentedControl *)sender;
@end

@implementation TweakActions
+ (void)closePanel { closePanelAction(); }
+ (void)addRule { addRuleAction(); }
+ (void)clearRules { clearRulesAction(); }
+ (void)toggleEnable:(UISwitch *)sender { toggleEnableAction(sender); }
+ (void)toggleBlockAlerts:(UISwitch *)sender { toggleBlockAlertsAction(sender); }
+ (void)segmentChanged:(UISegmentedControl *)sender { segmentChangedAction(sender); }
@end

#pragma mark - Hook

%hook UIAlertController

- (void)viewDidLoad {
    %orig;
    
    if (blockAlerts && kEnable) {
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
    }
}

%end

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    if (kEnable && shouldBlock(request.URL)) {
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
    
    // 为按钮添加 target
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 通过遍历找到按钮并添加 target
        if (panel) {
            for (UIView *subview in panel.subviews) {
                if ([subview isKindOfClass:[UIButton class]]) {
                    UIButton *btn = (UIButton *)subview;
                    NSString *title = [btn titleForState:UIControlStateNormal];
                    if ([title isEqualToString:@"✕"]) {
                        [btn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [btn addTarget:[TweakActions class] action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
                    } else if ([title isEqualToString:@"添加"]) {
                        [btn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [btn addTarget:[TweakActions class] action:@selector(addRule) forControlEvents:UIControlEventTouchUpInside];
                    } else if ([title isEqualToString:@"清空"]) {
                        [btn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [btn addTarget:[TweakActions class] action:@selector(clearRules) forControlEvents:UIControlEventTouchUpInside];
                    }
                } else if ([subview isKindOfClass:[UISwitch class]]) {
                    UISwitch *sw = (UISwitch *)subview;
                    if (sw == enableSwitch) {
                        [sw removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [sw addTarget:[TweakActions class] action:@selector(toggleEnable:) forControlEvents:UIControlEventValueChanged];
                    } else if (sw == alertSwitch) {
                        [sw removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [sw addTarget:[TweakActions class] action:@selector(toggleBlockAlerts:) forControlEvents:UIControlEventValueChanged];
                    }
                } else if ([subview isKindOfClass:[UISegmentedControl class]]) {
                    UISegmentedControl *seg = (UISegmentedControl *)subview;
                    [seg removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    [seg addTarget:[TweakActions class] action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
                }
            }
        }
    });
}