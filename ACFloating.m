//
//  SandboxCleanerPlugin.m
//  SandboxCleanerPlugin
//

#import "SandboxCleanerPlugin.h"
#import <WebKit/WebKit.h>
#import <Security/Security.h>

@interface SandboxCleanerPlugin ()

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint initialTouchPoint;

@end

@implementation SandboxCleanerPlugin

+ (instancetype)sharedPlugin {
    static SandboxCleanerPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupFloatingButton];
    }
    return self;
}

#pragma mark - Setup

- (void)setupFloatingButton {
    // 创建悬浮按钮
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(0, 0, 60, 60);
    self.floatingButton.backgroundColor = [UIColor systemBlueColor];
    self.floatingButton.layer.cornerRadius = 30;
    self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.floatingButton.layer.shadowOpacity = 0.3;
    self.floatingButton.layer.shadowRadius = 4;
    
    // 设置图标
    [self.floatingButton setTitle:@"🧹" forState:UIControlStateNormal];
    self.floatingButton.titleLabel.font = [UIFont systemFontOfSize:24];
    
    // 添加长按菜单
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.floatingButton addGestureRecognizer:longPress];
    
    // 添加拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.floatingButton addGestureRecognizer:pan];
    
    // 添加点击事件（快速点击清理）
    [self.floatingButton addTarget:self action:@selector(quickClean) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showFloatingButton {
    UIWindow *keyWindow = [self getKeyWindow];
    if (keyWindow && ![self.floatingButton.superview isEqual:keyWindow]) {
        [keyWindow addSubview:self.floatingButton];
        // 默认位置在右下角
        self.floatingButton.frame = CGRectMake(keyWindow.bounds.size.width - 80, 
                                                keyWindow.bounds.size.height - 120, 
                                                60, 60);
        self.floatingButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    }
}

- (void)hideFloatingButton {
    [self.floatingButton removeFromSuperview];
}

#pragma mark - Clean Methods

// 快速清理（默认清理所有，不终止应用）
- (void)quickClean {
    [self cleanSandbox];
    [self cleanUserDefaults];
    [self cleanCookiesAndWebKit];
    [self showAlertWithTitle:@"清理完成" message:@"已清理沙盒、偏好设置和Cookie"];
}

// 1. 清理 App 沙盒 (Documents / Caches / tmp)
- (void)cleanSandbox {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 清理 Documents (保留必要文件可在此过滤)
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [self deleteContentsOfDirectory:documentsPath fileManager:fm];
    
    // 清理 Caches
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    [self deleteContentsOfDirectory:cachesPath fileManager:fm];
    
    // 清理 tmp
    NSString *tmpPath = NSTemporaryDirectory();
    [self deleteContentsOfDirectory:tmpPath fileManager:fm];
}

- (void)deleteContentsOfDirectory:(NSString *)path fileManager:(NSFileManager *)fm {
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:&error];
    for (NSString *item in contents) {
        NSString *itemPath = [path stringByAppendingPathComponent:item];
        [fm removeItemAtPath:itemPath error:nil];
    }
}

// 2. 清理 NSUserDefaults
- (void)cleanUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 3. 清理 Cookie / WebKit
- (void)cleanCookiesAndWebKit {
    // 清理 HTTP Cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        [cookieStorage deleteCookie:cookie];
    }
    
    // 清理 WebKit 数据
    NSSet *websiteDataTypes = [NSSet setWithArray:@[
        WKWebsiteDataTypeMemoryCache,
        WKWebsiteDataTypeDiskCache,
        WKWebsiteDataTypeOfflineWebApplicationCache,
        WKWebsiteDataTypeCookies,
        WKWebsiteDataTypeLocalStorage,
        WKWebsiteDataTypeSessionStorage,
        WKWebsiteDataTypeIndexedDBDatabases,
        WKWebsiteDataTypeWebSQLDatabases
    ]];
    
    NSDate *sinceDate = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes 
                                               modifiedSince:sinceDate 
                                           completionHandler:^{
        NSLog(@"WebKit 数据清理完成");
    }];
}

// 4. 清理 Keychain
- (void)cleanKeychain {
    // 获取所有 Keychain 条目并删除
    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecReturnAttributes: @YES,
        (id)kSecMatchLimit: (id)kSecMatchLimitAll
    };
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result != NULL) {
        NSArray *items = (__bridge_transfer NSArray *)result;
        for (NSDictionary *item in items) {
            NSMutableDictionary *deleteQuery = [NSMutableDictionary dictionary];
            deleteQuery[(id)kSecClass] = (id)kSecClassGenericPassword;
            
            if (item[(id)kSecAttrService]) {
                deleteQuery[(id)kSecAttrService] = item[(id)kSecAttrService];
            }
            if (item[(id)kSecAttrAccount]) {
                deleteQuery[(id)kSecAttrAccount] = item[(id)kSecAttrAccount];
            }
            
            SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
        }
    }
    
    // 清理其他 Keychain 类型（可选）
    NSArray *secClasses = @[(id)kSecClassInternetPassword, (id)kSecClassCertificate, 
                            (id)kSecClassKey, (id)kSecClassIdentity];
    for (id secClass in secClasses) {
        NSDictionary *deleteQuery = @{(id)kSecClass: secClass};
        SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    }
    
    NSLog(@"Keychain 清理完成");
}

// 5. 一键 Kill App
- (void)killApp {
    // 平滑退出应用
    [UIView animateWithDuration:0.3 animations:^{
        UIWindow *window = [self getKeyWindow];
        window.alpha = 0;
    } completion:^(BOOL finished) {
        exit(0);
    }];
}

#pragma mark - UI Actions

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self showFullCleanMenu];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    CGPoint translation = [gesture translationInView:button.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.initialTouchPoint = button.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        button.center = CGPointMake(self.initialTouchPoint.x + translation.x,
                                     self.initialTouchPoint.y + translation.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
        // 可添加边界吸附逻辑
        [self snapToEdge];
    }
}

- (void)snapToEdge {
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow) return;
    
    CGRect screenBounds = keyWindow.bounds;
    CGFloat centerX = self.floatingButton.center.x;
    CGFloat targetX = (centerX < screenBounds.size.width / 2) ? 40 : screenBounds.size.width - 40;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.center = CGPointMake(targetX, self.floatingButton.center.y);
    }];
}

- (void)showFullCleanMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"沙盒清理工具"
                                                                   message:@"选择要执行的操作"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 清理所有（不含Kill）
    UIAlertAction *cleanAllAction = [UIAlertAction actionWithTitle:@"🧹 清理所有（沙盒/偏好/Cookie）" 
                                                             style:UIAlertActionStyleDefault 
                                                           handler:^(UIAlertAction * _Nonnull action) {
        [self quickClean];
    }];
    
    // 清理 Keychain
    UIAlertAction *cleanKeychainAction = [UIAlertAction actionWithTitle:@"🔑 清理 Keychain" 
                                                                  style:UIAlertActionStyleDefault 
                                                                handler:^(UIAlertAction * _Nonnull action) {
        [self cleanKeychain];
        [self showAlertWithTitle:@"完成" message:@"Keychain 已清理"];
    }];
    
    // 单独清理沙盒
    UIAlertAction *cleanSandboxAction = [UIAlertAction actionWithTitle:@"📁 仅清理沙盒 (Documents/Caches/tmp)" 
                                                                 style:UIAlertActionStyleDefault 
                                                               handler:^(UIAlertAction * _Nonnull action) {
        [self cleanSandbox];
        [self showAlertWithTitle:@"完成" message:@"沙盒已清理"];
    }];
    
    // 单独清理偏好设置
    UIAlertAction *cleanPrefsAction = [UIAlertAction actionWithTitle:@"⚙️ 仅清理 NSUserDefaults" 
                                                               style:UIAlertActionStyleDefault 
                                                             handler:^(UIAlertAction * _Nonnull action) {
        [self cleanUserDefaults];
        [self showAlertWithTitle:@"完成" message:@"偏好设置已清理"];
    }];
    
    // 单独清理Cookie/WebKit
    UIAlertAction *cleanWebAction = [UIAlertAction actionWithTitle:@"🌐 仅清理 Cookie / WebKit" 
                                                             style:UIAlertActionStyleDefault 
                                                           handler:^(UIAlertAction * _Nonnull action) {
        [self cleanCookiesAndWebKit];
        [self showAlertWithTitle:@"完成" message:@"Cookie和WebKit数据已清理"];
    }];
    
    // 一键 Kill App
    UIAlertAction *killAction = [UIAlertAction actionWithTitle:@"💀 一键 Kill App" 
                                                         style:UIAlertActionStyleDestructive 
                                                       handler:^(UIAlertAction * _Nonnull action) {
        [self killApp];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:cleanAllAction];
    [alert addAction:cleanKeychainAction];
    [alert addAction:cleanSandboxAction];
    [alert addAction:cleanPrefsAction];
    [alert addAction:cleanWebAction];
    [alert addAction:killAction];
    [alert addAction:cancelAction];
    
    UIViewController *rootVC = [self getRootViewController];
    if (rootVC) {
        // iPad 支持
        if (alert.popoverPresentationController) {
            alert.popoverPresentationController.sourceView = self.floatingButton;
            alert.popoverPresentationController.sourceRect = self.floatingButton.bounds;
        }
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Helper

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *rootVC = [self getRootViewController];
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (UIViewController *)getRootViewController {
    UIWindow *window = [self getKeyWindow];
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    return rootVC;
}

@end