#import <UIKit/UIKit.h>
#import "ACManager.h"

@interface ACFloating : UIWindow
@end

#pragma mark - 网络日志（调试用途）

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {

    NSLog(@"[Net] URL: %@", request.URL.absoluteString);

    return %orig(request, ^(NSData *data, NSURLResponse *res, NSError *err) {

        if (data) {
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[Net] Response: %@", str);
        }

        if (completionHandler) {
            completionHandler(data, res, err);
        }
    });
}

%end

#pragma mark - UI 注入

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        static ACFloating *f;
        f = [ACFloating new];
    });
}

%end