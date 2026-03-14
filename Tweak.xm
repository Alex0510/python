#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>
#import <objc/runtime.h>

// 自定义 NSURLProtocol 子类，用于拦截特定请求
@interface KGURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableData *responseData;
@end

// 全局字典，存储请求返回的 URL 列表（key 为歌曲 hash）
static NSMutableDictionary *g_cachedUrls = nil;

@implementation KGURLProtocol

+ (void)load {
    // 在加载时注册协议
    [NSURLProtocol registerClass:self];
    g_cachedUrls = [NSMutableDictionary dictionary];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 只拦截目标 URL
    NSString *urlString = request.URL.absoluteString;
    if ([urlString containsString:@"/tracker/v5/url"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // 使用 NSURLSession 发起请求，以便获取数据
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    self.task = [session dataTaskWithRequest:self.request];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
    self.task = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.responseData = [NSMutableData data];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        // 解析响应数据
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&jsonError];
        if (!jsonError && [json isKindOfClass:[NSDictionary class]]) {
            NSArray *urls = json[@"url"];
            if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {
                // 从请求 URL 中提取 hash 参数
                NSString *query = self.request.URL.query;
                NSString *hash = nil;
                NSArray *pairs = [query componentsSeparatedByString:@"&"];
                for (NSString *pair in pairs) {
                    NSArray *kv = [pair componentsSeparatedByString:@"="];
                    if (kv.count == 2 && [kv[0] isEqualToString:@"hash"]) {
                        hash = kv[1];
                        break;
                    }
                }
                if (hash) {
                    @synchronized(g_cachedUrls) {
                        g_cachedUrls[hash] = urls;
                    }
                }
            }
        }
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end

// 声明需要使用的类
CHDeclareClass(KGGuessFavorPlayViewController);
CHDeclareClass(SongInfo);

// 存储悬浮按钮的关联对象键
static const void *kFloatingButtonKey = &kFloatingButtonKey;

// 获取当前歌曲 hash 的辅助函数
static NSString *currentSongHash(id self) {
    SEL songInfoSel = @selector(currentSongInfo);
    if (![self respondsToSelector:songInfoSel]) return nil;
    id songInfo = ((id (*)(id, SEL))objc_msgSend)(self, songInfoSel);
    if (!songInfo) return nil;
    
    NSString *hash = nil;
    SEL fileHashSel = @selector(fileHash);
    if ([songInfo respondsToSelector:fileHashSel]) {
        hash = ((NSString *(*)(id, SEL))objc_msgSend)(songInfo, fileHashSel);
    }
    if (!hash) {
        SEL hashSel = @selector(hash);
        if ([songInfo respondsToSelector:hashSel]) {
            hash = ((NSString *(*)(id, SEL))objc_msgSend)(songInfo, hashSel);
        }
    }
    return hash;
}

// 显示简单提示
static void showAlert(id self, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// 显示带 URL 列表的面板
static void showPanelWithUrls(UIView *parentView, NSArray *urls, NSString *hash) {
    UIView *panelBg = [[UIView alloc] initWithFrame:parentView.bounds];
    panelBg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    panelBg.tag = 9999;
    [parentView addSubview:panelBg];
    
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 12;
    panel.clipsToBounds = YES;
    [panelBg addSubview:panel];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"选择下载地址：";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:titleLabel];
    
    UITableView *tableView = [[UITableView alloc] init];
    tableView.dataSource = (id<UITableViewDataSource>)panelBg;
    tableView.delegate = (id<UITableViewDelegate>)panelBg;
    tableView.rowHeight = 44;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [panel addSubview:tableView];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor lightGrayColor];
    closeBtn.layer.cornerRadius = 8;
    [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeBtn addTarget:panelBg action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:closeBtn];
    
    // Auto Layout
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    [panelBg addConstraints:@[
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:panelBg attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:panelBg attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeWidth constant:300],
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeHeight constant:400]
    ]];
    
    [panel addConstraints:@[
        [NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTop multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:-10],
        
        [NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
        
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:tableView attribute:NSLayoutAttributeBottom multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:-10],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeHeight constant:40],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]
    ]];
    
    // 存储数据供 tableView 使用
    objc_setAssociatedObject(panelBg, "urls", urls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(panelBg, "hash", hash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 动态添加 tableView 数据源和代理方法
    IMP numberOfRowsIMP = imp_implementationWithBlock(^NSInteger(id self, UITableView *tv, NSInteger section) {
        NSArray *urls = objc_getAssociatedObject(self, "urls");
        return urls.count;
    });
    class_addMethod([panelBg class], @selector(tableView:numberOfRowsInSection:), numberOfRowsIMP, "l@:@@l");
    
    IMP cellForRowIMP = imp_implementationWithBlock(^UITableViewCell *(id self, UITableView *tv, NSIndexPath *ip) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
            cell.textLabel.font = [UIFont systemFontOfSize:12];
            cell.textLabel.numberOfLines = 2;
        }
        NSArray *urls = objc_getAssociatedObject(self, "urls");
        cell.textLabel.text = urls[ip.row];
        return cell;
    });
    class_addMethod([panelBg class], @selector(tableView:cellForRowAtIndexPath:), cellForRowIMP, "@@:@@");
    
    IMP didSelectRowIMP = imp_implementationWithBlock(^(id self, UITableView *tv, NSIndexPath *ip) {
        [tv deselectRowAtIndexPath:ip animated:YES];
        NSArray *urls = objc_getAssociatedObject(self, "urls");
        NSString *urlString = urls[ip.row];
        
        NSString *encodedUrl = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *scheme = [NSString stringWithFormat:@"m3u8app://download?url=%@", encodedUrl];
        NSURL *finalURL = [NSURL URLWithString:scheme];
        
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:finalURL]) {
            [app openURL:finalURL options:@{} completionHandler:nil];
        } else {
            // 替换为真实应用 ID
            NSURL *appStoreURL = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id123456789"];
            [app openURL:appStoreURL options:@{} completionHandler:nil];
        }
        [self removeFromSuperview];
    });
    class_addMethod([panelBg class], @selector(tableView:didSelectRowAtIndexPath:), didSelectRowIMP, "v@:@@");
    
    // 添加关闭方法
    IMP closeIMP = imp_implementationWithBlock(^(id self) {
        [self removeFromSuperview];
    });
    class_addMethod([panelBg class], @selector(closePanel), closeIMP, "v@:");
}

// Hook viewDidLoad 添加悬浮按钮
CHOptimizedMethod(0, self, void, KGGuessFavorPlayViewController, viewDidLoad) {
    CHSuper0(KGGuessFavorPlayViewController, viewDidLoad);
    
    UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    floatBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.9];
    floatBtn.layer.cornerRadius = 25;
    [floatBtn setTitle:@"⏬" forState:UIControlStateNormal];
    [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [floatBtn addTarget:self action:@selector(floatButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    floatBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:floatBtn];
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-20],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-100],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeWidth constant:50],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeHeight constant:50]
    ]];
    
    objc_setAssociatedObject(self, kFloatingButtonKey, floatBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 按钮点击方法
CHOptimizedMethod(0, self, void, KGGuessFavorPlayViewController, floatButtonTapped) {
    NSString *hash = currentSongHash(self);
    if (!hash) {
        showAlert(self, @"无法获取歌曲信息");
        return;
    }
    
    NSArray *urls = nil;
    @synchronized(g_cachedUrls) {
        urls = g_cachedUrls[hash];
    }
    if (!urls || urls.count == 0) {
        showAlert(self, @"暂无下载链接，请先播放歌曲");
        return;
    }
    
    UIView *existingPanel = [self.view viewWithTag:9999];
    [existingPanel removeFromSuperview];
    
    showPanelWithUrls(self.view, urls, hash);
}

// 页面消失时移除按钮和面板
CHOptimizedMethod(1, self, void, KGGuessFavorPlayViewController, viewDidDisappear, BOOL, animated) {
    CHSuper1(KGGuessFavorPlayViewController, viewDidDisappear, animated);
    
    UIButton *floatBtn = objc_getAssociatedObject(self, kFloatingButtonKey);
    [floatBtn removeFromSuperview];
    objc_setAssociatedObject(self, kFloatingButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIView *panel = [self.view viewWithTag:9999];
    [panel removeFromSuperview];
}

// 构造函数
CHConstructor {
    @autoreleasepool {
        // 确保协议被注册（已在 +load 中注册）
        [KGURLProtocol class];
        
        CHLoadLateClass(KGGuessFavorPlayViewController);
        CHHook0(KGGuessFavorPlayViewController, viewDidLoad);
        CHHook0(KGGuessFavorPlayViewController, floatButtonTapped);
        CHHook1(KGGuessFavorPlayViewController, viewDidDisappear);
    }
}