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

// ========== LicenseValidator 类 ==========
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

// ========== KeyValueStore 类 ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"Pro"] || 
        [keyStr containsString:@"unlock"] || [keyStr containsString:@"Unlock"]) {
        if ([keyStr isEqualToString:@"isProUnlocked"] || 
            [keyStr isEqualToString:@"proUnlocked"]) {
            return @YES;
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

%end

// ========== NSUserDefaults ==========
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return YES;
        }
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return @YES;
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
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"]) {
            value = @YES;
        }
    }
    %orig;
}

%end

// ========== Preferences 类 ==========
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

// ========== GetProViewController - 使用performSelector避免编译错误 ==========
%hook _TtC5Egern20GetProViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 使用performSelector获取view
        UIView *view = [self performSelector:@selector(view)];
        if (view) {
            UILabel *unlockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, view.frame.size.width, 50)];
            unlockedLabel.text = @"✓ Pro Features Unlocked";
            unlockedLabel.textAlignment = NSTextAlignmentCenter;
            unlockedLabel.textColor = [UIColor systemGreenColor];
            unlockedLabel.font = [UIFont boldSystemFontOfSize:18];
            unlockedLabel.tag = 9999;
            [view addSubview:unlockedLabel];
            
            // 隐藏购买按钮
            [self hidePurchaseButtons];
            
            // 自动返回
            [self performSelector:@selector(dismissViewControllerAnimated:completion:) withObject:@YES afterDelay:1.0];
        }
    });
}

- (void)hidePurchaseButtons {
    UIView *view = [self performSelector:@selector(view)];
    if (view) {
        for (UIView *subview in view.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subview;
                NSString *title = button.titleLabel.text;
                if (title && ([title containsString:@"Unlock"] || 
                    [title containsString:@"Purchase"] ||
                    [title containsString:@"Buy"] ||
                    [title containsString:@"Restore"])) {
                    button.hidden = YES;
                    button.enabled = NO;
                }
            }
        }
    }
}

%end

// ========== SettingsViewController - 移除有问题的代码 ==========
%hook _TtC5Egern22SettingsViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 使用KVC设置可能的pro属性
        @try {
            [self setValue:@YES forKey:@"isPro"];
            [self setValue:@YES forKey:@"proUnlocked"];
            [self setValue:@YES forKey:@"_isProUnlocked"];
        } @catch (NSException *e) {
            // 忽略错误
        }
        
        // 刷新表格
        UITableView *tableView = [self valueForKey:@"tableView"];
        if (tableView) {
            [tableView reloadData];
        }
    });
}

%end

// ========== 拦截许可证验证请求 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    
    if ([urlString containsString:@"license"] || 
        [urlString containsString:@"verify"] ||
        [urlString containsString:@"validate"] ||
        [urlString containsString:@"pro"] ||
        [urlString containsString:@"unlock"]) {
        
        NSData *mockData = [@"{\"status\":\"active\",\"type\":\"pro\",\"valid\":true,\"expires\":null}" dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *mockResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                                      statusCode:200 
                                                                     HTTPVersion:@"HTTP/1.1" 
                                                                    headerFields:@{@"Content-Type": @"application/json"}];
        if (completionHandler) {
            completionHandler(mockData, mockResponse, nil);
        }
        return nil;
    }
    
    return %orig;
}

%end

// ========== 拦截可能的Pro功能检查方法 ==========
%hook UIApplication

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // 允许所有Pro功能
    return YES;
}

%end

// ========== 初始化 ==========
%ctor {
    NSLog(@"========================================");
    NSLog(@"Egern Pro Unlock loaded successfully!");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isProUnlocked"];
        [defaults setBool:YES forKey:@"proUnlocked"];
        [defaults setBool:YES forKey:@"ProUnlocked"];
        [defaults synchronize];
        
        // 尝试直接设置Store
        Class storeClass = NSClassFromString(@"_TtC5Egern5Store");
        if (storeClass) {
            id storeInstance = nil;
            if ([storeClass respondsToSelector:@selector(shared)]) {
                storeInstance = [storeClass performSelector:@selector(shared)];
            } else if ([storeClass respondsToSelector:@selector(sharedInstance)]) {
                storeInstance = [storeClass performSelector:@selector(sharedInstance)];
            }
            if (storeInstance) {
                @try {
                    [storeInstance setValue:@YES forKey:@"_isProUnlocked"];
                    [storeInstance setValue:@YES forKey:@"isProUnlocked"];
                    [storeInstance setValue:@YES forKey:@"proUnlocked"];
                    [storeInstance setValue:@YES forKey:@"isPro"];
                    NSLog(@"✓ Store pro status set");
                } @catch (NSException *e) {
                    NSLog(@"Failed to set store: %@", e);
                }
            }
        }
        
        // 尝试设置Preferences
        Class prefsClass = NSClassFromString(@"_TtC11EgernCommon11Preferences");
        if (prefsClass) {
            id prefsInstance = nil;
            if ([prefsClass respondsToSelector:@selector(shared)]) {
                prefsInstance = [prefsClass performSelector:@selector(shared)];
            } else if ([prefsClass respondsToSelector:@selector(standardUserDefaults)]) {
                prefsInstance = [prefsClass performSelector:@selector(standardUserDefaults)];
            }
            if (prefsInstance) {
                @try {
                    [prefsInstance setValue:@YES forKey:@"isPro"];
                    [prefsInstance setValue:@YES forKey:@"proUnlocked"];
                    NSLog(@"✓ Preferences pro status set");
                } @catch (NSException *e) {
                    NSLog(@"Failed to set preferences: %@", e);
                }
            }
        }
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
    });
}