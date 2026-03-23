#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ========== Store 类 ==========
%hook _TtC5Egern5Store

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

%end

// ========== LicenseValidator ==========
%hook _TtC5Egern16LicenseValidator

- (BOOL)validateLicense {
    return YES;
}

- (id)verifyType {
    return @"pro";
}

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasValidLicense {
    return YES;
}

%end

// ========== Preferences ==========
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

%end

// ========== KeyValueStore ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"]) {
        return @YES;
    }
    if ([keyStr containsString:@"license"] || [keyStr containsString:@"License"]) {
        return @"VALID_LICENSE";
    }
    return %orig;
}

- (BOOL)boolForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"]) {
        return YES;
    }
    return %orig;
}

%end

// ========== AppStorage ==========
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
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key isEqualToString:@"ProUnlocked"]) {
        return YES;
    }
    if ([key containsString:@"license"]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key isEqualToString:@"ProUnlocked"]) {
        return @YES;
    }
    if ([key containsString:@"license"]) {
        return @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES
        };
    }
    return %orig;
}

%end

// ========== NSURLSession 拦截验证请求 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    
    if ([url containsString:@"license"] || 
        [url containsString:@"verify"] ||
        [url containsString:@"validate"] ||
        [url containsString:@"receipt"]) {
        
        NSDictionary *mockResponse = @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES,
            @"isProUnlocked": @YES
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

// ========== 获取当前活动的场景窗口 (修复iOS 13+的keyWindow问题) ==========
static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
        return [UIApplication sharedApplication].windows.firstObject;
    } else {
        return [UIApplication sharedApplication].keyWindow;
    }
}

// ========== 构造函数 ==========
%ctor {
    NSLog(@"=== Egern Pro Unlock Loaded ===");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 设置 NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isProUnlocked"];
        [defaults setBool:YES forKey:@"proUnlocked"];
        [defaults setBool:YES forKey:@"ProUnlocked"];
        [defaults synchronize];
        
        // 使用objc_msgSend设置 Store
        Class storeClass = objc_getClass("_TtC5Egern5Store");
        if (storeClass) {
            id store = nil;
            if ([storeClass respondsToSelector:@selector(shared)]) {
                store = [storeClass performSelector:@selector(shared)];
            }
            if (store) {
                @try {
                    [store setValue:@YES forKey:@"_isProUnlocked"];
                    [store setValue:@YES forKey:@"isProUnlocked"];
                    [store setValue:@YES forKey:@"proUnlocked"];
                    [store setValue:@YES forKey:@"isPro"];
                    NSLog(@"✓ Store set");
                } @catch (NSException *e) {
                    NSLog(@"Store error: %@", e);
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
                    NSLog(@"✓ Preferences set");
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
                    NSLog(@"✓ KeyValueStore set");
                } @catch (NSException *e) {}
            }
        }
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
        
        // 刷新UI
        UIWindow *keyWindow = getKeyWindow();
        if (keyWindow) {
            [keyWindow setNeedsLayout];
            [keyWindow layoutIfNeeded];
            UIViewController *rootVC = keyWindow.rootViewController;
            if (rootVC) {
                [rootVC setNeedsStatusBarAppearanceUpdate];
                [rootVC.view setNeedsLayout];
            }
        }
        
        NSLog(@"=== Egern Pro Unlock Initialized ===");
    });
}