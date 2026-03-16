#import <Foundation/Foundation.h>

// 正则模式：匹配 https:// 任意主机 /users? 后第一个参数为 column、aaid 或 extra_info
static NSString * const kURLPattern = @"https://.*/users\\?(column|aaid|extra_info)";

// 要删除的广告字段列表（位于 body.extra 中）
static NSArray<NSString *> *kAdFieldsToRemove = nil;

// 递归清理函数（如果需要根据值清理，可扩展此函数）
static void removeAdFieldsFromJSON(id jsonObject) {
    if ([jsonObject isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dict = (NSMutableDictionary *)jsonObject;
        // 如果当前字典是 "extra"，则删除指定的广告字段
        // 注意：这里假设 extra 是字典，我们无法直接知道哪个字典是 extra，因此采用更通用的方式：
        // 如果字典包含这些键中的任何一个，就尝试删除它们
        for (NSString *key in [dict allKeys]) {
            if ([kAdFieldsToRemove containsObject:key]) {
                [dict removeObjectForKey:key];
            } else {
                // 递归处理值
                removeAdFieldsFromJSON(dict[key]);
            }
        }
    } else if ([jsonObject isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *array = (NSMutableArray *)jsonObject;
        for (id item in array) {
            removeAdFieldsFromJSON(item);
        }
    }
    // 其他类型无需处理
}

%hook __NSCFURLSession   // 如果此私有类不生效，可尝试改为 __NSURLSessionLocal

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    // 初始化广告字段列表（只执行一次）
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAdFieldsToRemove = @[
            @"adms_operating",
            @"nearby_dating",
            @"adms_user",
            @"adms",
            @"adms_activity"
        ];
    });

    // 编译正则表达式（只执行一次）
    static NSRegularExpression *regex = nil;
    static dispatch_once_t regexToken;
    dispatch_once(&regexToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:kURLPattern
                                                          options:0
                                                            error:nil];
    });

    // 判断当前请求是否匹配目标 URL
    BOOL shouldModify = NO;
    NSString *urlString = request.URL.absoluteString;
    if (regex && urlString.length > 0) {
        NSUInteger matches = [regex numberOfMatchesInString:urlString
                                                     options:0
                                                       range:NSMakeRange(0, urlString.length)];
        shouldModify = (matches > 0);
    }

    if (shouldModify) {
        // 包装原始 completionHandler，拦截并修改响应数据
        return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSData *modifiedData = data;  // 默认使用原始数据

            if (data && !error) {
                NSError *jsonError = nil;
                // 使用 MutableContainers 以便直接修改内部字典/数组
                id jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
                if (!jsonError && jsonObj) {
                    // 递归删除广告字段
                    removeAdFieldsFromJSON(jsonObj);

                    // 重新序列化为 NSData
                    modifiedData = [NSJSONSerialization dataWithJSONObject:jsonObj
                                                                    options:0
                                                                      error:nil];
                    // 如果序列化失败，回退到原始数据
                    if (!modifiedData) {
                        modifiedData = data;
                    }
                }
            }

            // 调用原始的 completionHandler
            if (completionHandler) {
                completionHandler(modifiedData, response, error);
            }
        });
    } else {
        // 不匹配的 URL，直接传递原始 completionHandler
        return %orig(request, completionHandler);
    }
}

%end