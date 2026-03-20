#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

#pragma mark - 自定义 NSURLProtocol 拦截器
@interface BypassURLProtocol : NSURLProtocol
@end

@implementation BypassURLProtocol

// 判断是否需要拦截该请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *urlString = request.URL.absoluteString;
    // 使用 containsString 匹配域名，适应动态参数
    if ([urlString containsString:@"uz1mzm22i185.guyubao.com"]) {
        NSLog(@"[Bypass] 拦截到请求: %@", urlString);
        return YES;
    }
    return NO;
}

// 返回规范化请求（通常直接返回原请求）
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// 开始加载伪造的响应
- (void)startLoading {
    // 伪造的 JSON 数据（已正确转义）
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
    NSHTTPURLResponse *fakeResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                   statusCode:200
                                                                  HTTPVersion:@"HTTP/1.1"
                                                                 headerFields:@{@"Content-Type": @"application/json"}];
    
    // 将伪造的响应和数据传递给客户端
    [self.client URLProtocol:self didReceiveResponse:fakeResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:fakeData];
    [self.client URLProtocolDidFinishLoading:self];
}

// 停止加载（不需要额外操作）
- (void)stopLoading {
    // Nothing to do
}

@end

#pragma mark - 可选：直接绕过 ZSLoginView 的登录按钮
static void (*orig_button_Login)(id self, SEL _cmd);
static void new_button_Login(id self, SEL _cmd) {
    NSLog(@"[Bypass] button_Login 被调用，直接绕过验证");
    
    // 显示提示（如果原类有 showAlertWithMessage: 方法）
    if ([self respondsToSelector:@selector(showAlertWithMessage:)]) {
        [self showAlertWithMessage:@"注册码已跳过，直接登录成功！"];
    }
    
    // 设置状态属性（如果存在）
    if ([self respondsToSelector:@selector(setStatus_res:)]) {
        [self setStatus_res:@"登录成功（绕过）"];
    }
    
    // 尝试退出登录界面（通过响应链找到 UIViewController）
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
    
    // 不调用原始实现，彻底绕过
    // 如需保留原始功能，可取消下面注释
    // orig_button_Login(self, _cmd);
}

#pragma mark - 构造函数：dylib 加载时执行
__attribute__((constructor)) static void init() {
    @autoreleasepool {
        // 1. 注册自定义 NSURLProtocol
        [NSURLProtocol registerClass:[BypassURLProtocol class]];
        NSLog(@"[Bypass] NSURLProtocol 注册成功 - 等待拦截请求");
        
        // 2. Hook ZSLoginView 的 button_Login 方法（如果存在）
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
            NSLog(@"[Bypass] 未找到 ZSLoginView 类，跳过按钮 Hook");
        }
    }
}