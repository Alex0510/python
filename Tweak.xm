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

%end

// ========== Preferences ==========
%hook _TtC11EgernCommon11Preferences

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasProFeature {
    return YES;
}

%end

// ========== KeyValueStore ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"]) {
        return @YES;
    }
    return %orig;
}

- (BOOL)boolForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"]) {
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
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key isEqualToString:@"ProUnlocked"]) {
        return @YES;
    }
    return %orig;
}

%end

// ========== GetProViewController - 只hook基本方法，不访问view ==========
%hook _TtC5Egern20GetProViewController

- (void)viewDidLoad {
    %orig;
    // 不需要添加额外UI，避免编译问题
}

%end

// ========== SettingsViewController - 只hook基本方法 ==========
%hook _TtC5Egern22SettingsViewController

- (void)viewDidLoad {
    %orig;
    // 不添加额外代码，避免编译问题
}

%end

// ========== NSURLSession 拦截验证请求 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    
    if ([url containsString:@"license"] || 
        [url containsString:@"verify"] ||
        [url containsString:@"validate"] ||
        [url containsString:@"egern"]) {
        
        NSDictionary *mockResponse = @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES
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

// ========== 构造函数 ==========
%ctor {
    NSLog(@"=== Egern Pro Unlock Loaded ===");
    
    // 设置 NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isProUnlocked"];
    [defaults setBool:YES forKey:@"proUnlocked"];
    [defaults setBool:YES forKey:@"ProUnlocked"];
    [defaults synchronize];
    
    // 尝试设置 Store
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
                NSLog(@"✓ Store updated");
            } @catch (NSException *e) {
                NSLog(@"Store update failed: %@", e);
            }
        }
    }
    
    // 尝试设置 Preferences
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
                NSLog(@"✓ Preferences updated");
            } @catch (NSException *e) {
                NSLog(@"Preferences update failed: %@", e);
            }
        }
    }
    
    // 尝试设置 KeyValueStore
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
                NSLog(@"✓ KeyValueStore updated");
            } @catch (NSException *e) {}
        }
    }
}