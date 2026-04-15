#import <UIKit/UIKit.h>
#import "ACManager.h"

@interface ACFloating : UIWindow
@end

#pragma mark - 网络日志（安全写法）

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    NSLog(@"[Net] URL: %@", request.URL.absoluteString);

    void (^newBlock)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {

        if (data) {
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[Net] Response: %@", str);
        }

        if (completionHandler) {
            completionHandler(data, response, error);
        }
    };

    return %orig(request, newBlock);
}

%end

#pragma mark - UI 注入

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static ACFloating *f = nil;
        if (!f) {
            f = [ACFloating new];
        }
    });
}

%end