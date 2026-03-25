#import <Foundation/Foundation.h>

#pragma mark - 工具函数

static BOOL shouldBlockURL(NSURL *url) {
    if (!url) return NO;

    NSString *urlStr = url.absoluteString.lowercaseString;

    // 拦截 simhaoka
    if ([urlStr containsString:@"simhaoka.com/phone/index"]) {
        NSLog(@"[BLOCK] 命中 simhaoka: %@", urlStr);
        return YES;
    }

    // 拦截 t.me
    if ([urlStr containsString:@"t.me/"]) {
        NSLog(@"[BLOCK] 命中 Telegram: %@", urlStr);
        return YES;
    }

    return NO;
}

#pragma mark - NSURLSession Hook

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    if (shouldBlockURL(request.URL)) {
        NSLog(@"[BLOCK] NSURLSession 拦截请求: %@", request.URL);

        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:@"block.domain"
                                                 code:-999
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request Blocked"}];

            completionHandler(nil, nil, error);
        }

        return nil;
    }

    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    if (shouldBlockURL(url)) {
        NSLog(@"[BLOCK] NSURLSession 拦截 URL: %@", url);

        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:@"block.domain"
                                                 code:-999
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request Blocked"}];

            completionHandler(nil, nil, error);
        }

        return nil;
    }

    return %orig;
}

%end

#pragma mark - NSURLConnection Hook（兼容旧 API）

%hook NSURLConnection

+ (NSURLConnection *)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate {

    if (shouldBlockURL(request.URL)) {
        NSLog(@"[BLOCK] NSURLConnection 拦截: %@", request.URL);
        return nil;
    }

    return %orig;
}

- (instancetype)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {

    if (shouldBlockURL(request.URL)) {
        NSLog(@"[BLOCK] NSURLConnection init 拦截: %@", request.URL);
        return nil;
    }

    return %orig;
}

%end

#pragma mark - NSURLRequest 兜底（更强）

%hook NSURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {

    if (shouldBlockURL(URL)) {
        NSLog(@"[BLOCK] NSURLRequest 拦截: %@", URL);
        return nil;
    }

    return %orig;
}

%end