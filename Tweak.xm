#import <UIKit/UIKit.h>
#import "AppCleanerPlugin.h"

static BOOL isPluginLoaded = NO;

%ctor {
    @autoreleasepool {
        if (!isPluginLoaded) {
            isPluginLoaded = YES;
            
            // 延迟加载确保UI完全初始化
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), 
                          dispatch_get_main_queue(), ^{
                [[AppCleanerPlugin sharedPlugin] showFloatingButton];
            });
        }
    }
}