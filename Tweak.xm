#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

#pragma mark - 第一部分：拦截注册码验证请求（NSURLSession）
static id (*orig_dataTaskWithURL_completionHandler)(id self, SEL _cmd, NSURL *url, id completionHandler);
static id new_dataTaskWithURL_completionHandler(id self, SEL _cmd, NSURL *url, id completionHandler) {
    NSString *urlString = url.absoluteString;
    // 匹配目标链接（可根据需要调整匹配规则）
    if ([urlString hasPrefix:@"https://uz1mzm22i185.guyubao.com/5EjBmAUphDWuulmdFtwfWsN8s/"]) {
        NSLog(@"[Bypass] 拦截到注册码验证请求: %@", urlString);
        
        // 伪造的 JSON 响应数据（已转义）
        NSString *fakeJSONString = @"{"
            "\"status\":2000,"
            "\"success\":true,"
            "\"data\":{"
                "\"data\":\"ECD8382CE5CC637B457D7BE9507DD70BD32BB66EE88D42D9565C9C545990481BFA6D673C9EFFC9492DD4C205938181A4C32935FEE0B50FEC3A4BC50656FD4C242F74C87B40E1300DB16236254D8D8CB83E77BFFDEDCFD3843A57E5330097C590EA52827BEA54D3B12395D630FDE630034735C42B49D669526313E6CFCDB73CE4EB9CC1465C907A0D50A8DA4C68EE718441BF11EF3030540316CE5FAD3BE9E696B286728CC0E32FD858278FF15B66A90A6BFEB7E0D8D7591395E3AB9C2F6AAEAB80EB36E4D7A95CE647F4B72A792FE690E3205A6E47775951AA1C06A166C2391DE5A194A635118A7D64A9DC422252330A0F9551E78DF8DB5D79EDCD68FF417754716E7102D145CF04FD84B927F6EE7A9715AB68B891174A2FC305D74484283B72\","
                "\"jsondata\":\"{\\\"msg_a\\\":\\\"success\\\",\\\"fushuxing\\\":\\\"自定义时长卡\\\",\\\"time_S\\\":\\\"352997994\\\",\\\"Ver\\\":\\\"2.5.5\\\",\\\"Retn\\\":\\\"com.xie.workingpartnerbeta5g|com.xingin|ss.iphone\\\",\\\"card_type\\\":\\\"iOS逆向助手永久卡\\\",\\\"mac\\\":\\\"DAB309F6-3579-4C2B-96F3-434E9D0A8F24\\\",\\\"card_note\\\":\\\"发布\\\",\\\"card_bind_txt\\\":\\\"无\\\",\\\"Login_ip\\\":\\\"127.0.0.1\\\",\\\"card_point\\\":\\\"0\\\",\\\"Login_location\\\":\\\"本机地址\\\",\\\"Login_time\\\":\\\"2025-03-19 22:55:10\\\",\\\"card_expirationdate\\\":\\\"2036-05-26 13:55:04\\\",\\\"card_bind_num\\\":\\\"99999999\\\",\\\"card_Agent\\\":\\\"老板号\\\",\\\"card_QQ\\\":\\\"\\\",\\\"card_user\\\":\\\"\\\",\\\"card\\\":\\\"YJK763991374H521841984C0\\\"}\""
            "},"
            "\"msg\":\"验证成功\""
        "}";
        NSData *fakeData = [fakeJSONString dataUsingEncoding:NSUTF8StringEncoding];
        
        // 伪造 HTTP 响应（状态码 200，类型 JSON）
        NSHTTPURLResponse *fakeResponse = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                       statusCode:200
                                                                      HTTPVersion:@"HTTP/1.1"
                                                                     headerFields:@{@"Content-Type": @"application/json"}];
        
        // 保存原始 completionHandler
        void (^originalHandler)(NSData *, NSURLResponse *, NSError *) = (__bridge void (^)(NSData *, NSURLResponse *, NSError *))completionHandler;
        
        // 创建一个空的 completionHandler，用于调用原始方法（避免真实网络请求干扰）
        id emptyHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
            // 什么都不做
        };
        
        // 调用原始方法，传入空 handler，获得 data task
        NSURLSessionDataTask *task = orig_dataTaskWithURL_completionHandler(self, _cmd, url, emptyHandler);
        [task cancel]; // 立即取消，防止真实请求继续
        
        // 在合适的队列中调用原始 handler（通常使用 NSURLSession 的 delegateQueue）
        NSOperationQueue *delegateQueue = [NSURLSession sharedSession].delegateQueue;
        if (delegateQueue) {
            [delegateQueue addOperationWithBlock:^{
                originalHandler(fakeData, fakeResponse, nil);
            }];
        } else {
            // 默认全局队列
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                originalHandler(fakeData, fakeResponse, nil);
            });
        }
        
        return task;
    }
    
    // 不匹配的请求，正常处理
    return orig_dataTaskWithURL_completionHandler(self, _cmd, url, completionHandler);
}

#pragma mark - 第二部分：直接绕过 ZSLoginView 的登录按钮（可选）
// 如果你希望同时修改 UI 行为，可以保留此部分；若仅需网络拦截，可删除

static void (*orig_button_Login)(id self, SEL _cmd);
static void new_button_Login(id self, SEL _cmd) {
    NSLog(@"[Bypass] button_Login 被调用，直接绕过");
    
    // 显示绕过提示（利用原类中的方法，若存在）
    if ([self respondsToSelector:@selector(showAlertWithMessage:)]) {
        [self showAlertWithMessage:@"注册码已跳过，直接登录成功！"];
    }
    
    // 设置状态（如果存在 status_res 属性）
    if ([self respondsToSelector:@selector(setStatus_res:)]) {
        [self setStatus_res:@"登录成功（绕过）"];
    }
    
    // 尝试退出登录界面（假设是导航栈或模态）
    // 通过响应链找到 UIViewController
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            if (vc.navigationController) {
                [vc.navigationController popViewControllerAnimated:YES];
            } else if (vc.presentingViewController) {
                [vc dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }
    }
    
    // 不调用原始 button_Login，彻底绕过验证
}

#pragma mark - 构造函数
__attribute__((constructor)) static void init() {
    @autoreleasepool {
        // Hook NSURLSession 的类方法
        Class sessionClass = objc_getClass("NSURLSession");
        if (sessionClass) {
            SEL selector = @selector(dataTaskWithURL:completionHandler:);
            Method method = class_getClassMethod(sessionClass, selector);
            if (method) {
                MSHookMessageEx(sessionClass, selector, (IMP)&new_dataTaskWithURL_completionHandler, (IMP *)&orig_dataTaskWithURL_completionHandler);
                NSLog(@"[Bypass] Hook NSURLSession dataTaskWithURL:completionHandler: 成功");
            } else {
                NSLog(@"[Bypass] 未找到 NSURLSession 的 dataTaskWithURL:completionHandler: 方法");
            }
        } else {
            NSLog(@"[Bypass] 未找到 NSURLSession 类");
        }
        
        // 可选：Hook ZSLoginView 的 button_Login
        Class loginClass = objc_getClass("ZSLoginView");
        if (loginClass) {
            SEL loginSel = @selector(button_Login);
            Method loginMethod = class_getInstanceMethod(loginClass, loginSel);
            if (loginMethod) {
                MSHookMessageEx(loginClass, loginSel, (IMP)&new_button_Login, (IMP *)&orig_button_Login);
                NSLog(@"[Bypass] Hook ZSLoginView button_Login 成功");
            } else {
                NSLog(@"[Bypass] 未找到 ZSLoginView button_Login 方法");
            }
        } else {
            NSLog(@"[Bypass] 未找到 ZSLoginView 类，可能不需要 Hook 登录按钮");
        }
    }
}