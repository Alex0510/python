// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - 工具函数
static void swizzleMethod(Class cls, SEL original, SEL replacement) {
    Method origMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, replacement);
    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, replacement, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

static void setPropertyIfExists(id obj, NSString *propertyName, id value) {
    NSString *setterName = [NSString stringWithFormat:@"set%@:", [propertyName capitalizedString]];
    SEL setter = NSSelectorFromString(setterName);
    if ([obj respondsToSelector:setter]) {
        ((void (*)(id, SEL, id))objc_msgSend)(obj, setter, value);
    }
}

#pragma mark - 核心功能设置
static void enableAllPrivacyFeatures(id userInfo) {
    setPropertyIfExists(userInfo, @"isTracelessAccess", @YES);
    setPropertyIfExists(userInfo, @"isGlobalViewSecretly", @YES);
    setPropertyIfExists(userInfo, @"isAgeStealth", @YES);
    setPropertyIfExists(userInfo, @"isRoleStealth", @YES);
    setPropertyIfExists(userInfo, @"isStealthDistance", @YES);
    setPropertyIfExists(userInfo, @"isHideLastOperate", @YES);
    setPropertyIfExists(userInfo, @"isHideDistance", @YES);
}

static void enableScreenshotProtection(void) {
    Class managerClass = NSClassFromString(@"BDChatProtectionManager");
    if (managerClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if ([managerClass respondsToSelector:sharedSel]) {
            id manager = ((id (*)(id, SEL))objc_msgSend)(managerClass, sharedSel);
            if (manager && [manager respondsToSelector:NSSelectorFromString(@"setIs_prohibit_chat_screenshot:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(manager, NSSelectorFromString(@"setIs_prohibit_chat_screenshot:"), YES);
            }
        }
    }
    Class modelClass = NSClassFromString(@"BDChatProtectionModel");
    if (modelClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedModel");
        if ([modelClass respondsToSelector:sharedSel]) {
            id model = ((id (*)(id, SEL))objc_msgSend)(modelClass, sharedSel);
            if (model) {
                setPropertyIfExists(model, @"is_prohibit_chat_screenshot", @YES);
            }
        }
    }
}

#pragma mark - Hook 用户信息对象的初始化
static void setupUserInfoHook(void) {
    Class BDUserInfo = NSClassFromString(@"BDUserInfo");
    if (!BDUserInfo) return;

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
}

#pragma mark - 监听登录成功，再次确保设置
static void observeLoginSuccess(void) {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BDLoginSuccessNotification"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        id appDelegate = [UIApplication sharedApplication].delegate;
        if (appDelegate) {
            id mineModel = [appDelegate valueForKey:@"mineModel"];
            if (mineModel && [mineModel respondsToSelector:NSSelectorFromString(@"userInfo")]) {
                id userInfo = [mineModel valueForKey:@"userInfo"];
                if (userInfo) enableAllPrivacyFeatures(userInfo);
            } else {
                id userInfo = [appDelegate valueForKey:@"userInfo"];
                if (userInfo) enableAllPrivacyFeatures(userInfo);
            }
        }
        enableScreenshotProtection();
    }];
}

#pragma mark - 入口
__attribute__((constructor))
static void initialize(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupUserInfoHook();
        enableScreenshotProtection();
        observeLoginSuccess();
    });
}