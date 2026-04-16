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

- (void)setupFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingButton.frame = CGRectMake(0, 0, 50, 50);
        self.floatingButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.85];
        self.floatingButton.layer.cornerRadius = 25;
        self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
        self.floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
        self.floatingButton.layer.shadowOpacity = 0.4;
        self.floatingButton.layer.shadowRadius = 4;
        [self.floatingButton setTitle:@"🧹" forState:UIControlStateNormal];
        self.floatingButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] 
                                                     initWithTarget:self 
                                                     action:@selector(showCleanMenu)];
        longPress.minimumPressDuration = 0.3;
        [self.floatingButton addGestureRecognizer:longPress];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] 
                                        initWithTarget:self 
                                        action:@selector(handlePan:)];
        [self.floatingButton addGestureRecognizer:pan];
        
        [self.floatingButton addTarget:self 
                                action:@selector(quickClean) 
                      forControlEvents:UIControlEventTouchUpInside];
    });
}

- (void)showFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow && ![self.floatingButton.superview isEqual:keyWindow]) {
            [keyWindow addSubview:self.floatingButton];
            
            CGFloat x = keyWindow.bounds.size.width - 60;
            CGFloat y = keyWindow.bounds.size.height - 100;
            self.floatingButton.frame = CGRectMake(x, y, 50, 50);
            self.floatingButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
                                                    UIViewAutoresizingFlexibleTopMargin;
            
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

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    CGPoint translation = [gesture translationInView:button.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.initialTouchPoint = button.center;
        if (self.isMenuShowing) [self hideMenu];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.initialTouchPoint.x + translation.x,
                                        self.initialTouchPoint.y + translation.y);
        UIWindow *keyWindow = [self getKeyWindow];
        CGFloat minX = 25, maxX = keyWindow.bounds.size.width - 25;
        CGFloat minY = 50, maxY = keyWindow.bounds.size.height - 50;
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
    CGFloat centerX = self.floatingButton.center.x;
    CGFloat targetX = (centerX < keyWindow.bounds.size.width / 2) ? 35 : keyWindow.bounds.size.width - 35;
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.center = CGPointMake(targetX, self.floatingButton.center.y);
    }];
}

- (void)quickClean {
    [self cleanSandbox];
    [self cleanUserDefaults];
    [self cleanCookiesAndWebKit];
    [self showAlert:@"✅ 快速清理完成" message:@"已清理沙盒、偏好设置和Cookie"];
}

- (void)cleanAllData {
    [self cleanSandbox];
    [self cleanUserDefaults];
    [self cleanCookiesAndWebKit];
    [self cleanKeychain];
    [self showAlert:@"✨ 完全清理完成" message:@"已清理所有数据，即将退出"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitApp];
    });
}

- (void)cleanSandbox {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *homePath = NSHomeDirectory();
    
    NSArray *paths = @[
        [homePath stringByAppendingPathComponent:@"Documents"],
        [homePath stringByAppendingPathComponent:@"Library/Caches"],
        NSTemporaryDirectory()
    ];
    
    for (NSString *path in paths) {
        if ([fm fileExistsAtPath:path]) {
            NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
            for (NSString *item in contents) {
                if (![item isEqualToString:@"."] && ![item isEqualToString:@".."]) {
                    [fm removeItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
                }
            }
        }
    }
    NSLog(@"[AppCleaner] 沙盒清理完成");
}

- (void)cleanUserDefaults {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[AppCleaner] NSUserDefaults清理完成: %@", bundleIdentifier);
    }
}

- (void)cleanCookiesAndWebKit {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        [cookieStorage deleteCookie:cookie];
    }
    
    if (@available(iOS 9.0, *)) {
        NSSet *websiteDataTypes = [NSSet setWithArray:@[
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeLocalStorage
        ]];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes 
                                                   modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] 
                                               completionHandler:^{
            NSLog(@"[AppCleaner] WebKit清理完成");
        }];
    }
    NSLog(@"[AppCleaner] Cookie清理完成");
}

- (void)cleanKeychain {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
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
            if (item[(id)kSecAttrService]) deleteQuery[(id)kSecAttrService] = item[(id)kSecAttrService];
            if (item[(id)kSecAttrAccount]) deleteQuery[(id)kSecAttrAccount] = item[(id)kSecAttrAccount];
            SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
        }
    }
    NSLog(@"[AppCleaner] Keychain清理完成");
}

- (void)exitApp {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [[self getKeyWindow] setAlpha:0];
        } completion:^(BOOL finished) {
            exit(0);
        }];
    });
}

- (void)showCleanMenu {
    if (self.isMenuShowing) {
        [self hideMenu];
        return;
    }
    
    self.isMenuShowing = YES;
    UIWindow *keyWindow = [self getKeyWindow];
    if (!keyWindow) return;
    
    CGFloat menuWidth = 200;
    CGFloat menuHeight = 280;
    CGFloat menuX = CGRectGetMinX(self.floatingButton.frame) - menuWidth - 10;
    if (menuX < 10) menuX = CGRectGetMaxX(self.floatingButton.frame) + 10;
    CGFloat menuY = CGRectGetMinY(self.floatingButton.frame) + (50 - menuHeight) / 2;
    menuY = MAX(20, MIN(keyWindow.bounds.size.height - menuHeight - 20, menuY));
    
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, menuWidth, menuHeight)];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.menuView.layer.cornerRadius = 12;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 2);
    self.menuView.layer.shadowOpacity = 0.3;
    
    NSArray *menuItems = @[
        @"🧹 快速清理", @"🗑️ 清理沙盒", @"⚙️ 清理偏好设置",
        @"🌐 清理Cookie", @"🔑 清理Keychain", @"✨ 完全清理并退出", @"💀 仅退出App"
    ];
    
    CGFloat itemHeight = menuHeight / menuItems.count;
    for (NSInteger i = 0; i < menuItems.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(0, i * itemHeight, menuWidth, itemHeight);
        [btn setTitle:menuItems[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.tag = i;
        [btn addTarget:self action:@selector(menuItemTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        if (i < menuItems.count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, itemHeight - 0.5, menuWidth - 20, 0.5)];
            line.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
            [btn addSubview:line];
        }
        [self.menuView addSubview:btn];
    }
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(menuWidth - 30, 0, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:closeBtn];
    
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [keyWindow addSubview:self.menuView];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = 1;
        self.menuView.transform = CGAffineTransformIdentity;
    }];
}

- (void)hideMenu {
    if (!self.isMenuShowing) return;
    self.isMenuShowing = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.menuView removeFromSuperview];
        self.menuView = nil;
    }];
}

- (void)menuItemTapped:(UIButton *)sender {
    NSArray *selectors = @[@"quickClean", @"cleanSandbox", @"cleanUserDefaults", 
                           @"cleanCookiesAndWebKit", @"cleanKeychain", @"cleanAllData", @"exitApp"];
    if (sender.tag < selectors.count) {
        SEL selector = NSSelectorFromString(selectors[sender.tag]);
        if ([self respondsToSelector:selector]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector];
            #pragma clang diagnostic pop
        }
    }
    [self hideMenu];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        UIViewController *rootVC = [self getRootViewController];
        if (rootVC) [rootVC presentViewController:alert animated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

// 修复：兼容 iOS 11+ 的 getKeyWindow 方法
- (UIWindow *)getKeyWindow {
    // iOS 13+ 兼容方法
    if (@available(iOS 13.0, *)) {
        UIWindowScene *activeScene = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = scene;
                break;
            }
        }
        if (activeScene) {
            for (UIWindow *window in activeScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
            // 如果没有keyWindow，返回第一个window
            return activeScene.windows.firstObject;
        }
    }
    
    // iOS 12 及以下
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
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