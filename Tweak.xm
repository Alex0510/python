#import <objc/runtime.h>

// 关联对象key
static const char *kReceivedDataKey = "kReceivedDataKey";
static const char *kButtonAddedKey = "kButtonAddedKey";

// 全局保存捕获的链接
static NSMutableArray *capturedUrls = nil;

// 悬浮窗口
static UIWindow *floatingWindow = nil;
static BOOL isWindowCreated = NO;

#pragma mark - 网络请求拦截 (Hook AFHTTPSessionManager)
%hook AFHTTPSessionManager

// 拦截数据接收，拼接到关联数据中
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    %orig;

    NSString *path = dataTask.originalRequest.URL.path;
    // 判断是否为目标请求（可根据实际调整域名/路径）
    if ([path containsString:@"tracker/v5/url"]) {
        NSMutableData *receivedData = objc_getAssociatedObject(dataTask, kReceivedDataKey);
        if (!receivedData) {
            receivedData = [NSMutableData data];
            objc_setAssociatedObject(dataTask, kReceivedDataKey, receivedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [receivedData appendData:data];
    }
}

// 请求完成时解析数据
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    %orig;

    if ([task.originalRequest.URL.path containsString:@"tracker/v5/url"]) {
        NSMutableData *receivedData = objc_getAssociatedObject(task, kReceivedDataKey);
        if (receivedData && !error) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&jsonError];
            if (json && !jsonError) {
                NSArray *urls = json[@"url"];
                if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {
                    // 保存链接到全局数组（线程安全）
                    dispatch_async(dispatch_get_main_queue(), ^{
                        static dispatch_once_t onceToken;
                        dispatch_once(&onceToken, ^{
                            capturedUrls = [NSMutableArray array];
                        });
                        [capturedUrls addObjectsFromArray:urls];
                        // 可选：去重
                        // capturedUrls = [[[NSSet setWithArray:capturedUrls] allObjects] mutableCopy];
                    });
                }
            }
        }
        // 清理关联对象
        objc_setAssociatedObject(task, kReceivedDataKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

#pragma mark - 播放页面添加悬浮按钮
%hook 酷狗播放页面的控制器类名   // 需要替换为实际类名，例如 KGPlayerViewController

- (void)viewDidLoad {
    %orig;
    [self addFloatingButtonIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self addFloatingButtonIfNeeded];
}

%new
- (void)addFloatingButtonIfNeeded {
    // 避免重复添加
    if ([objc_getAssociatedObject(self, kButtonAddedKey) boolValue]) return;

    // 创建悬浮窗口（如果未创建）
    if (!isWindowCreated) {
        [self createFloatingWindow];
        isWindowCreated = YES;
    }

    // 将悬浮窗口显示在当前视图之上
    floatingWindow.hidden = NO;
    [floatingWindow makeKeyAndVisible]; // 注意：这可能会抢夺keyWindow，但悬浮窗通常不需要成为key，只是显示
    // 更好的方式是：将floatingWindow的windowLevel设得比普通窗口高，且不makeKeyAndVisible，只设置hidden=NO
    // 这里简化，但makeKeyAndVisible可能导致输入焦点问题，可以用下面的方式：
    // floatingWindow.hidden = NO;
    // 不调用makeKeyAndVisible，仅显示

    objc_setAssociatedObject(self, kButtonAddedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)createFloatingWindow {
    floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 100, 60, 60)];
    floatingWindow.windowLevel = UIWindowLevelAlert + 1; // 高于普通窗口
    floatingWindow.backgroundColor = [UIColor clearColor];
    floatingWindow.rootViewController = [UIViewController new];
    floatingWindow.rootViewController.view.backgroundColor = [UIColor clearColor];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = floatingWindow.bounds;
    button.backgroundColor = [UIColor redColor];
    button.layer.cornerRadius = 30;
    button.clipsToBounds = YES;
    [button setTitle:@"DL" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [floatingWindow.rootViewController.view addSubview:button];

    // 拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [button addGestureRecognizer:pan];

    // 默认隐藏，等需要显示时再设置hidden=NO
    floatingWindow.hidden = YES;
}

%new
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:floatingWindow];
        floatingWindow.center = CGPointMake(floatingWindow.center.x + translation.x, floatingWindow.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:floatingWindow];
    }
}

%new
- (void)floatingButtonTapped {
    if (!capturedUrls || capturedUrls.count == 0) {
        // 没有链接时提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"暂无下载链接" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [[self topMostViewController] presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择下载链接" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *url in capturedUrls) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:url style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openDownloadURL:url];
        }];
        [alert addAction:action];
    }

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];

    [[self topMostViewController] presentViewController:alert animated:YES completion:nil];
}

%new
- (void)openDownloadURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // 尝试自定义协议
        NSString *m3u8URLString = [NSString stringWithFormat:@"m3u8app://%@", urlString];
        NSURL *m3u8URL = [NSURL URLWithString:m3u8URLString];
        [[UIApplication sharedApplication] openURL:m3u8URL];
    }
}

%new
- (UIViewController *)topMostViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

%end