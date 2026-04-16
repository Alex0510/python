//
//  AppCleanerPlugin.h
//  AppCleaner
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppCleanerPlugin : NSObject

+ (instancetype)sharedPlugin;

/// 显示悬浮清理按钮
- (void)showFloatingButton;

/// 隐藏悬浮清理按钮
- (void)hideFloatingButton;

/// 清理当前App的所有数据
- (void)cleanAllData;

/// 清理沙盒 (Documents/Caches/tmp)
- (void)cleanSandbox;

/// 清理 NSUserDefaults
- (void)cleanUserDefaults;

/// 清理 Cookie 和 WebKit
- (void)cleanCookiesAndWebKit;

/// 清理 Keychain
- (void)cleanKeychain;

/// 退出App
- (void)exitApp;

@end

NS_ASSUME_NONNULL_END