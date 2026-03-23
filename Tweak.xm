#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 使用字符串动态获取类，避免编译时检查
static Class GetClass(const char* name) {
    return objc_getClass(name);
}

// ========== Hook Store 类 ==========
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

// ========== Hook LicenseValidator ==========
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

// ========== Hook Preferences ==========
%hook _TtC11EgernCommon11Preferences

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasProFeature {
    return YES;
}

%end

// ========== Hook KeyValueStore ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"]) {
        return @YES;
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

- (void)setObject:(id)object forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"]) {
        object = @YES;
    }
    %orig;
}

- (void)setBool:(BOOL)value forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"]) {
        value = YES;
    }
    %orig;
}

%end

// ========== Hook NSUserDefaults ==========
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

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key isEqualToString:@"ProUnlocked"]) {
        value = YES;
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"isProUnlocked"] || 
        [key isEqualToString:@"proUnlocked"] ||
        [key isEqualToString:@"ProUnlocked"]) {
        value = @YES;
    }
    %orig;
}

%end

// ========== Hook GetProViewController - 不直接使用self的方法 ==========
%hook _TtC5Egern20GetProViewController

- (void)viewDidLoad {
    %orig;
    
    // 使用objc_msgSend来调用方法，避免编译错误
    dispatch_async(dispatch_get_main_queue(), ^{
        void (*objc_msgSendTyped)(id, SEL) = (void*)objc_msgSend;
        SEL viewSel = sel_registerName("view");
        
        id view = objc_msgSendTyped(self, viewSel);
        if (view) {
            UILabel *label = [[UILabel alloc] init];
            label.text = @"✓ Pro Unlocked";
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor systemGreenColor];
            label.font = [UIFont boldSystemFontOfSize:16];
            label.frame = CGRectMake(0, 50, [view frame].size.width, 40);
            label.tag = 9999;
            [view addSubview:label];
            
            // 延迟返回
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                SEL dismissSel = sel_registerName("dismissViewControllerAnimated:completion:");
                void (*dismissMsgSend)(id, SEL, BOOL, id) = (void*)objc_msgSend;
                dismissMsgSend(self, dismissSel, YES, nil);
            });
        }
    });
}

%end

// ========== Hook SettingsViewController - 完全移除self调用 ==========
%hook _TtC5Egern22SettingsViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 使用KVC设置值
        @try {
            [self setValue:@YES forKey:@"isPro"];
            [self setValue:@YES forKey:@"proUnlocked"];
            [self setValue:@YES forKey:@"_isProUnlocked"];
        } @catch (NSException *e) {
            // ignore
        }
        
        // 刷新table view
        @try {
            UITableView *tableView = [self valueForKey:@"tableView"];
            [tableView reloadData];
        } @catch (NSException *e) {}
    });
}

%end

// ========== Hook NSURLSession 拦截验证请求 ==========
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    
    // 拦截许可证验证
    if ([url containsString:@"license"] || 
        [url containsString:@"verify"] ||
        [url containsString:@"validate"]) {
        
        NSDictionary *mockResponse = @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES,
            @"expires": @"2099-12-31"
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
    
    // 延迟执行，确保应用已启动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 设置 NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isProUnlocked"];
        [defaults setBool:YES forKey:@"proUnlocked"];
        [defaults setBool:YES forKey:@"ProUnlocked"];
        [defaults synchronize];
        
        // 尝试获取并设置 Store
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
                    NSLog(@"✓ Store updated");
                } @catch (NSException *e) {}
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
                    NSLog(@"✓ Preferences updated");
                } @catch (NSException *e) {}
            }
        }
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
    });
}