#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>

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
        [keyStr isEqualToString:@"proUnlocked"]) {
        return YES;
    }
    return %orig;
}

- (void)setObject:(id)object forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"license"]) {
        return;
    }
    %orig;
}

- (void)setBool:(BOOL)value forKey:(id)key {
    NSString *keyStr = [NSString stringWithFormat:@"%@", key];
    if ([keyStr containsString:@"pro"] || [keyStr containsString:@"license"]) {
        return;
    }
    %orig;
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
            @"valid": @YES
        };
    }
    return %orig;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"license"]) {
        value = YES;
    }
    %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"license"]) {
        value = @YES;
    }
    %orig;
}

%end

// ========== 构造函数 ==========
%ctor {
    NSLog(@"=== Egern Pro Unlock Loaded ===");
    
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
        
        NSLog(@"=== Egern Pro Unlock Ready ===");
    });
}