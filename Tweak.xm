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
        NSLog(@"[TrollFoolsAdRemover] 去广告已启用");
    } else {
        NSLog(@"[TrollFoolsAdRemover] Hook boolForKey: 失败");
    }
}

#pragma mark - 隐藏分段控件与字母索引（直接隐藏，无需按钮）

static void hideScopeBarAndIndexInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        // 隐藏右侧字母索引
        if ([className containsString:@"IndexableScroller"]) {
            subview.hidden = YES;
        }
        // 隐藏搜索栏的分段控件 (Scope Bar)
        if ([subview isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            UISearchBar *searchBar = [subview valueForKey:@"searchBar"];
            if (searchBar) {
                searchBar.showsScopeBar = NO;
                searchBar.scopeButtonTitles = nil;
            }
        }
        hideScopeBarAndIndexInView(subview);
    }
}

static void applySimplifications(UIViewController *vc) {
    hideScopeBarAndIndexInView(vc.view);
}

#pragma mark - Hook 视图控制器

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // 只处理包含 AppListView 的控制器
    if ([NSStringFromClass([self class]) containsString:@"AppListView"] ||
        [NSStringFromClass([[self valueForKey:@"rootView"] class]) containsString:@"AppListView"]) {
        applySimplifications(self);
        NSLog(@"[TrollFoolsAdRemover] 已隐藏分段控件和字母索引");
    }
}

%end

%ctor {
    NSLog(@"[TrollFoolsAdRemover] 插件加载完成，将自动隐藏 UI 元素");
}