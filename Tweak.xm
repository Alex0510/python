#import <Foundation/Foundation.h>
#include <stdio.h>

// 使用汇编定义缺失的 Swift 符号
__asm__(
    ".globl _$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu\n"
    "_$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu:\n"
    "ret\n"
);

// 构造函数，用于确认插件已加载
__attribute__((constructor))
static void init() {
    NSLog(@"[PythonIDEFix] 插件已加载，已提供缺失符号伪装。");
}
