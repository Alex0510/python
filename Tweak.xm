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

+ (id)shared {
    id instance = %orig;
    if (instance) {
        @try {
            [instance setValue:@YES forKey:@"_isProUnlocked"];
        } @catch (NSException *e) {}
    }
    return instance;
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
        return @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES
        };
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
    if ([keyStr containsString:@"license"]) {
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
        [key isEqualToString:@"ProUnlocked"] ||
        [key containsString:@"license"]) {
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

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key containsString:@"license"]) {
        value = YES;
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key containsString:@"license"]) {
        value = @YES;
    }
    %orig;
}

%end

// ========== ProLabel - 让Pro标签始终显示 ==========
%hook _TtC5Egern8ProLabel

- (void)layoutSubviews {
    %orig;
    // 确保ProLabel可见
    [self setHidden:NO];
}

- (struct CGSize)sizeThatFits:(struct CGSize)size {
    struct CGSize original = %orig;
    // 确保标签不会被压缩
    if (original.width < 30) {
        original.width = 50;
    }
    return original;
}

- (struct CGSize)intrinsicContentSize {
    struct CGSize original = %orig;
    if (original.width < 30) {
        original.width = 50;
    }
    return original;
}

- (void)traitCollectionDidChange:(id)previousTraitCollection {
    %orig;
    // 确保渐变层正确显示
    [self setNeedsDisplay];
}

%end

// ========== GetProViewController - 隐藏购买界面 ==========
%hook _TtC5Egern20GetProViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 查找并隐藏所有按钮
        UIView *view = [self valueForKey:@"view"];
        if (view) {
            for (UIView *subview in view.subviews) {
                if ([subview isKindOfClass:[UIButton class]]) {
                    subview.hidden = YES;
                }
            }
            
            // 显示已解锁提示
            UILabel *unlockedLabel = [[UILabel alloc] init];
            unlockedLabel.text = @"✓ Pro Features Unlocked";
            unlockedLabel.textAlignment = NSTextAlignmentCenter;
            unlockedLabel.textColor = [UIColor systemGreenColor];
            unlockedLabel.font = [UIFont boldSystemFontOfSize:20];
            unlockedLabel.frame = CGRectMake(0, 150, view.frame.size.width, 50);
            [view addSubview:unlockedLabel];
        }
        
        // 自动返回
        [self performSelector:@selector(dismissViewControllerAnimated:completion:) withObject:@YES afterDelay:1.5];
    });
}

%end

// ========== SettingsViewController - 确保Pro设置可见 ==========
%hook _TtC5Egern22SettingsViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 刷新表格以显示Pro选项
        UITableView *tableView = [self valueForKey:@"tableView"];
        if (tableView) {
            [tableView reloadData];
        }
    });
}

%end

// ========== NSURLSession 拦截验证请求 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    
    // 拦截所有许可证验证请求
    if ([url containsString:@"license"] || 
        [url containsString:@"verify"] ||
        [url containsString:@"validate"] ||
        [url containsString:@"receipt"] ||
        [url containsString:@"iap"] ||
        [url containsString:@"purchase"] ||
        [url containsString:@"subscription"]) {
        
        NSDictionary *mockResponse = @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES,
            @"isProUnlocked": @YES,
            @"expires": @"2099-12-31",
            @"productId": @"com.egern.pro"
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

// ========== 获取窗口的辅助函数 ==========
static UIWindow *getFirstWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    return window;
                }
            }
        }
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

// ========== 构造函数 ==========
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
        
        // 设置 Store
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
                    [store setValue:@"pro" forKey:@"licenseType"];
                    NSLog(@"✓ Store configured");
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
                    NSLog(@"✓ Preferences configured");
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
                    NSLog(@"✓ KeyValueStore configured");
                } @catch (NSException *e) {}
            }
        }
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
        
        // 刷新UI
        UIWindow *window = getFirstWindow();
        if (window) {
            [window setNeedsLayout];
            UIView *rootView = window.rootViewController.view;
            if (rootView) {
                [rootView setNeedsLayout];
                [rootView setNeedsDisplay];
            }
        }
        
        NSLog(@"========================================");
        NSLog(@"Egern Pro Unlock initialization complete");
        NSLog(@"========================================");
    });
}