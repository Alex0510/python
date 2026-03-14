#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>
#import <objc/runtime.h>

// ==================== 自定义 NSURLProtocol 拦截器 ====================
@interface KGURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableData *responseData;
@end

static NSMutableDictionary *g_cachedUrls = nil;

@implementation KGURLProtocol

+ (void)load {
    [NSURLProtocol registerClass:self];
    g_cachedUrls = [NSMutableDictionary dictionary];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.absoluteString containsString:@"/tracker/v5/url"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
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
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&jsonError];
        if (!jsonError && [json isKindOfClass:[NSDictionary class]]) {
            NSArray *urls = json[@"url"];
            if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {
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

// ==================== 声明需要使用的播放页类 ====================
CHDeclareClass(KGYouthPlayViewController);      // 通用播放页
CHDeclareClass(KGYouthNewPlayViewController);   // 新版播放页
CHDeclareClass(KGMVPlayerViewController);       // MV播放页

static const void *kFloatingButtonKey = &kFloatingButtonKey;

// ==================== 辅助函数 ====================

// 获取当前歌曲 hash
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
static void showAlert(UIViewController *vc, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}

// 显示带 URL 列表的面板（添加到窗口）
static void showPanelWithUrls(UIWindow *window, NSArray *urls, NSString *hash) {
    // 移除旧面板
    UIView *oldPanel = [window viewWithTag:9999];
    [oldPanel removeFromSuperview];
    
    CGFloat panelWidth = 300;
    CGFloat panelHeight = 400;
    CGFloat panelX = (window.bounds.size.width - panelWidth) / 2;
    CGFloat panelY = (window.bounds.size.height - panelHeight) / 2;
    
    UIView *panelBg = [[UIView alloc] initWithFrame:window.bounds];
    panelBg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    panelBg.tag = 9999;
    [window addSubview:panelBg];
    [window bringSubviewToFront:panelBg];
    
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(panelX, panelY, panelWidth, panelHeight)];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 12;
    panel.clipsToBounds = YES;
    [panelBg addSubview:panel];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, panelWidth-20, 30)];
    titleLabel.text = @"选择下载地址：";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:titleLabel];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, panelWidth, panelHeight-100) style:UITableViewStylePlain];
    tableView.dataSource = (id<UITableViewDataSource>)panelBg;
    tableView.delegate = (id<UITableViewDelegate>)panelBg;
    tableView.rowHeight = 44;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [panel addSubview:tableView];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(10, panelHeight-50, panelWidth-20, 40);
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor lightGrayColor];
    closeBtn.layer.cornerRadius = 8;
    [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeBtn addTarget:panelBg action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:closeBtn];
    
    // 存储数据
    objc_setAssociatedObject(panelBg, "urls", urls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(panelBg, "hash", hash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 动态添加 UITableView 数据源方法
    IMP numberOfRowsIMP = imp_implementationWithBlock(^NSInteger(id self, UITableView *tv, NSInteger section) {
        return [objc_getAssociatedObject(self, "urls") count];
    });
    class_addMethod([panelBg class], @selector(tableView:numberOfRowsInSection:), numberOfRowsIMP, "l@:@@l");
    
    IMP cellForRowIMP = imp_implementationWithBlock(^UITableViewCell *(id self, UITableView *tv, NSIndexPath *ip) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
            cell.textLabel.font = [UIFont systemFontOfSize:12];
            cell.textLabel.numberOfLines = 2;
        }
        cell.textLabel.text = objc_getAssociatedObject(self, "urls")[ip.row];
        return cell;
    });
    class_addMethod([panelBg class], @selector(tableView:cellForRowAtIndexPath:), cellForRowIMP, "@@:@@");
    
    IMP didSelectRowIMP = imp_implementationWithBlock(^(id self, UITableView *tv, NSIndexPath *ip) {
        [tv deselectRowAtIndexPath:ip animated:YES];
        NSString *urlString = objc_getAssociatedObject(self, "urls")[ip.row];
        NSString *encodedUrl = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"m3u8app://download?url=%@", encodedUrl]];
        
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:finalURL]) {
            [app openURL:finalURL options:@{} completionHandler:nil];
        } else {
            // 替换为真实的 m3u8 应用 App Store ID
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

// ==================== 通用的 Hook 逻辑（使用宏简化） ====================

#define HOOK_PLAY_VIEW_CONTROLLER(ClassName) \
CHOptimizedMethod(1, self, void, ClassName, viewDidAppear, BOOL, animated) { \
    CHSuper1(ClassName, viewDidAppear, animated); \
    UIButton *existingBtn = objc_getAssociatedObject(self, kFloatingButtonKey); \
    if (existingBtn) return; \
    UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom]; \
    floatBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 70, [UIScreen mainScreen].bounds.size.height - 150, 50, 50); \
    floatBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.9]; \
    floatBtn.layer.cornerRadius = 25; \
    [floatBtn setTitle:@"⏬" forState:UIControlStateNormal]; \
    [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; \
    [floatBtn addTarget:self action:@selector(floatButtonTapped) forControlEvents:UIControlEventTouchUpInside]; \
    UIWindow *window = [UIApplication sharedApplication].keyWindow; \
    [window addSubview:floatBtn]; \
    [window bringSubviewToFront:floatBtn]; \
    objc_setAssociatedObject(self, kFloatingButtonKey, floatBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
\
CHOptimizedMethod(1, self, void, ClassName, viewWillDisappear, BOOL, animated) { \
    CHSuper1(ClassName, viewWillDisappear, animated); \
    UIButton *floatBtn = objc_getAssociatedObject(self, kFloatingButtonKey); \
    [floatBtn removeFromSuperview]; \
    objc_setAssociatedObject(self, kFloatingButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
    UIWindow *window = [UIApplication sharedApplication].keyWindow; \
    UIView *panel = [window viewWithTag:9999]; \
    [panel removeFromSuperview]; \
} \
\
CHOptimizedMethod(0, self, void, ClassName, floatButtonTapped) { \
    NSString *hash = currentSongHash(self); \
    if (!hash) { \
        showAlert((UIViewController *)self, @"无法获取歌曲信息"); \
        return; \
    } \
    NSArray *urls = nil; \
    @synchronized(g_cachedUrls) { \
        urls = g_cachedUrls[hash]; \
    } \
    if (!urls || urls.count == 0) { \
        showAlert((UIViewController *)self, @"暂无下载链接，请先播放歌曲"); \
        return; \
    } \
    UIWindow *window = [UIApplication sharedApplication].keyWindow; \
    showPanelWithUrls(window, urls, hash); \
}

// ==================== 为每个类应用 Hook ====================
HOOK_PLAY_VIEW_CONTROLLER(KGYouthPlayViewController)
HOOK_PLAY_VIEW_CONTROLLER(KGYouthNewPlayViewController)
HOOK_PLAY_VIEW_CONTROLLER(KGMVPlayerViewController)

// ==================== 构造函数 ====================
CHConstructor {
    @autoreleasepool {
        // 确保协议被注册
        [KGURLProtocol class];
        
        // 加载所有可能的播放页类（如果存在则生效）
        CHLoadLateClass(KGYouthPlayViewController);
        CHLoadLateClass(KGYouthNewPlayViewController);
        CHLoadLateClass(KGMVPlayerViewController);
    }
}