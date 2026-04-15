#import "ACManager.h"
#import <Security/Security.h>
#import <WebKit/WebKit.h>

@implementation ACManager

+ (instancetype)shared {
    static ACManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [ACManager new];
    });
    return m;
}

#pragma mark - 当前 App

- (NSString *)currentBundle {
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark - Keychain 清理（调试用途）

- (void)clearKeychain {
    NSArray *classes = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];

    for (id cls in classes) {
        NSDictionary *query = @{(__bridge id)kSecClass: cls};
        SecItemDelete((__bridge CFDictionaryRef)query);
    }

    NSLog(@"[AllClean] Keychain cleared");
}

#pragma mark - 沙盒清理

- (void)clearSandbox {

    NSString *home = NSHomeDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];

    NSArray *dirs = @[@"Documents", @"Library", @"tmp"];

    for (NSString *dir in dirs) {
        NSString *path = [home stringByAppendingPathComponent:dir];
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];

        for (NSString *file in files) {
            NSString *full = [path stringByAppendingPathComponent:file];
            [fm removeItemAtPath:full error:nil];
        }
    }

    NSLog(@"[AllClean] Sandbox cleared");
}

#pragma mark - Preferences

- (void)clearPreferences {

    NSString *bundle = [self currentBundle];

    NSString *pref = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", bundle];

    [[NSFileManager defaultManager] removeItemAtPath:pref error:nil];

    NSLog(@"[AllClean] Preferences cleared");
}

#pragma mark - Web 数据

- (void)clearWeb {

    NSSet *types = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];

    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:types
                                              modifiedSince:date
                                          completionHandler:^{
        NSLog(@"[AllClean] Web data cleared");
    }];
}

#pragma mark - URLCache

- (void)clearCache {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSLog(@"[AllClean] URLCache cleared");
}

#pragma mark - 主入口

- (void)runFullClean {

    NSLog(@"======== AllClean START ========");

    [self clearKeychain];
    [self clearSandbox];
    [self clearPreferences];
    [self clearWeb];
    [self clearCache];

    NSLog(@"======== AllClean DONE ========");

    exit(0);
}

@end
