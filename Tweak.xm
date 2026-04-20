#import <UIKit/UIKit.h>
#import <substrate.h>

// 保存原始函数指针
static void (*orig_dispatch_once)(dispatch_once_t *predicate, dispatch_block_t block);
static void (*orig_dispatch_once_f)(dispatch_once_t *predicate, void *context, dispatch_function_t function);

// 安全版本 dispatch_once
void safe_dispatch_once(dispatch_once_t *predicate, dispatch_block_t block) {
    if (!predicate || !block) {
        return;
    }
    
    dispatch_once_t value = *predicate;
    const dispatch_once_t done_value = ~0ul;
    
    // 如果 token 既不是 0 也不是 ~0ul，说明已损坏
    if (value != 0 && value != done_value) {
        NSLog(@"[SafeDispatchOnce] Fix corrupted dispatch_once_t %p, value=0x%lx -> set to 0", 
              predicate, (unsigned long)value);
        *predicate = 0;
    }
    
    // 调用原始函数
    orig_dispatch_once(predicate, block);
}

void safe_dispatch_once_f(dispatch_once_t *predicate, void *context, dispatch_function_t function) {
    if (!predicate || !function) {
        return;
    }
    
    dispatch_once_t value = *predicate;
    const dispatch_once_t done_value = ~0ul;
    
    if (value != 0 && value != done_value) {
        NSLog(@"[SafeDispatchOnce] Fix corrupted dispatch_once_f token %p, value=0x%lx -> set to 0", 
              predicate, (unsigned long)value);
        *predicate = 0;
    }
    
    orig_dispatch_once_f(predicate, context, function);
}

// 构造函数，使用 MSHookFunction 挂钩
__attribute__((constructor))
void initSafeDispatchOnce() {
    // 获取 dispatch_once 和 dispatch_once_f 的地址
    void *handle = dlopen(NULL, RTLD_LAZY);
    void *dispatch_once_ptr = dlsym(handle, "dispatch_once");
    void *dispatch_once_f_ptr = dlsym(handle, "dispatch_once_f");
    dlclose(handle);
    
    if (dispatch_once_ptr) {
        MSHookFunction(dispatch_once_ptr, (void *)&safe_dispatch_once, (void **)&orig_dispatch_once);
        NSLog(@"[SafeDispatchOnce] Hooked dispatch_once");
    }
    if (dispatch_once_f_ptr) {
        MSHookFunction(dispatch_once_f_ptr, (void *)&safe_dispatch_once_f, (void **)&orig_dispatch_once_f);
        NSLog(@"[SafeDispatchOnce] Hooked dispatch_once_f");
    }
}