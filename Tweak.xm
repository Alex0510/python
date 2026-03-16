#import <Foundation/Foundation.h>

%hook __NSCFURLSession  // 如果无效，请尝试改为 __NSURLSessionLocal

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request 
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    // 编译正则表达式（只执行一次）
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 模式说明：以 https:// 开头，任意主机，路径为 /users，后跟 ?，且第一个参数为 column、aaid 或 extra_info 之一
        // 注意：字符串中的反斜杠需要转义，所以 @"\\?" 表示正则中的 \?
        NSString *pattern = @"https://.*/users\\?(column|aaid|extra_info)";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:0
                                                            error:nil];
    });
    
    // 获取 URL 字符串并进行匹配
    NSString *urlString = request.URL.absoluteString;
    BOOL shouldModify = NO;
    if (regex && urlString.length > 0) {
        NSUInteger matches = [regex numberOfMatchesInString:urlString
                                                     options:0
                                                       range:NSMakeRange(0, urlString.length)];
        shouldModify = (matches > 0);
    }
    
    if (shouldModify) {
        return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSData *modifiedData = data;
            
            if (data && !error) {
                NSError *jsonError = nil;
                // 使用 MutableContainers 以便直接修改内部字典
                id jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
                if (!jsonError && [jsonObj isKindOfClass:[NSMutableDictionary class]]) {
                    NSMutableDictionary *rootDict = (NSMutableDictionary *)jsonObj;
                    
                    NSMutableDictionary *body = rootDict[@"body"];
                    if ([body isKindOfClass:[NSMutableDictionary class]]) {
                        NSMutableDictionary *extra = body[@"extra"];
                        if ([extra isKindOfClass:[NSMutableDictionary class]]) {
                            // 删除指定的广告字段
                            [extra removeObjectForKey:@"adms_operating"];
                            [extra removeObjectForKey:@"nearby_dating"];
                            [extra removeObjectForKey:@"adms_user"];
                            [extra removeObjectForKey:@"adms"];
                            [extra removeObjectForKey:@"adms_activity"];
                            
                            // 重新序列化为 JSON 数据
                            modifiedData = [NSJSONSerialization dataWithJSONObject:rootDict
                                                                            options:0
                                                                              error:nil];
                            if (!modifiedData) modifiedData = data; // 回退保护
                        }
                    }
                }
            }
            
            if (completionHandler) {
                completionHandler(modifiedData, response, error);
            }
        });
    } else {
        // 不匹配的 URL，原样传递
        return %orig(request, completionHandler);
    }
}

%end