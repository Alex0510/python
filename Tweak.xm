#import <UIKit/UIKit.h>

#pragma mark - UILabel 文本修改

%hook UILabel

- (void)setText:(NSString *)text {

    if ([text containsString:@"Pro"] ||
        [text containsString:@"VIP"]) {

        NSLog(@"[Hook] UILabel 修改前: %@", text);

        text = @"已解锁"; // 你可以改成你想要的

        NSLog(@"[Hook] UILabel 修改后: %@", text);
    }

    %orig(text);
}

%end


#pragma mark - 网络数据拦截

%hook SessionDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {

    NSURLRequest *req = dataTask.currentRequest;
    NSString *url = req.URL.absoluteString;

    NSLog(@"[Hook] URL: %@", url);

    NSMutableData *mData = [data mutableCopy];

    if ([url containsString:@"api"] ||
        [url containsString:@"user"] ||
        [url containsString:@"vip"]) {

        NSError *error = nil;

        NSMutableDictionary *json =
        [NSJSONSerialization JSONObjectWithData:mData
                                        options:NSJSONReadingMutableContainers
                                          error:&error];

        if (!error && [json isKindOfClass:[NSDictionary class]]) {

            NSLog(@"[Hook] 原始JSON: %@", json);

            // 🔥 核心修改
            json[@"is_pro"] = @1;
            json[@"vip"] = @1;
            json[@"pro"] = @1;

            if (json[@"data"]) {
                NSMutableDictionary *dataDict = [json[@"data"] mutableCopy];
                dataDict[@"is_pro"] = @1;
                dataDict[@"vip"] = @1;
                json[@"data"] = dataDict;
            }

            NSData *newData =
            [NSJSONSerialization dataWithJSONObject:json
                                            options:0
                                              error:nil];

            if (newData) {
                mData = [newData mutableCopy];
                NSLog(@"[Hook] 修改成功");
            }
        }
    }

    %orig(session, dataTask, mData);
}

%end