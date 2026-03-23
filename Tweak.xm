#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// ========== 关键类：Store (包含 _isProUnlocked) ==========
%hook _TtC5Egern5Store

// 返回Pro状态的方法
- (BOOL)_isProUnlocked {
    return YES;
}

- (BOOL)isProUnlocked {
    return YES;
}

- (BOOL)proUnlocked {
    return YES;
}

- (BOOL)isPro {
    return YES;
}

// 如果有获取Store实例的方法
+ (id)shared {
    id instance = %orig;
    if (instance) {
        @try {
            [instance setValue:@YES forKey:@"_isProUnlocked"];
            [instance setValue:@YES forKey:@"isProUnlocked"];
        } @catch (NSException *e) {}
    }
    return instance;
}

+ (id)sharedInstance {
    id instance = %orig;
    if (instance) {
        @try {
            [instance setValue:@YES forKey:@"_isProUnlocked"];
        } @catch (NSException *e) {}
    }
    return instance;
}

%end

// ========== 关键类：LicenseValidator ==========
%hook _TtC5Egern16LicenseValidator

- (BOOL)validateLicense {
    return YES;
}

- (id)verifyType {
    // 返回pro类型
    return @"pro";
}

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasValidLicense {
    return YES;
}

// 拦截初始化方法
- (id)init {
    self = %orig;
    if (self) {
        @try {
            [self setValue:@YES forKey:@"isPro"];
        } @catch (NSException *e) {}
    }
    return self;
}

%end

// ========== 关键类：Preferences ==========
%hook _TtC11EgernCommon11Preferences

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasProFeature {
    return YES;
}

- (BOOL)proEnabled {
    return YES;
}

+ (id)shared {
    id instance = %orig;
    if (instance) {
        @try {
            [instance setValue:@YES forKey:@"isPro"];
        } @catch (NSException *e) {}
    }
    return instance;
}

%end

// ========== 关键类：KeyValueStore (存储Pro状态) ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    // 拦截所有Pro相关的key
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"unlock"] || [keyStr containsString:@"Unlock"]) {
        if ([keyStr isEqualToString:@"isProUnlocked"] || 
            [keyStr isEqualToString:@"proUnlocked"] ||
            [keyStr isEqualToString:@"ProUnlocked"]) {
            return @YES;
        }
        // 如果是license key，返回有效的
        if ([keyStr containsString:@"license"] || [keyStr containsString:@"License"]) {
            return @"VALID_LICENSE_KEY";
        }
    }
    return %orig;
}

- (BOOL)boolForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"unlock"] || [keyStr containsString:@"Unlock"]) {
        if ([keyStr isEqualToString:@"isProUnlocked"] || 
            [keyStr isEqualToString:@"proUnlocked"]) {
            return YES;
        }
    }
    return %orig;
}

- (void)setObject:(id)object forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"unlock"] || [keyStr containsString:@"Unlock"]) {
        if ([keyStr isEqualToString:@"isProUnlocked"] || 
            [keyStr isEqualToString:@"proUnlocked"]) {
            object = @YES;
        }
    }
    %orig;
}

- (void)setBool:(BOOL)value forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"unlock"] || [keyStr containsString:@"Unlock"]) {
        if ([keyStr isEqualToString:@"isProUnlocked"] || 
            [keyStr isEqualToString:@"proUnlocked"]) {
            value = YES;
        }
    }
    %orig;
}

%end

// ========== 关键类：AppStorage ==========
%hook _TtC5Egern14AppStorage

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"]) {
        return @YES;
    }
    return %orig;
}

- (BOOL)boolForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"]) {
        return YES;
    }
    return %orig;
}

%end

// ========== NSUserDefaults ==========
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] ||
        [key containsString:@"unlock"] || [key containsString:@"Unlock"] ||
        [key containsString:@"license"] || [key containsString:@"License"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"] ||
            [key containsString:@"license"]) {
            return YES;
        }
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] ||
        [key containsString:@"unlock"] || [key containsString:@"Unlock"] ||
        [key containsString:@"license"] || [key containsString:@"License"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return @YES;
        }
        if ([key containsString:@"license"]) {
            return @{
                @"status": @"active",
                @"type": @"pro",
                @"valid": @YES,
                @"expires": @"2099-12-31"
            };
        }
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] ||
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        value = YES;
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] ||
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        value = @YES;
    }
    %orig;
}

%end

// ========== 拦截网络请求中的许可证验证 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    
    // 拦截所有可能的许可证验证请求
    if ([url containsString:@"license"] || 
        [url containsString:@"verify"] ||
        [url containsString:@"validate"] ||
        [url containsString:@"egern"] ||
        [url containsString:@"pro"] ||
        [url containsString:@"iap"] ||
        [url containsString:@"receipt"]) {
        
        // 返回成功的响应
        NSDictionary *mockResponse = @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES,
            @"isProUnlocked": @YES,
            @"expires": @"2099-12-31",
            @"message": @"License valid"
        };
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:mockResponse options:0 error:nil];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:@{@"Content-Type": @"application/json"}];
        
        if (completionHandler) {
            completionHandler(data, response, nil);
        }
        return nil;
    }
    
    return %orig;
}

%end

// ========== 初始化 ==========
%ctor {
    NSLog(@"========================================");
    NSLog(@"Egern Pro Unlock v1.0 - Loaded");
    NSLog(@"========================================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 设置 NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isProUnlocked"];
        [defaults setBool:YES forKey:@"proUnlocked"];
        [defaults setBool:YES forKey:@"ProUnlocked"];
        [defaults setObject:@"active" forKey:@"licenseStatus"];
        [defaults setObject:@"pro" forKey:@"licenseType"];
        [defaults synchronize];
        
        // 获取并设置 Store
        Class storeClass = objc_getClass("_TtC5Egern5Store");
        if (storeClass) {
            id store = nil;
            if ([storeClass respondsToSelector:@selector(shared)]) {
                store = [storeClass performSelector:@selector(shared)];
            } else if ([storeClass respondsToSelector:@selector(sharedInstance)]) {
                store = [storeClass performSelector:@selector(sharedInstance)];
            }
            if (store) {
                @try {
                    [store setValue:@YES forKey:@"_isProUnlocked"];
                    [store setValue:@YES forKey:@"isProUnlocked"];
                    [store setValue:@YES forKey:@"proUnlocked"];
                    [store setValue:@YES forKey:@"isPro"];
                    [store setValue:@"pro" forKey:@"licenseType"];
                    NSLog(@"✓ Store: Pro status set");
                } @catch (NSException *e) {
                    NSLog(@"Store error: %@", e);
                }
            } else {
                // 尝试创建实例
                store = [[storeClass alloc] init];
                if (store) {
                    [store setValue:@YES forKey:@"_isProUnlocked"];
                    NSLog(@"✓ Store instance created");
                }
            }
        }
        
        // 设置 Preferences
        Class prefsClass = objc_getClass("_TtC11EgernCommon11Preferences");
        if (prefsClass) {
            id prefs = nil;
            if ([prefsClass respondsToSelector:@selector(shared)]) {
                prefs = [prefsClass performSelector:@selector(shared)];
            }
            if (prefs) {
                @try {
                    [prefs setValue:@YES forKey:@"isPro"];
                    [prefs setValue:@YES forKey:@"proUnlocked"];
                    NSLog(@"✓ Preferences: Pro status set");
                } @catch (NSException *e) {}
            }
        }
        
        // 设置 KeyValueStore
        Class kvClass = objc_getClass("_TtC5Egern13KeyValueStore");
        if (kvClass) {
            id kv = nil;
            if ([kvClass respondsToSelector:@selector(shared)]) {
                kv = [kvClass performSelector:@selector(shared)];
            }
            if (kv) {
                @try {
                    [kv setValue:@YES forKey:@"isProUnlocked"];
                    [kv setValue:@YES forKey:@"proUnlocked"];
                    NSLog(@"✓ KeyValueStore: Pro status set");
                } @catch (NSException *e) {}
            }
        }
        
        // 发送通知，让应用知道Pro已解锁
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
        
        // 尝试刷新UI
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIViewController *rootVC = keyWindow.rootViewController;
        if (rootVC) {
            [rootVC setNeedsStatusBarAppearanceUpdate];
            [rootVC.view setNeedsLayout];
        }
        
        NSLog(@"========================================");
        NSLog(@"Egern Pro Unlock initialization complete");
        NSLog(@"========================================");
    });
}