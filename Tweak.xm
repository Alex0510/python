#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>

static BOOL kEnableBlock = YES;

#pragma mark - URL 规则

BOOL isBlockedURL(NSString *url) {
    if (!url) return NO;

    NSArray *rules = @[
        @"simhaoka.com",
        @"t.me",
        @"telegram",
        @"tg://",
        @"joinchat",
        @"invite"
    ];

    for (NSString *rule in rules) {
        if ([url.lowercaseString containsString:rule]) {
            NSLog(@"🚫 拦截URL: %@", url);
            return YES;
        }
    }

    return NO;
}

#pragma mark - UIApplication

CHDeclareClass(UIApplication)

CHOptimizedMethod1(self, BOOL, UIApplication, openURL, NSURL *, url) {
    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 openURL 被拦截: %@", url);
        return NO;
    }
    return CHSuper1(UIApplication, openURL, url);
}

CHOptimizedMethod2(self, BOOL, UIApplication, openURL, NSURL *, url, options, NSDictionary *, options) {
    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 openURL(options) 被拦截: %@", url);
        return NO;
    }
    return CHSuper2(UIApplication, openURL, url, options, options);
}

#pragma mark - 弹窗拦截

CHDeclareClass(UIViewController)

CHOptimizedMethod3(self, void, UIViewController,
presentViewController,
UIViewController *, vc,
animated, BOOL, animated,
completion, void (^)(void), completion)
{
    if (kEnableBlock && [vc isKindOfClass:[UIAlertController class]]) {

        UIAlertController *alert = (UIAlertController *)vc;

        NSString *msg = [NSString stringWithFormat:@"%@ %@",
                         alert.title ?: @"",
                         alert.message ?: @""];

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
                NSLog(@"🚫 拦截弹窗: %@", msg);
                return;
            }
        }
    }

    CHSuper3(UIViewController,
             presentViewController,
             vc,
             animated,
             animated,
             completion,
             completion);
}

#pragma mark - WKWebView

CHDeclareClass(WKWebView)

CHOptimizedMethod1(self, id, WKWebView, loadRequest, NSURLRequest *, request) {

    NSString *url = request.URL.absoluteString;

    if (kEnableBlock && isBlockedURL(url)) {
        NSLog(@"🚫 WKWebView 拦截: %@", url);
        return nil;
    }

    return CHSuper1(WKWebView, loadRequest, request);
}

#pragma mark - Safari

CHDeclareClass(SFSafariViewController)

CHOptimizedMethod1(self, id, SFSafariViewController, initWithURL, NSURL *, url) {

    if (kEnableBlock && isBlockedURL(url.absoluteString)) {
        NSLog(@"🚫 Safari 拦截: %@", url);
        return nil;
    }

    return CHSuper1(SFSafariViewController, initWithURL, url);
}

#pragma mark - 构造函数

CHConstructor {
    @autoreleasepool {

        NSLog(@"🔥 广告/跳转拦截插件已加载");

        CHLoadLateClass(UIApplication);
        CHHook1(UIApplication, openURL);
        CHHook2(UIApplication, openURL, options);

        CHLoadLateClass(UIViewController);
        CHHook3(UIViewController, presentViewController, animated, completion);

        CHLoadLateClass(WKWebView);
        CHHook1(WKWebView, loadRequest);

        CHLoadLateClass(SFSafariViewController);
        CHHook1(SFSafariViewController, initWithURL);
    }
}