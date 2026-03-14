#import <objc/runtime.h>

// 定义关联对象的key
static const char *kReceivedDataKey = "kReceivedDataKey";

// 全局变量保存悬浮窗和链接列表
static UIWindow *floatingWindow = nil;
static NSArray *capturedUrls = nil;

%hook AFHTTPSessionManager

// 拦截数据接收，进行拼接
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    %orig; // 先调用原始实现，保证正常功能

    // 仅处理目标请求（可根据实际域名/路径调整）
    NSString *path = dataTask.originalRequest.URL.path;
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

    // 处理目标请求
    if ([task.originalRequest.URL.path containsString:@"tracker/v5/url"]) {
        NSMutableData *receivedData = objc_getAssociatedObject(task, kReceivedDataKey);
        if (receivedData && !error) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:&jsonError];
            if (json && !jsonError) {
                NSArray *urls = json[@"url"];
                if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {
                    // 在主线程更新UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showFloatingButtonWithUrls:urls];
                    });
                }
            }
        }
        // 清理关联对象
        objc_setAssociatedObject(task, kReceivedDataKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

// 添加新方法：显示悬浮按钮
%new
- (void)showFloatingButtonWithUrls:(NSArray *)urls {
    capturedUrls = urls; // 保存链接列表

    if (!floatingWindow) {
        // 创建悬浮窗口
        floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 100, 60, 60)];
        floatingWindow.windowLevel = UIWindowLevelAlert + 1; // 高于普通窗口
        floatingWindow.backgroundColor = [UIColor clearColor];
        floatingWindow.rootViewController = [UIViewController new];
        floatingWindow.rootViewController.view.backgroundColor = [UIColor clearColor];

        // 添加按钮
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = floatingWindow.bounds;
        button.backgroundColor = [UIColor redColor];
        button.layer.cornerRadius = 30;
        button.clipsToBounds = YES;
        [button setTitle:@"DL" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [floatingWindow.rootViewController.view addSubview:button];

        // 添加拖动手势（可选）
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [button addGestureRecognizer:pan];

        floatingWindow.hidden = NO;
    }
}

// 处理拖动
%new
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:floatingWindow];
        floatingWindow.center = CGPointMake(floatingWindow.center.x + translation.x, floatingWindow.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:floatingWindow];
    }
}

// 按钮点击事件：显示链接列表
%new
- (void)floatingButtonTapped {
    if (!capturedUrls || capturedUrls.count == 0) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择下载链接" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *url in capturedUrls) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:url style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 尝试直接打开http链接
            NSURL *httpURL = [NSURL URLWithString:url];
            if ([[UIApplication sharedApplication] canOpenURL:httpURL]) {
                [[UIApplication sharedApplication] openURL:httpURL];
            } else {
                // 备选：构造 m3u8app:// 协议（根据目标app支持的格式调整）
                NSString *m3u8URLString = [NSString stringWithFormat:@"m3u8app://%@", url];
                NSURL *m3u8URL = [NSURL URLWithString:m3u8URLString];
                [[UIApplication sharedApplication] openURL:m3u8URL];
            }
        }];
        [alert addAction:action];
    }

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];

    // 获取当前显示的控制器以present弹窗
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

%end