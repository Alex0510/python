#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 去广告功能

static BOOL (*orig_boolForKey)(id self, SEL _cmd, NSString *defaultName);

static BOOL new_boolForKey(id self, SEL _cmd, NSString *defaultName) {
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

static BOOL isSimplifiedMode = NO;
static NSString * const kSimplifiedModeChangedNotification = @"SimplifiedModeChanged";

static void toggleSimplifiedMode() {
    isSimplifiedMode = !isSimplifiedMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSimplifiedModeChangedNotification object:nil];
}

static void hideIndexableScrollerInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"IndexableScroller"]) {
            subview.hidden = YES;
        }
        hideIndexableScrollerInView(subview);
    }
}

static void applySimplifiedMode(UIViewController *vc) {
    if (!isSimplifiedMode) return;
    
    // 隐藏搜索栏的分段控件 (Scope Bar)
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
    // 隐藏右侧字母索引
    hideIndexableScrollerInView(vc.view);
}

static void resetSimplifiedMode(UIViewController *vc) {
    for (UIView *subview in vc.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = YES;
                // 注意：scopeButtonTitles 需要重新设置，原始值需要从 AppListModel.Scope 获取
                // 简单起见，不恢复标题，下次视图刷新时会自动恢复
                break;
            }
        }
    }
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

static void updateUIForMode(UIViewController *vc) {
    if (isSimplifiedMode) {
        applySimplifiedMode(vc);
    } else {
        resetSimplifiedMode(vc);
    }
}

#pragma mark - Hook

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tf_simplifiedModeChanged)
                                                 name:kSimplifiedModeChangedNotification
                                               object:nil];
}

- (void)tf_simplifiedModeChanged {
    if ([self isKindOfClass:NSClassFromString(@"UIHostingController")]) {
        UIViewController *hosting = self;
        NSString *rootClassName = NSStringFromClass([[hosting valueForKey:@"rootView"] class]);
        if ([rootClassName containsString:@"AppListView"]) {
            updateUIForMode(hosting);
            // 更新左上角按钮标题
            UIBarButtonItem *btn = hosting.navigationItem.leftBarButtonItem;
            if (btn && (btn.action == @selector(tf_toggleSimplifiedMode))) {
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
    static NSMutableSet *processed = [NSMutableSet set];
    if ([processed containsObject:self]) return;
    
    NSString *rootClassName = NSStringFromClass([self.rootView class]);
    if ([rootClassName containsString:@"AppListView"]) {
        [processed addObject:self];
        // 延迟添加按钮，确保导航栏完全加载
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addSimplifyButton];
        });
        NSLog(@"[TrollFoolsAdRemover] AppListView detected, will add button.");
    }
}

%new
- (void)addSimplifyButton {
    // 避免重复添加
    UIBarButtonItem *existing = self.navigationItem.leftBarButtonItem;
    if (existing && (existing.action == @selector(tf_toggleSimplifiedMode))) {
        return;
    }
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:isSimplifiedMode ? @"恢复" : @"简化"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(tf_toggleSimplifiedMode)];
    self.navigationItem.leftBarButtonItem = btn;
    [self.navigationController.navigationBar setNeedsLayout];
    NSLog(@"[TrollFoolsAdRemover] Simplify button added to left bar.");
}

%new
- (void)tf_toggleSimplifiedMode {
    toggleSimplifiedMode();
    updateUIForMode(self);
    self.navigationItem.leftBarButtonItem.title = isSimplifiedMode ? @"恢复" : @"简化";
    NSLog(@"[TrollFoolsAdRemover] Simplified mode toggled: %@", isSimplifiedMode ? @"ON" : @"OFF");
}

%end