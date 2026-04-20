#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 去广告功能

static BOOL (*orig_boolForKey)(id self, SEL _cmd, NSString *defaultName);

static BOOL new_boolForKey(id self, SEL _cmd, NSString *defaultName) {
    // 强制隐藏广告开关
    if ([defaultName isEqualToString:@"isAdvertisementHiddenV2"]) {
        return YES;
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
        NSLog(@"[TrollFoolsAdRemover] Ad removal enabled.");
    } else {
        NSLog(@"[TrollFoolsAdRemover] Failed to hook boolForKey:");
    }
}

#pragma mark - 简化模式功能

static BOOL isSimplifiedMode = NO;          // 当前是否处于简化模式
static NSString * const kSimplifiedModeChangedNotification = @"SimplifiedModeChanged";

static void toggleSimplifiedMode() {
    isSimplifiedMode = !isSimplifiedMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSimplifiedModeChangedNotification object:nil];
}

// 递归隐藏 IndexableScroller（右侧字母索引）
static void hideIndexableScrollerInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"IndexableScroller"]) {
            subview.hidden = YES;
        }
        hideIndexableScrollerInView(subview);
    }
}

// 隐藏分段控件（Scope Bar）和右侧索引
static void applySimplifiedMode(UIViewController *vc) {
    if (!isSimplifiedMode) return;
    
    // 1. 隐藏搜索栏的 scope bar（所有应用/用户应用/巨魔应用/系统应用）
    for (UIView *subview in vc.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = NO;
                searchBar.scopeButtonTitles = nil;
                break;
            }
        }
    }
    
    // 2. 隐藏右侧字母索引视图
    hideIndexableScrollerInView(vc.view);
}

// 恢复简化模式隐藏的内容（显示 scope bar 和索引）
static void resetSimplifiedMode(UIViewController *vc) {
    // 显示 scope bar（恢复原始状态）
    for (UIView *subview in vc.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = YES;
                // 需要重新设置 scopeButtonTitles，原始值需要从 AppListModel.Scope 获取
                // 为简单起见，我们只恢复显示，标题会在下次刷新时自动恢复
                break;
            }
        }
    }
    
    // 显示右侧索引（遍历恢复隐藏）
    void (^showIndexableScroller)(UIView *) = ^(UIView *view) {
        for (UIView *subview in view.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"IndexableScroller"]) {
                subview.hidden = NO;
            }
            showIndexableScroller(subview);
        }
    };
    showIndexableScroller(vc.view);
}

// 根据当前模式更新视图
static void updateUIForMode(UIViewController *vc) {
    if (isSimplifiedMode) {
        applySimplifiedMode(vc);
    } else {
        resetSimplifiedMode(vc);
    }
}

#pragma mark - Hook 代码

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    // 监听简化模式切换通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tf_simplifiedModeChanged)
                                                 name:kSimplifiedModeChangedNotification
                                               object:nil];
}

- (void)tf_simplifiedModeChanged {
    // 只处理承载 AppListView 的 UIHostingController
    if ([self isKindOfClass:NSClassFromString(@"UIHostingController")]) {
        UIViewController *hosting = self;
        NSString *rootClassName = NSStringFromClass([[hosting valueForKey:@"rootView"] class]);
        if ([rootClassName containsString:@"AppListView"]) {
            updateUIForMode(hosting);
            // 更新左上角按钮标题
            UIBarButtonItem *btn = hosting.navigationItem.leftBarButtonItem;
            if (btn) {
                btn.title = isSimplifiedMode ? @"恢复" : @"简化";
            }
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

%end

%hook UIHostingController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    NSString *rootClassName = NSStringFromClass([self.rootView class]);
    if ([rootClassName containsString:@"AppListView"]) {
        // 应用当前模式（如果未应用过）
        static NSMutableSet *processedControllers = [NSMutableSet set];
        if (![processedControllers containsObject:self]) {
            [processedControllers addObject:self];
            updateUIForMode(self);
            
            // 添加左上角切换按钮
            UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:isSimplifiedMode ? @"恢复" : @"简化"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(tf_toggleSimplifiedMode)];
            self.navigationItem.leftBarButtonItem = toggleButton;
        }
    }
}

%new
- (void)tf_toggleSimplifiedMode {
    toggleSimplifiedMode();
    // 更新当前控制器的 UI
    updateUIForMode(self);
    // 更新按钮标题
    self.navigationItem.leftBarButtonItem.title = isSimplifiedMode ? @"恢复" : @"简化";
}

%end