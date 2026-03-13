#import <Foundation/Foundation.h>
#include <stdio.h>

// 使用汇编提供缺失的 ActivityKit 符号
// 符号名称从崩溃日志中复制，注意在汇编中需要添加一个前导下划线
__asm__(
    ".globl __$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu\n"
    "__$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu:\n"
    "    ret\n"
);

// 构造函数：插件加载时输出日志
__attribute__((constructor))
static void init() {
    NSLog(@"[PythonIDEFix] 插件已加载，已填补缺失的 ActivityKit 符号。");
    
    // 可选：写入文件以便调试
    // NSString *logPath = @"/var/mobile/Library/Preferences/PythonIDEFix.log";
    // [@"Plugin loaded\n" writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}