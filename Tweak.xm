#import <UIKit/UIKit.h>
#import <dlfcn.h>
#include "fishhook.h"

// 保存原始函数指针
static void (*orig_dispatch_once)(dispatch_once_t *predicate, dispatch_block_t block);
static void (*orig_dispatch_once_f)(dispatch_once_t *predicate, void *context, dispatch_function_t function);

// 安全版本 dispatch_once
void safe_dispatch_once(dispatch_once_t *predicate, dispatch_block_t block) {
    if (!predicate || !block) return;
    
    // 检查 token 是否处于非法状态（既不是0也不是~0ul）
    dispatch_once_t value = *predicate;
    const dispatch_once_t done_value = ~0ul;
    
    if (value != 0 && value != done_value) {
        // token 损坏，修复为未执行状态
        NSLog(@"[SafeDispatchOnce] Fix corrupted dispatch_once_t %p, value=%lx -> set to 0", predicate, (unsigned long)value);
        *predicate = 0;
    }
    
    // 调用原始 dispatch_once
    orig_dispatch_once(predicate, block);
}

// 安全版本 dispatch_once_f
void safe_dispatch_once_f(dispatch_once_t *predicate, void *context, dispatch_function_t function) {
    if (!predicate || !function) return;
    
    dispatch_once_t value = *predicate;
    const dispatch_once_t done_value = ~0ul;
    
    if (value != 0 && value != done_value) {
        NSLog(@"[SafeDispatchOnce] Fix corrupted dispatch_once_f token %p, value=%lx -> set to 0", predicate, (unsigned long)value);
        *predicate = 0;
    }
    
    orig_dispatch_once_f(predicate, context, function);
}

// 初始化 hook
__attribute__((constructor))
void initSafeDispatchOnce() {
    // 重绑定 dispatch_once 和 dispatch_once_f
    struct rebinding bindings[] = {
        {"dispatch_once", (void *)safe_dispatch_once, (void **)&orig_dispatch_once},
        {"dispatch_once_f", (void *)safe_dispatch_once_f, (void **)&orig_dispatch_once_f}
    };
    rebind_symbols(bindings, 2);
    NSLog(@"[SafeDispatchOnce] Installed hooks for dispatch_once family");
}