//
//  AppCleanerPlugin.m
//  AppCleaner
//

#import "AppCleanerPlugin.h"
#import <WebKit/WebKit.h>
#import <Security/Security.h>

@interface AppCleanerPlugin ()

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint initialTouchPoint;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, assign) BOOL isMenuShowing;

@end

@implementation AppCleanerPlugin

#pragma mark - Singleton

+ (instancetype)sharedPlugin {
    static AppCleanerPlugin *instance = nil;
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
        self.isMenuShowing = NO;
    }
    return self;
}

#pragma mark - Setup

- (void)setupFloatingButton {
    // 创建悬浮按钮
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(0, 0, 50, 50);
    self.floatingButton.backgroundColor = [UIColor systemRedColor];
    self.floatingButton.layer.cornerRadius = 25;
    self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.floatingButton.layer.shadowOpacity = 0.4;
    self.floatingButton.layer.shadowRadius = 4;
    
    // 设置图标
    [self.floatingButton setTitle:@"🧹" forState:UIControlStateNormal];
    self.floatingButton.titleLabel.font = [UIFont systemFontOfSize:24];
    
    // 添加手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] 
                                                 initWithTarget:self 
                                                 action:@selector(showCleanMenu)];
    longPress.minimumPressDuration = 0.3;
    [self.floatingButton addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
                                    initWithTarget:self 
                                    action:@selector(handlePan:)];
    [self.floatingButton addGestureRecognizer:pan];
    
    // 单击快速清理
    [self.floatingButton addTarget:self 
                            action:@selector(quickClean) 
                  forControlEvents:UIControlEventTouchUpInside];
}

- (void)showFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow && ![self.floatingButton.superview isEqual:keyWindow]) {
            [keyWindow addSubview:self.floatingButton];
            
            // 默认位置在屏幕右下角
            CGFloat x = keyWindow.bounds.size.width - 60;
            CGFloat y = keyWindow.bounds.size.height - 100;
            self.floatingButton.frame = CGRectMake(x, y, 50, 50);
            self.floatingButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
                                                    UIViewAutoresizingFlexibleTopMargin;
            
            // 添加入场动画
            self.floatingButton.alpha = 0;
            self.floatingButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            [UIView animateWithDuration:0.4 
                                  delay:0 
                 usingSpringWithDamping:0.6 
                  initialSpringVelocity:0.8 
                                options:UIViewAnimationOptionCurveEaseOut 
                             animations:^{
                self.floatingButton.alpha = 0.9;
                self.floatingButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    });
}

- (void)hideFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            self.floatingButton.alpha = 0;
        } completion:^(BOOL finished) {
            [self.floatingButton removeFromSuperview];
            [self hideMenu];
        }];
    });
}

#pragma mark - Gesture Handlers

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    CGPoint translation = [gesture translationInView:button.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.initialTouchPoint = button.center;
        
        // 拖拽时隐藏菜单
        if (self.isMenuShowing) {
            [self hideMenu];
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.initialTouchPoint.x + translation.x,
                                        self.initialTouchPoint.y + translation.y);
        
        // 边界限制
        UIWindow *keyWindow = [self getKeyWindow];
        CGFloat minX = 25;
        CGFloat maxX = keyWindow.bounds.size.width - 25;
        CGFloat minY = 50;
        CGFloat maxY = keyWindow.bounds.size.height - 50;
        
        newCenter.x = MAX(minX, MIN(maxX, newCenter.x));
        newCenter.y = MAX(minY, MIN(maxY, newCenter.y));
        
        button.center = newCenter;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
        [self snapToEdge];
    }
}

- (void)snapToEdge {
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow) return;
    
    CGRect screenBounds = keyWindow.bounds;
    CGFloat centerX = self.floatingButton.center.x;
    CGFloat targetX = (centerX < screenBounds.size.width / 2) ? 35 : screenBounds.size.width - 35;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.center = CGPointMake(targetX, self.floatingButton.center.y);
    }];
}

#pragma mark - Clean Methods

// 快速清理（最常用）
- (void)quickClean {
    [self cleanSandbox];
    [self cleanUserDefaults];
    [self cleanCookiesAndWebKit];
    [self showAlert:@"✅ 快速清理完成" 
           message:@"已清理沙盒、偏好设置和Cookie"];
}

// 清理所有数据
- (void)cleanAllData {
    [self cleanSandbox];
    [self cleanUserDefaults];
    [self cleanCookiesAndWebKit];
    [self cleanKeychain];
    [self showAlert:@"✨ 完全清理完成" 
           message:@"已清理所有数据，即将退出App"];
    
    // 清理完成后延迟退出
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitApp];
    });
}

// 1. 清理沙盒 - 清除当前App的 Documents/Caches/tmp
- (void)cleanSandbox {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 获取当前App的沙盒路径
    NSString *homePath = NSHomeDirectory();
    
    // 清理 Documents
    NSString *documentsPath = [homePath stringByAppendingPathComponent:@"Documents"];
    if ([fm fileExistsAtPath:documentsPath]) {
        NSArray *documents = [fm contentsOfDirectoryAtPath:documentsPath error:&error];
        for (NSString *item in documents) {
            if (![item isEqualToString:@"."] && ![item isEqualToString:@".."]) {
                NSString *itemPath = [documentsPath stringByAppendingPathComponent:item];
                [fm removeItemAtPath:itemPath error:nil];
            }
        }
        NSLog(@"[AppCleaner] Documents 清理完成");
    }
    
    // 清理 Library/Caches
    NSString *cachesPath = [homePath stringByAppendingPathComponent:@"Library/Caches"];
    if ([fm fileExistsAtPath:cachesPath]) {
        NSArray *caches = [fm contentsOfDirectoryAtPath:cachesPath error:&error];
        for (NSString *item in caches) {
            if (![item isEqualToString:@"."] && ![item isEqualToString:@".."]) {
                NSString *itemPath = [cachesPath stringByAppendingPathComponent:item];
                [fm removeItemAtPath:itemPath error:nil];
            }
        }
        NSLog(@"[AppCleaner] Caches 清理完成");
    }
    
    // 清理 tmp
    NSString *tmpPath = NSTemporaryDirectory();
    if ([fm fileExistsAtPath:tmpPath]) {
        NSArray *tmpFiles = [fm contentsOfDirectoryAtPath:tmpPath error:&error];
        for (NSString *item in tmpFiles) {
            if (![item isEqualToString:@"."] && ![item isEqualToString:@".."]) {
                NSString *itemPath = [tmpPath stringByAppendingPathComponent:item];
                [fm removeItemAtPath:itemPath error:nil];
            }
        }
        NSLog(@"[AppCleaner] tmp 清理完成");
    }
}

// 2. 清理当前App的 NSUserDefaults
- (void)cleanUserDefaults {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[AppCleaner] NSUserDefaults 清理完成: %@", bundleIdentifier);
    }
}

// 3. 清理当前App的 Cookie 和 WebKit 数据
- (void)cleanCookiesAndWebKit {
    // 清理 HTTP Cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        [cookieStorage deleteCookie:cookie];
    }
    
    // 清理 WebKit 数据
    if (@available(iOS 9.0, *)) {
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
            NSLog(@"[AppCleaner] WebKit 数据清理完成");
        }];
    }
    
    NSLog(@"[AppCleaner] Cookie 清理完成");
}

// 4. 清理当前App的 Keychain 数据
- (void)cleanKeychain {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    // 查询当前App的所有Keychain条目
    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: bundleIdentifier ?: @"",
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
        NSLog(@"[AppCleaner] Keychain清理了 %lu 条记录", (unsigned long)items.count);
    }
    
    // 清理其他类型的Keychain数据
    NSArray *secClasses = @[(id)kSecClassInternetPassword, 
                            (id)kSecClassCertificate, 
                            (id)kSecClassKey, 
                            (id)kSecClassIdentity];
    for (id secClass in secClasses) {
        NSDictionary *deleteQuery = @{
            (id)kSecClass: secClass,
            (id)kSecAttrService: bundleIdentifier ?: @""
        };
        SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    }
    
    NSLog(@"[AppCleaner] Keychain 清理完成");
}

// 5. 退出当前App
- (void)exitApp {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 优雅退出
        [UIView animateWithDuration:0.3 animations:^{
            UIWindow *window = [self getKeyWindow];
            window.alpha = 0;
        } completion:^(BOOL finished) {
            exit(0);
        }];
    });
}

#pragma mark - Menu UI

- (void)showCleanMenu {
    if (self.isMenuShowing) {
        [self hideMenu];
        return;
    }
    
    self.isMenuShowing = YES;
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow) return;
    
    // 创建菜单视图
    CGFloat menuWidth = 200;
    CGFloat menuHeight = 280;
    CGFloat buttonX = CGRectGetMinX(self.floatingButton.frame);
    CGFloat buttonY = CGRectGetMinY(self.floatingButton.frame);
    
    // 根据按钮位置决定菜单显示方向
    CGFloat menuX = buttonX - menuWidth - 10;
    if (menuX < 10) {
        menuX = CGRectGetMaxX(self.floatingButton.frame) + 10;
    }
    
    CGFloat menuY = buttonY + (50 - menuHeight) / 2;
    menuY = MAX(20, MIN(keyWindow.bounds.size.height - menuHeight - 20, menuY));
    
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, menuWidth, menuHeight)];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.menuView.layer.cornerRadius = 12;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 2);
    self.menuView.layer.shadowOpacity = 0.3;
    self.menuView.layer.shadowRadius = 8;
    
    // 菜单项
    NSArray *menuItems = @[
        @{@"title": @"🧹 快速清理", @"action": @"quickClean"},
        @{@"title": @"🗑️ 清理沙盒", @"action": @"cleanSandbox"},
        @{@"title": @"⚙️ 清理偏好设置", @"action": @"cleanUserDefaults"},
        @{@"title": @"🌐 清理Cookie/WebKit", @"action": @"cleanCookiesAndWebKit"},
        @{@"title": @"🔑 清理Keychain", @"action": @"cleanKeychain"},
        @{@"title": @"✨ 完全清理并退出", @"action": @"cleanAllData"},
        @{@"title": @"💀 仅退出App", @"action": @"exitApp"}
    ];
    
    CGFloat itemHeight = menuHeight / menuItems.count;
    for (NSInteger i = 0; i < menuItems.count; i++) {
        NSDictionary *item = menuItems[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(0, i * itemHeight, menuWidth, itemHeight);
        [btn setTitle:item[@"title"] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.backgroundColor = [UIColor clearColor];
        btn.tag = i;
        [btn addTarget:self action:@selector(menuItemTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加分隔线
        if (i < menuItems.count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, itemHeight - 0.5, menuWidth - 20, 0.5)];
            line.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
            [btn addSubview:line];
        }
        
        [self.menuView addSubview:btn];
    }
    
    // 添加关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(menuWidth - 30, 0, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:closeBtn];
    
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [keyWindow addSubview:self.menuView];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = 1;
        self.menuView.transform = CGAffineTransformIdentity;
    }];
    
    // 点击空白关闭菜单
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMenu)];
    tap.cancelsTouchesInView = NO;
    [keyWindow addGestureRecognizer:tap];
    objc_setAssociatedObject(tap, "menuTap", @(YES), OBJC_ASSOCIATION_RETAIN);
}

- (void)hideMenu {
    if (!self.isMenuShowing) return;
    
    self.isMenuShowing = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = 0;
        self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [self.menuView removeFromSuperview];
        self.menuView = nil;
    }];
    
    // 移除手势
    UIWindow *keyWindow = [self getKeyWindow];
    for (UIGestureRecognizer *gesture in keyWindow.gestureRecognizers) {
        if (objc_getAssociatedObject(gesture, "menuTap")) {
            [keyWindow removeGestureRecognizer:gesture];
        }
    }
}

- (void)menuItemTapped:(UIButton *)sender {
    NSArray *selectors = @[
        @"quickClean",
        @"cleanSandbox",
        @"cleanUserDefaults",
        @"cleanCookiesAndWebKit",
        @"cleanKeychain",
        @"cleanAllData",
        @"exitApp"
    ];
    
    if (sender.tag < selectors.count) {
        NSString *selectorName = selectors[sender.tag];
        SEL selector = NSSelectorFromString(selectorName);
        if ([self respondsToSelector:selector]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector];
            #pragma clang diagnostic pop
        }
    }
    
    [self hideMenu];
}

#pragma mark - Helper Methods

- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = [self getRootViewController];
        if (rootVC) {
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
        
        // 2秒后自动关闭
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    });
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
