#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static UIWindow *floatingWindow = nil;
static NSString * const kEnableInfiniteResourcesNotification = @"com.example.hellolua.enableInfinite";

// 安全执行 Lua 脚本
static void executeLuaScript(NSString *script) {
    @try {
        // 方式1：尝试获取 Cocos2d-x Lua 引擎
        Class luaEngineClass = NSClassFromString(@"LuaEngine");
        if (luaEngineClass && [luaEngineClass respondsToSelector:@selector(getInstance)]) {
            id engine = [luaEngineClass performSelector:@selector(getInstance)];
            if (engine && [engine respondsToSelector:NSSelectorFromString(@"getLuaState")]) {
                // 获取 lua_State*
                NSMethodSignature *sig = [engine methodSignatureForSelector:NSSelectorFromString(@"getLuaState")];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setTarget:engine];
                [inv setSelector:NSSelectorFromString(@"getLuaState")];
                void *state = NULL;
                [inv invoke];
                [inv getReturnValue:&state];
                if (state) {
                    // 查找 luaL_dostring 符号
                    int (*luaL_dostring)(void*, const char*) = (int (*)(void*, const char*))dlsym(RTLD_DEFAULT, "luaL_dostring");
                    if (luaL_dostring) {
                        luaL_dostring(state, [script UTF8String]);
                        return;
                    }
                }
            }
        }

        // 方式2：尝试通过 Swift 桥接类执行脚本（假设有方法）
        Class bridgeClass = NSClassFromString(@"_TtC8HelloLua11SwiftBridge");
        if (bridgeClass) {
            id bridge = [[bridgeClass alloc] init];
            SEL testSel = NSSelectorFromString(@"test");
            if ([bridge respondsToSelector:testSel]) {
                [bridge performSelector:testSel];
            }
            SEL execSel = NSSelectorFromString(@"executeLua:");
            if ([bridge respondsToSelector:execSel]) {
                [bridge performSelector:execSel withObject:script];
            }
        }

        // 如果都无法执行，可以在此打印日志或弹窗提示
        NSLog(@"无法执行 Lua 脚本，请检查游戏版本或逆向结果");
    } @catch (NSException *exception) {
        NSLog(@"执行 Lua 脚本异常: %@", exception);
    }
}

// 显示提示框（主线程安全）
static void showAlert(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

%hook AppController

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL ret = %orig;

    // 延迟一点创建悬浮窗，避免干扰启动流程
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserverForName:kEnableInfiniteResourcesNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            // 执行修改资源的 Lua 脚本
            NSString *script = @"\
                -- 根据实际游戏 API 修改以下内容\
                if setMagicBirdCount then setMagicBirdCount(999) end\
                if setEnergy then setEnergy(999) end\
                if setCoin then setCoin(999999) end\
                local mgr = GameManager:getInstance()\
                if mgr then\
                    mgr:setMagicBirdCount(999)\
                    mgr:setEnergy(999)\
                    mgr:setCoin(999999)\
                end\
            ";
            executeLuaScript(script);
            showAlert(@"无限魔力鸟、精力、风车币已开启！");
        }];

        // 创建悬浮按钮
        CGFloat size = 50;
        CGFloat margin = 10;
        CGFloat x = [UIScreen mainScreen].bounds.size.width - size - margin;
        CGFloat y = 100;
        CGRect frame = CGRectMake(x, y, size, size);

        if (!floatingWindow) {
            floatingWindow = [[UIWindow alloc] initWithFrame:frame];
            floatingWindow.windowLevel = UIWindowLevelAlert + 1;
            floatingWindow.backgroundColor = [UIColor clearColor];
            floatingWindow.hidden = NO;

            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, size, size);
            button.backgroundColor = [UIColor redColor];
            button.layer.cornerRadius = size / 2;
            button.layer.shadowColor = [UIColor blackColor].CGColor;
            button.layer.shadowOffset = CGSizeMake(2, 2);
            button.layer.shadowOpacity = 0.5;
            [button setTitle:@"🐦" forState:UIControlStateNormal];
            // 使用 weak 避免循环引用，但这里 self 是 AppController 单例，直接使用没问题
            [button addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [floatingWindow addSubview:button];

            // 添加拖拽手势
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [button addGestureRecognizer:pan];
        }
    });

    return ret;
}

- (void)floatingButtonTapped:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kEnableInfiniteResourcesNotification object:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:gesture.view.superview];
        gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                          gesture.view.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:gesture.view.superview];
    }
}

%end

%ctor {
    // 可选初始化
}