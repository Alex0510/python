#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

static BOOL kEnableBlock = YES;

#pragma mark - URL 过滤规则

BOOL isBlockedURL(NSString *url) {
    if (!url) return NO;

    NSArray *rules = @[
        @"simhaoka.com",
        @"t.me",
        @"telegram",
        @"invite",
        @"jump",
        @"open",
        @"scheme"
    ];

    for (NSString *rule in rules) {
        if ([url.lowercaseString containsString:rule]) {
            NSLog(@"[拦截URL] %@", url);
            return YES;
        }
    }

    return NO;
}

#pragma mark - Hook UIApplication 打开URL

CHDeclareClass(UIApplication)

CHOptimizedMethod1(self, BOOL, UIApplication, openURL, NSURL *, url) {
    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 已拦截 openURL: %@", url);
        return NO;
    }
    return CHSuper1(UIApplication, openURL, url);
}

CHOptimizedMethod2(self, BOOL, UIApplication, openURL, NSURL *, url, options, NSDictionary *, options) {
    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 已拦截 openURL(options): %@", url);
        return NO;
    }
    return CHSuper2(UIApplication, openURL, url, options, options);
}

#pragma mark - Hook UIAlertController 弹窗

CHDeclareClass(UIAlertController)

CHOptimizedMethod2(self, void, UIViewController, presentViewController, UIViewController *, vc, animated, BOOL, animated, completion, void (^)(void), completion) {

    if (kEnableBlock && [vc isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)vc;

        NSString *msg = [NSString stringWithFormat:@"%@ %@", alert.title ?: @"", alert.message ?: @""];

        NSArray *keywords = @[
            @"跳转",
            @"下载",
            @"安装",
            @"telegram",
            @"链接",
            @"广告",
            @"推广",
            @"网址"
        ];

        for (NSString *key in keywords) {
            if ([msg.lowercaseString containsString:key]) {
                NSLog(@"🚫 已拦截弹窗: %@", msg);
                return;
            }
        }
    }

    CHSuper2(UIViewController, presentViewController, vc, animated, animated, completion, completion);
}

#pragma mark - Hook WKWebView 跳转

CHDeclareClass(WKWebView)

CHOptimizedMethod1(self, WKNavigation *, WKWebView, loadRequest, NSURLRequest *, request) {
    NSString *url = request.URL.absoluteString;

    if (kEnableBlock && isBlockedURL(url)) {
        NSLog(@"🚫 已拦截 WKWebView: %@", url);
        return nil;
    }

    return CHSuper1(WKWebView, loadRequest, request);
}

#pragma mark - Hook SFSafariViewController

CHDeclareClass(SFSafariViewController)

CHOptimizedMethod1(self, id, SFSafariViewController, initWithURL, NSURL *, url) {

    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 已拦截 Safari: %@", url);
        return nil;
    }

    return CHSuper1(SFSafariViewController, initWithURL, url);
}

#pragma mark - 构造

CHConstructor {
    @autoreleasepool {
        NSLog(@"🔥 URL/弹窗拦截插件加载成功");

        CHLoadLateClass(UIApplication);
        CHHook1(UIApplication, openURL);
        CHHook2(UIApplication, openURL, options);

        CHLoadLateClass(UIViewController);
        CHHook2(UIViewController, presentViewController, animated, completion);

        CHLoadLateClass(WKWebView);
        CHHook1(WKWebView, loadRequest);

        CHLoadLateClass(SFSafariViewController);
        CHHook1(SFSafariViewController, initWithURL);
    }
}