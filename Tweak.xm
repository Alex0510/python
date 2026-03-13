#import <Foundation/Foundation.h>
#include <stdio.h>

// 汇编符号存根（基于崩溃日志中的符号名，加前导下划线）
__asm__(
    ".globl __$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu\n"
    "__$s11ActivityKit0A0C3end_15dismissalPolicyyAA0A7ContentVy0F5StateQzGSg_AA0a11UIDismissalE0VtYaFTjTu:\n"
    "    ret\n"
);

// 额外可能缺失的符号（基于 Swift ActivityKit 常见 API）
__asm__(
    ".globl __$s11ActivityKit0A0C6request_5datayAA0A5State_pAA0A7ContentV_xtYaFTjTu\n"
    "__$s11ActivityKit0A0C6request_5datayAA0A5State_pAA0A7ContentV_xtYaFTjTu:\n"
    "    ret\n"
);

__asm__(
    ".globl __$s11ActivityKit0A0C6update_5datayAA0A7ContentV_xtYaFTjTu\n"
    "__$s11ActivityKit0A0C6update_5datayAA0A7ContentV_xtYaFTjTu:\n"
    "    ret\n"
);

__asm__(
    ".globl __$s11ActivityKit0A0C3endyyYaFTjTu\n"
    "__$s11ActivityKit0A0C3endyyYaFTjTu:\n"
    "    ret\n"
);

// 构造函数：写入文件并输出日志
__attribute__((constructor))
static void init() {
    NSString *logPath = @"/var/mobile/PythonIDEFix_loaded.txt";
    NSString *message = [NSString stringWithFormat:@"插件加载时间: %@\n", [NSDate date]];
    [message writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"[PythonIDEFix] 插件已加载，已填补 ActivityKit 符号。");
}