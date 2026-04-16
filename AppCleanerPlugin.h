//
//  AppCleanerPlugin.h
//  AppCleaner
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppCleanerPlugin : NSObject

+ (instancetype)sharedPlugin;
- (void)showFloatingButton;
- (void)hideFloatingButton;

// 清理方法
- (void)quickClean;
- (void)cleanAllData;
- (void)cleanSandbox;
- (void)cleanUserDefaults;
- (void)cleanCookiesAndWebKit;
- (void)cleanKeychain;
- (void)exitApp;

@end

NS_ASSUME_NONNULL_END