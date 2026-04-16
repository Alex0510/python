#import <UIKit/UIKit.h>
#import "SandboxCleanerPlugin.h"

%ctor {
    @autoreleasepool {
        // 延迟加载，确保 SpringBoard 完全启动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[SandboxCleanerPlugin sharedPlugin] showFloatingButton];
        });
    }
}