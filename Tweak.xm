#import <Foundation/Foundation.h>

// 定义要拦截的请求 URL 关键字（根据实际抓包结果）
#define TARGET_URL @"guyubao.com"          // 域名，可根据需要更改为完整路径

// 伪造的成功响应数据（直接复制你抓包得到的 JSON）
static NSString *fakeResponseJSON = @"{\"status\":2000,\"success\":true,\"data\":{\"data\":\"ECD8382CE5CC637B457D7BE9507DD70BD32BB66EE88D42D9565C9C545990481BFA6D673C9EFFC9492DD4C205938181A4C32935FEE0B50FEC3A4BC50656FD4C242F74C87B40E1300DB16236254D8D8CB83E77BFFDEDCFD3843A57E5330097C590EA52827BEA54D3B12395D630FDE630034735C42B49D669526313E6CFCDB73CE4EB9CC1465C907A0D50A8DA4C68EE718441BF11EF3030540316CE5FAD3BE9E696B286728CC0E32FD858278FF15B66A90A6BFEB7E0D8D7591395E3AB9C2F6AAEAB80EB36E4D7A95CE647F4B72A792FE690E3205A6E47775951AA1C06A166C2391DE5A194A635118A7D64A9DC422252330A0F9551E78DF8DB5D79EDCD68FF417754716E7102D145CF04FD84B927F6EE7A9715AB68B891174A2FC305D74484283B72\",\"jsondata\":\"{\\\"msg_a\\\":\\\"success\\\",\\\"fushuxing\\\":\\\"自定义时长卡\\\",\\\"time_S\\\":\\\"352997994\\\",\\\"Ver\\\":\\\"2.5.5\\\",\\\"Retn\\\":\\\"com.xie.workingpartnerbeta5g|com.xingin|ss.iphone\\\",\\\"card_type\\\":\\\"iOS逆向助手永久卡\\\",\\\"mac\\\":\\\"DAB309F6-3579-4C2B-96F3-434E9D0A8F24\\\",\\\"card_note\\\":\\\"发布\\\",\\\"card_bind_txt\\\":\\\"无\\\",\\\"Login_ip\\\":\\\"127.0.0.1\\\",\\\"card_point\\\":\\\"0\\\",\\\"Login_location\\\":\\\"本机地址\\\",\\\"Login_time\\\":\\\"2025-03-19 22:55:10\\\",\\\"card_expirationdate\\\":\\\"2036-05-26 13:55:04\\\",\\\"card_bind_num\\\":\\\"99999999\\\",\\\"card_Agent\\\":\\\"老板号\\\",\\\"card_QQ\\\":\\\"\\\",\\\"card_user\\\":\\\"\\\",\\\"card\\\":\\\"YJK763991374H521841984C0\\\"}\"},\"msg\":\"验证成功\"}";

// ==================== 自定义 NSURLProtocol 拦截器 ====================
@interface FakeResponseProtocol : NSURLProtocol
@end

@implementation FakeResponseProtocol

// 决定是否拦截该请求
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *urlString = request.URL.absoluteString;
    // 检查是否包含目标域名（可根据需要改为更精确的路径匹配）
    if ([urlString containsString:TARGET_URL]) {
        NSLog(@"[FakeProtocol] 拦截请求: %@", urlString);
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// 开始加载（伪造响应）
- (void)startLoading {
    // 构造 HTTP 响应，状态码 200，内容类型 JSON
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                               statusCode:200
                                                              HTTPVersion:@"HTTP/1.1"
                                                             headerFields:@{@"Content-Type": @"application/json"}];
    
    // 将 JSON 字符串转为 NSData
    NSData *fakeData = [fakeResponseJSON dataUsingEncoding:NSUTF8StringEncoding];
    
    // 通过 client 返回数据
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:fakeData];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    // 无需额外操作
}

@end

// ==================== 辅助：防止弹出错误提示（可选） ====================
// 假设 ZSLoginView 类存在，我们 Hook 掉弹窗方法，让界面更干净
%hook ZSLoginView

- (void)showAlertWithMessage:(id)message {
    %log;
    // 什么都不做，屏蔽弹窗
    return;
}

- (void)showAlertWithTitle:(id)title message:(id)message {
    %log;
    return;
}

%end

// ==================== 在加载动态库时注册协议 ====================
%ctor {
    // 注册自定义协议拦截器
    [NSURLProtocol registerClass:[FakeResponseProtocol class]];
    NSLog(@"[FakeProtocol] 已注册，等待拦截请求...");
}