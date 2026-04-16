//
//  SandboxCleanerPlugin.h
//  SandboxCleanerPlugin
//
//  Created on 2026-04-16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SandboxCleanerPlugin : NSObject

+ (instancetype)sharedPlugin;

/// 显示悬浮清理按钮
- (void)showFloatingButton;

/// 隐藏悬浮清理按钮
- (void)hideFloatingButton;

@end

NS_ASSUME_NONNULL_END