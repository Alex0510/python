// Tweak.xm

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// 悬浮窗口
static UIWindow *floatingWindow = nil;

// 通知名称，用于解耦
static NSString * const kEnableInfiniteResourcesNotification = @"com.example.hellolua.enableInfinite";

// 尝试通过Lua引擎执行脚本
static void executeLuaScript(NSString *script) {
    // 方式1：通过 Cocos2d-x LuaEngine 获取状态机
    // 动态查找类（实际类名可能为 LuaEngine、LuaEngineImpl 等）
    Class luaEngineClass = NSClassFromString(@"LuaEngine");
    if (luaEngineClass) {
        // 获取单例实例
        id engine = [luaEngineClass performSelector:@selector(getInstance)];
        if (engine) {
            // 获取 lua_State*
            SEL getStateSel = NSSelectorFromString(@"getLuaState");
            if ([engine respondsToSelector:getStateSel]) {
                NSMethodSignature *sig = [engine methodSignatureForSelector:getStateSel];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setTarget:engine];
                [inv setSelector:getStateSel];
                void *state = NULL;
                [inv invoke];
                [inv getReturnValue:&state];
                if (state) {
                    // 调用 luaL_dostring
                    int (*luaL_dostring)(void*, const char*) = (int (*)(void*, const char*))dlsym(RTLD_DEFAULT, "luaL_dostring");
                    if (luaL_dostring) {
                        luaL_dostring(state, [script UTF8String]);
                        return;
                    }
                }
            }
        }
    }
    
    // 方式2：通过 Swift 桥接类尝试执行 Lua 代码
    // 头文件中有 _TtC8HelloLua11SwiftBridge 类，可能提供与 Lua 交互的方法
    Class bridgeClass = NSClassFromString(@"_TtC8HelloLua11SwiftBridge");
    if (bridgeClass) {
        id bridge = [[bridgeClass alloc] init];
        // 尝试调用 test 方法（可能是执行 Lua 脚本的占位方法）
        if ([bridge respondsToSelector:@selector(test)]) {
            [bridge performSelector:@selector(test)];
        }
        // 如果有其他公开方法，可以尝试更精确的调用
        // 例如假设存在 - (void)executeLua:(NSString *)script
        SEL execSel = NSSelectorFromString(@"executeLua:");
        if ([bridge respondsToSelector:execSel]) {
            [bridge performSelector:execSel withObject:script];
        }
    }
    
    // 方式3：通过 Cocos2d-x 的 CCDirector 获取当前场景并执行脚本（较为复杂，此处略）
    // 若以上都失败，可考虑通过 Hook 游戏内部的关键函数（如资源修改接口）直接修改数值
}

// 显示提示框
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
    
    // 在游戏启动后创建悬浮按钮并注册通知
    dispatch_async(dispatch_get_main_queue(), ^{
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserverForName:kEnableInfiniteResourcesNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            // 执行Lua脚本修改资源（具体脚本内容需根据游戏内部API调整）
            NSString *script = @"\
                -- 假设游戏内有以下函数或全局变量\
                if setMagicBirdCount then setMagicBirdCount(999) end\
                if setEnergy then setEnergy(999) end\
                if setCoin then setCoin(999999) end\
                -- 或直接修改全局变量\
                if magicBirdCount then magicBirdCount = 999 end\
                if energy then energy = 999 end\
                if coin then coin = 999999 end\
                -- 若有游戏管理器对象\
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
        [button addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [floatingWindow addSubview:button];
        
        // 拖拽手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [button addGestureRecognizer:pan];
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
    // 构造函数，可做额外初始化
}