// BluedPrivacyEnabler.m
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 工具函数
static void swizzleMethod(Class class, SEL original, SEL replacement) {
    Method origMethod = class_getInstanceMethod(class, original);
    Method newMethod = class_getInstanceMethod(class, replacement);
    if (class_addMethod(class, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, replacement, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

static void setPropertyIfExists(id obj, NSString *propertyName, id value) {
    SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", [propertyName capitalizedString]]);
    if ([obj respondsToSelector:setter]) {
        [obj setValue:value forKey:propertyName];
    }
}

#pragma mark - 核心功能设置
static void enableAllPrivacyFeatures(id userInfo) {
    // 1. 无痕访问
    setPropertyIfExists(userInfo, @"isTracelessAccess", @YES);
    
    // 2. 悄悄查看
    setPropertyIfExists(userInfo, @"isGlobalViewSecretly", @YES);
    setPropertyIfExists(userInfo, @"isAgeStealth", @YES);
    setPropertyIfExists(userInfo, @"isRoleStealth", @YES);
    setPropertyIfExists(userInfo, @"isStealthDistance", @YES);
    
    // 3. 隐藏在线时间
    setPropertyIfExists(userInfo, @"isHideLastOperate", @YES);
    
    // 4. 隐藏距离
    setPropertyIfExists(userInfo, @"isHideDistance", @YES);
    
    // 5. 截屏保护（在单独的管理类中设置）
    // 稍后单独处理
}

#pragma mark - 截屏保护单独处理
static void enableScreenshotProtection(void) {
    // 尝试获取 BDChatProtectionManager 单例
    Class managerClass = NSClassFromString(@"BDChatProtectionManager");
    if (managerClass) {
        // 假设有 sharedInstance 方法
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if ([managerClass respondsToSelector:sharedSel]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)(managerClass, sharedSel);
            if (manager && [manager respondsToSelector:NSSelectorFromString(@"setIs_prohibit_chat_screenshot:")]) {
                [manager setValue:@YES forKey:@"is_prohibit_chat_screenshot"];
            }
        }
    }
    
    // 尝试获取 BDChatProtectionModel 实例（可能通过 userDefaults 或单例）
    Class modelClass = NSClassFromString(@"BDChatProtectionModel");
    if (modelClass) {
        id model = [modelClass performSelector:NSSelectorFromString(@"sharedModel")]; // 假设存在
        if (model) {
            setPropertyIfExists(model, @"is_prohibit_chat_screenshot", @YES);
        }
    }
}

#pragma mark - Hook 用户信息对象的初始化
static void setupUserInfoHook(void) {
    Class BDUserInfo = NSClassFromString(@"BDUserInfo");
    if (!BDUserInfo) return;
    
    // 保存原始方法实现
    SEL originalInit = @selector(initWithCoder:);
    __block IMP originalImp = NULL;
    
    IMP newImp = imp_implementationWithBlock(^(id self, NSCoder *coder) {
        id result = ((id (*)(id, SEL, NSCoder*))originalImp)(self, originalInit, coder);
        if (result) {
            enableAllPrivacyFeatures(result);
        }
        return result;
    });
    
    Method method = class_getInstanceMethod(BDUserInfo, originalInit);
    if (method) {
        originalImp = method_getImplementation(method);
        class_replaceMethod(BDUserInfo, @selector(privacy_initWithCoder:), newImp, method_getTypeEncoding(method));
        swizzleMethod(BDUserInfo, originalInit, @selector(privacy_initWithCoder:));
    }
    
    // 也可以 hook 其他初始化方法，如 initWithDictionary:
    SEL dictInit = @selector(initWithDictionary:);
    if (class_getInstanceMethod(BDUserInfo, dictInit)) {
        // 类似实现，省略
    }
}

#pragma mark - 监听登录成功，再次确保设置
static void observeLoginSuccess(void) {
    // 假设登录成功通知名为 "BDLoginSuccessNotification"
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BDLoginSuccessNotification"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        // 获取当前用户信息
        id userInfo = nil;
        // 尝试从 AppDelegate 获取
        id appDelegate = [UIApplication sharedApplication].delegate;
        if (appDelegate) {
            id mineModel = [appDelegate valueForKey:@"mineModel"];
            if (mineModel && [mineModel respondsToSelector:NSSelectorFromString(@"userInfo")]) {
                userInfo = [mineModel valueForKey:@"userInfo"];
            } else {
                // 尝试直接获取 userInfo
                userInfo = [appDelegate valueForKey:@"userInfo"];
            }
        }
        if (userInfo) {
            enableAllPrivacyFeatures(userInfo);
        }
        enableScreenshotProtection();
    }];
}

#pragma mark - 入口
__attribute__((constructor))
static void initialize(void) {
    // 延迟执行，确保应用已经启动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupUserInfoHook();
        enableScreenshotProtection();
        observeLoginSuccess();
    });
}