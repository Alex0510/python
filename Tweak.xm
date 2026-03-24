#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ========== Store 类 - 核心 ==========
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

- (BOOL)hasPro {
    return YES;
}

- (BOOL)isPremium {
    return YES;
}

+ (id)shared {
    id instance = %orig;
    if (instance) {
        @try {
            [instance setValue:@YES forKey:@"_isProUnlocked"];
            [instance setValue:@YES forKey:@"isProUnlocked"];
            [instance setValue:@"pro" forKey:@"licenseType"];
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

- (BOOL)isLicenseValid {
    return YES;
}

- (id)licenseStatus {
    return @"active";
}

- (id)licenseType {
    return @"pro";
}

- (id)getLicenseInfo {
    return @{
        @"status": @"active",
        @"type": @"pro",
        @"expires": @"2099-12-31"
    };
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

- (id)proStatus {
    return @"active";
}

%end

// ========== KeyValueStore ==========
%hook _TtC5Egern13KeyValueStore

- (id)objectForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    
    // Pro状态相关的key
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"] ||
        [keyStr isEqualToString:@"pro_enabled"] ||
        [keyStr isEqualToString:@"isPro"]) {
        return @YES;
    }
    
    // 许可证相关的key
    if ([keyStr containsString:@"license"] || [keyStr containsString:@"License"]) {
        return @{
            @"status": @"active",
            @"type": @"pro",
            @"valid": @YES,
            @"expires": 4102444800  // 2099-12-31
        };
    }
    
    // 购买记录相关的key
    if ([keyStr containsString:@"purchase"] || 
        [keyStr containsString:@"receipt"] ||
        [keyStr containsString:@"subscription"]) {
        return @{
            @"productId": @"com.egern.pro",
            @"purchaseDate": @([[NSDate date] timeIntervalSince1970]),
            @"expiresDate": @4102444800,
            @"isActive": @YES
        };
    }
    
    return %orig;
}

- (BOOL)boolForKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr isEqualToString:@"isProUnlocked"] || 
        [keyStr isEqualToString:@"proUnlocked"] ||
        [keyStr isEqualToString:@"ProUnlocked"] ||
        [keyStr isEqualToString:@"pro_enabled"]) {
        return YES;
    }
    if ([keyStr containsString:@"license"] && [keyStr containsString:@"valid"]) {
        return YES;
    }
    return %orig;
}

- (void)setObject:(id)object forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || 
        [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"license"]) {
        // 拦截写入，确保Pro状态不被覆盖
        return;
    }
    %orig;
}

- (void)setBool:(BOOL)value forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || 
        [keyStr containsString:@"Pro"] ||
        [keyStr containsString:@"license"]) {
        // 拦截写入
        return;
    }
    %orig;
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
        [key isEqualToString:@"isPro"] ||
        [key containsString:@"pro_enabled"]) {
        return YES;
    }
    if ([key containsString:@"license"] && [key containsString:@"valid"]) {
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
            @"valid": @YES,
            @"expiresDate": @4102444800
        };
    }
    if ([key containsString:@"receipt"]) {
        return @{
            @"receipt": @"mock_receipt_data",
            @"status": @0
        };
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || 
        [key containsString:@"Pro"] ||
        [key containsString:@"license"]) {
        value = YES;
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || 
        [key containsString:@"Pro"] ||
        [key containsString:@"license"]) {
        value = @YES;
    }
    %orig;
}

%end

// ========== 拦截购买相关方法 ==========
%hook SKPaymentQueue

- (void)restoreCompletedTransactions {
    // 什么都不做，避免恢复购买检查
    return;
}

- (void)addPayment:(SKPayment *)payment {
    // 拦截购买请求
    return;
}

%end

%hook SKPaymentTransaction

- (SKPaymentTransactionState)transactionState {
    return SKPaymentTransactionStatePurchased;
}

- (id)transactionIdentifier {
    return @"com.egern.pro.mock.transaction";
}

%end

// ========== 构造函数 ==========
%ctor {
    NSLog(@"========================================");
    NSLog(@"Egern Pro Unlock v1.0 - Loading...");
    NSLog(@"========================================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 设置 NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"isProUnlocked"];
        [defaults setBool:YES forKey:@"proUnlocked"];
        [defaults setBool:YES forKey:@"ProUnlocked"];
        [defaults setBool:YES forKey:@"isPro"];
        [defaults setObject:@"active" forKey:@"licenseStatus"];
        [defaults setObject:@"pro" forKey:@"licenseType"];
        [defaults setObject:@4102444800 forKey:@"licenseExpires"];
        [defaults synchronize];
        
        // 设置 Store
        Class storeClass = objc_getClass("_TtC5Egern5Store");
        if (storeClass) {
            id store = nil;
            if ([storeClass respondsToSelector:@selector(shared)]) {
                store = [storeClass performSelector:@selector(shared)];
            } else if ([storeClass respondsToSelector:@selector(sharedInstance)]) {
                store = [storeClass performSelector:@selector(sharedInstance)];
            } else if ([storeClass respondsToSelector:@selector(defaultStore)]) {
                store = [storeClass performSelector:@selector(defaultStore)];
            }
            
            if (!store) {
                store = [[storeClass alloc] init];
            }
            
            if (store) {
                @try {
                    [store setValue:@YES forKey:@"_isProUnlocked"];
                    [store setValue:@YES forKey:@"isProUnlocked"];
                    [store setValue:@YES forKey:@"proUnlocked"];
                    [store setValue:@YES forKey:@"isPro"];
                    [store setValue:@"pro" forKey:@"licenseType"];
                    [store setValue:@"active" forKey:@"licenseStatus"];
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
                    [kv setValue:@"pro" forKey:@"licenseType"];
                    NSLog(@"✓ KeyValueStore configured");
                } @catch (NSException *e) {}
            }
        }
        
        // 设置 NSUserDefaults 的额外值
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setBool:YES forKey:@"com.egern.pro.unlocked"];
        [ud setBool:YES forKey:@"com.egern.premium"];
        [ud setObject:@"pro" forKey:@"com.egern.license.type"];
        [ud synchronize];
        
        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LicenseStatusChanged" object:nil];
        
        NSLog(@"========================================");
        NSLog(@"Egern Pro Unlock - Ready");
        NSLog(@"========================================");
    });
}