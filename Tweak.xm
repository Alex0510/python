#import <UIKit/UIKit.h>
#import <dlfcn.h>

static dispatch_once_t brokenOnceToken = 0;

// 模拟内存破坏：将 once token 写成一个非法值
__attribute__((constructor))
void triggerDispatchOnceCorruption() {
    // 先正常执行一次 dispatch_once，让 token 变为已执行状态
    dispatch_once(&brokenOnceToken, ^{
        NSLog(@"[CrashDylib] First dispatch_once executed.");
    });

    // 关键破坏步骤：强行把 token 的最后一位改成 0（模拟内存损坏）
    // 在 libdispatch 内部，token 为 0 表示未初始化，但这里 token 原本是 ~0ul 的某个值，
    // 直接清零后 dispatch_once 会认为从未执行过，但在内部检查时会因为 ulock 状态不一致而崩溃。
    // 更暴力的方式：直接 memset 为 0。
    memset(&brokenOnceToken, 0, sizeof(brokenOnceToken));

    // 再次调用 dispatch_once，libdispatch 会尝试重新初始化锁结构，从而触发 ulock 错误
    dispatch_once(&brokenOnceToken, ^{
        NSLog(@"[CrashDylib] This line will never be reached because we crash.");
    });
}