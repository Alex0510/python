#import <UIKit/UIKit.h>
#import "AppCleanerPlugin.h"

// 使用 %ctor 在每次App启动时初始化
%ctor {
    @autoreleasepool {
        // 延迟加载，确保App完全启动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[AppCleanerPlugin sharedPlugin] showFloatingButton];
        });
    }
}