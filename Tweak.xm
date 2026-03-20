#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// 目标类和方法
static void (*orig_button_Login)(id self, SEL _cmd);
static void new_button_Login(id self, SEL _cmd) {
    NSLog(@"[Bypass] button_Login hooked, bypassing registration code.");
    
    // 1. 显示绕过提示（利用原类中的 showAlertWithMessage: 方法）
    if ([self respondsToSelector:@selector(showAlertWithMessage:)]) {
        [self showAlertWithMessage:@"注册码已跳过，直接登录成功！"];
    } else {
        // 如果原类没有该方法，就用 UIAlertController 自己弹窗
        UIViewController *vc = [self _viewController]; // 自定义方法，见下文
        if (vc) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"绕过" message:@"注册码已跳过" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [vc presentViewController:alert animated:YES completion:nil];
        }
    }
    
    // 2. 模拟登录成功：修改状态栏提示（如果存在 status_res 属性）
    if ([self respondsToSelector:@selector(setStatus_res:)]) {
        [self setStatus_res:@"登录成功（绕过）"];
    }
    
    // 3. 退出登录界面（假设登录界面是模态弹出或导航栈中的控制器）
    //    通过响应链找到所属的 UIViewController
    UIViewController *vc = [self _viewController];
    if (vc.navigationController) {
        // 如果在导航栈中，pop 回上一页
        [vc.navigationController popViewControllerAnimated:YES];
    } else if (vc.presentingViewController) {
        // 如果是模态 present 出来的，dismiss 掉
        [vc dismissViewControllerAnimated:YES completion:nil];
    } else {
        // 如果找不到合适的跳转方式，至少让界面看起来刷新了
        [self setNeedsLayout];
    }
    
    // 不调用原始 button_Login 方法，彻底绕过验证
    // orig_button_Login(self, _cmd);  // 如果需要保留原始行为，可以取消注释这行
}

// 辅助方法：从 UIView 找到所在的 UIViewController
static inline UIViewController* _viewControllerFromView(UIView *view) {
    UIResponder *responder = view;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

// 为 NSObject 添加一个 category，方便调用
@interface NSObject (ViewControllerAdditions)
- (UIViewController *)_viewController;
@end

@implementation NSObject (ViewControllerAdditions)
- (UIViewController *)_viewController {
    if ([self isKindOfClass:[UIView class]]) {
        return _viewControllerFromView((UIView *)self);
    }
    return nil;
}
@end

// 构造函数：在 dylib 加载时自动执行 Hook
__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // 获取目标类和方法
    Class targetClass = NSClassFromString(@"ZSLoginView");
    if (targetClass) {
        SEL selector = @selector(button_Login);
        Method method = class_getInstanceMethod(targetClass, selector);
        if (method) {
            // 使用 MSHookMessageEx 进行 Hook
            MSHookMessageEx(targetClass, selector, (IMP)&new_button_Login, (IMP *)&orig_button_Login);
            NSLog(@"[Bypass] Hook installed on ZSLoginView button_Login");
        } else {
            NSLog(@"[Bypass] Method button_Login not found");
        }
    } else {
        NSLog(@"[Bypass] Class ZSLoginView not found");
    }
    
    [pool release];
}