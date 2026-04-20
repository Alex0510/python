#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 去广告功能

static BOOL (*orig_boolForKey)(id self, SEL _cmd, NSString *defaultName);

static BOOL new_boolForKey(id self, SEL _cmd, NSString *defaultName) {
    if ([defaultName isEqualToString:@"isAdvertisementHiddenV2"]) {
        return YES;   // 强制隐藏广告
    }
    return orig_boolForKey(self, _cmd, defaultName);
}

__attribute__((constructor))
static void initAdRemover() {
    Class cls = NSClassFromString(@"NSUserDefaults");
    SEL sel = @selector(boolForKey:);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_boolForKey = (typeof(orig_boolForKey))method_getImplementation(method);
        method_setImplementation(method, (IMP)new_boolForKey);
        NSLog(@"[TrollFoolsAdRemover] 去广告已启用");
    } else {
        NSLog(@"[TrollFoolsAdRemover] Hook boolForKey: 失败");
    }
}

#pragma mark - 简化模式功能

static BOOL isSimplifiedMode = NO;                         // 当前模式
static NSString * const kModeChangedNotification = @"SimplifiedModeChanged";

// 切换模式
static void toggleSimplifiedMode() {
    isSimplifiedMode = !isSimplifiedMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:kModeChangedNotification object:nil];
}

// 递归隐藏右侧字母索引视图
static void hideIndexScrollerInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"IndexableScroller"]) {
            subview.hidden = YES;
        }
        hideIndexScrollerInView(subview);
    }
}

// 应用简化模式：隐藏搜索栏的分段控件(Scope Bar) 和右侧字母索引
static void applySimplifiedMode(UIViewController *vc) {
    if (!isSimplifiedMode) return;

    // 隐藏搜索栏的分段控件
    for (UIView *subview in vc.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = NO;
                searchBar.scopeButtonTitles = nil;
            }
            break;
        }
    }
    // 隐藏右侧字母索引
    hideIndexScrollerInView(vc.view);
}

// 恢复原始状态：显示分段控件和索引（仅显示分段控件，索引恢复显示）
static void resetSimplifiedMode(UIViewController *vc) {
    for (UIView *subview in vc.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = YES;
                // 分段按钮标题会在视图刷新时自动恢复，无需手动设置
            }
            break;
        }
    }
    // 恢复右侧字母索引
    void (^showIndexScroller)(UIView *) = ^(UIView *view) {
        for (UIView *subview in view.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"IndexableScroller"]) {
                subview.hidden = NO;
            }
            showIndexScroller(subview);
        }
    };
    showIndexScroller(vc.view);
}

// 根据当前模式更新界面
static void updateUIForCurrentMode(UIViewController *vc) {
    if (isSimplifiedMode) {
        applySimplifiedMode(vc);
    } else {
        resetSimplifiedMode(vc);
    }
}

#pragma mark - 添加左上角按钮

static UIButton *simplifyButton = nil;

static void addSimplifyButtonToViewController(UIViewController *vc) {
    if (!vc.navigationController) return;

    // 如果按钮已经存在，只更新标题
    if (simplifyButton && simplifyButton.superview) {
        [simplifyButton setTitle:isSimplifiedMode ? @"恢复" : @"简化" forState:UIControlStateNormal];
        return;
    }

    // 创建按钮
    simplifyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [simplifyButton setTitle:isSimplifiedMode ? @"恢复" : @"简化" forState:UIControlStateNormal];
    [simplifyButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [simplifyButton addTarget:nil action:@selector(tf_onSimplifyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [simplifyButton sizeToFit];

    // 将按钮设置为 navigationItem 的 leftBarButtonItem
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:simplifyButton];
    vc.navigationItem.leftBarButtonItem = barItem;
    [vc.navigationController.navigationBar setNeedsLayout];
}

#pragma mark - 处理模式切换通知

static void handleModeChange() {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootVC;
        for (UIViewController *vc in nav.viewControllers) {
            if ([NSStringFromClass([vc class]) containsString:@"AppListView"]) {
                updateUIForCurrentMode(vc);
                if (simplifyButton) {
                    [simplifyButton setTitle:isSimplifiedMode ? @"恢复" : @"简化" forState:UIControlStateNormal];
                } else {
                    addSimplifyButtonToViewController(vc);
                }
                break;
            }
        }
    }
}

// 按钮点击回调（通过响应链查找）
static void tf_onSimplifyButtonTapped(id self, SEL _cmd) {
    toggleSimplifiedMode();
    handleModeChange();
}

#pragma mark - Hook 部分

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tf_handleModeChange)
                                                 name:kModeChangedNotification
                                               object:nil];
}

- (void)tf_handleModeChange {
    handleModeChange();
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

%end

%hook UINavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    %orig;
    if ([NSStringFromClass([viewController class]) containsString:@"AppListView"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            addSimplifyButtonToViewController(viewController);
        });
    }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    %orig;
    for (UIViewController *vc in viewControllers) {
        if ([NSStringFromClass([vc class]) containsString:@"AppListView"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                addSimplifyButtonToViewController(vc);
            });
            break;
        }
    }
}

%end

// 为 NSObject 添加方法，使按钮的 target (nil) 能够找到实现
@interface NSObject (TrollFoolsAdRemover)
- (void)tf_onSimplifyButtonTapped;
@end

@implementation NSObject (TrollFoolsAdRemover)
- (void)tf_onSimplifyButtonTapped {
    tf_onSimplifyButtonTapped(self, _cmd);
}
@end

%ctor {
    NSLog(@"[TrollFoolsAdRemover] 插件加载完成");
}