#import <UIKit/UIKit.h>

static BOOL kHookEnabled = YES;

#pragma mark - 工具函数（智能识别 VIP 字段）

BOOL isVipKey(NSString *key) {
    NSArray *keys = @[
        @"vip", @"isvip", @"is_vip",
        @"pro", @"ispro",
        @"premium",
        @"member", @"ismember"
    ];

    for (NSString *k in keys) {
        if ([[key lowercaseString] containsString:k]) {
            return YES;
        }
    }
    return NO;
}

id processJson(id obj) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [obj mutableCopy];

        for (NSString *key in dict.allKeys) {
            id value = dict[key];

            if (isVipKey(key)) {
                dict[key] = @1;
            } else {
                dict[key] = processJson(value);
            }
        }
        return dict;
    }

    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *arr = [obj mutableCopy];

        for (NSInteger i = 0; i < arr.count; i++) {
            arr[i] = processJson(arr[i]);
        }
        return arr;
    }

    return obj;
}

#pragma mark - 网络 Hook（核心）

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {

        if (!kHookEnabled || !data) {
            completionHandler(data, response, error);
            return;
        }

        NSString *url = request.URL.absoluteString;

        if ([url containsString:@"api"] ||
            [url containsString:@"user"] ||
            [url containsString:@"vip"]) {

            NSError *jsonError = nil;

            id json =
            [NSJSONSerialization JSONObjectWithData:data
                                            options:NSJSONReadingMutableContainers
                                              error:&jsonError];

            if (!jsonError && json) {

                NSLog(@"[Hook] 命中接口: %@", url);

                id newJson = processJson(json);

                NSData *newData =
                [NSJSONSerialization dataWithJSONObject:newJson
                                                options:0
                                                  error:nil];

                if (newData) {
                    completionHandler(newData, response, error);
                    return;
                }
            }
        }

        completionHandler(data, response, error);
    });
}

%end

#pragma mark - UI 文本 Hook

%hook UILabel

- (void)setText:(NSString *)text {

    if (!kHookEnabled) {
        %orig(text);
        return;
    }

    if ([text containsString:@"Pro"] ||
        [text containsString:@"VIP"] ||
        [text containsString:@"会员"]) {

        text = @"已解锁";
    }

    %orig(text);
}

%end

#pragma mark - 悬浮窗

@interface HookWindow : UIWindow
@end

@implementation HookWindow

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 200, 60, 60)];
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.layer.cornerRadius = 30;
    self.windowLevel = UIWindowLevelAlert + 1;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = self.bounds;
    [btn setTitle:@"ON" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:btn];

    self.hidden = NO;
    return self;
}

- (void)toggle {
    kHookEnabled = !kHookEnabled;

    UIButton *btn = self.subviews.firstObject;
    [btn setTitle:(kHookEnabled ? @"ON" : @"OFF") forState:UIControlStateNormal];

    NSLog(@"[Hook] 状态: %@", kHookEnabled ? @"开启" : @"关闭");
}

@end

#pragma mark - 启动

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        HookWindow *win = [HookWindow new];
        win.hidden = NO;
    });
}