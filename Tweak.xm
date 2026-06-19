#import <UIKit/UIKit.h>
#import <substrate.h>

// ============================================================
// 声明目标类（基于你提供的头文件）
// ============================================================

// ---------- 防撤回相关 ----------
@interface MPushContext : NSObject
- (BOOL)recallNotificationWithMsg:(id)arg1 isFromTCP:(BOOL)arg2;
- (void)removeNotificationWithIdentifiers:(id)arg0;
- (void)removeNotificationWithIdentifiers:(id)arg0 requestStatus:(long long)arg1;
@end

@interface MobPush : NSObject
+ (void)recallMessageWithWorkId:(id)arg0 isProductionEnvironment:(BOOL)arg1 result:(id)arg2;
@end

// ---------- 闪照相关（图片缓存） ----------
@interface MPImageCache : NSObject
- (void)removeImageForKey:(id)arg0 cacheType:(long long)arg1 completion:(id)arg2;
- (void)removeImageFromMemoryForKey:(id)arg0;
- (void)removeImageFromDiskForKey:(id)arg0;
- (void)clearMemory;
@end

@interface MPWebImageManager : NSObject
- (void)removeAllFailedURLs;
@end

// 可能用到的 UI 相关类（防御性）
@interface UIImageView : UIView
- (void)setImage:(UIImage *)image;
@end

@interface UIView : NSObject
- (void)removeFromSuperview;
@end

// ============================================================
// 第一块：消息防撤回（Hook 撤回相关方法）
// ============================================================

// 1.1 拦截接收到的撤回指令（他人撤回）
%hook MPushContext

- (BOOL)recallNotificationWithMsg:(id)arg1 isFromTCP:(BOOL)arg2 {
    NSLog(@"[MobPushKiller] 🛑 拦截到服务器撤回指令 | Msg: %@ | FromTCP: %d", arg1, arg2);
    // 不执行原始逻辑，返回 NO 表示撤回失败
    return NO;
}

// 1.2 拦截移除通知（撤回通常会导致通知移除）
- (void)removeNotificationWithIdentifiers:(id)arg0 {
    NSLog(@"[MobPushKiller] 🛑 阻止移除通知标识符: %@", arg0);
    return;
}

- (void)removeNotificationWithIdentifiers:(id)arg0 requestStatus:(long long)arg1 {
    NSLog(@"[MobPushKiller] 🛑 阻止移除通知(带状态): %@", arg0);
    return;
}

%end

// 1.3 拦截主动发起的撤回请求（你撤回别人的消息）
%hook MobPush

+ (void)recallMessageWithWorkId:(id)arg0 isProductionEnvironment:(BOOL)arg1 result:(id)arg2 {
    NSLog(@"[MobPushKiller] 🛑 拦截到主动撤回请求 | WorkId: %@", arg0);
    // 直接返回，不向服务器发送撤回指令
    return;
}

%end

// ============================================================
// 第二块：闪照转换为普通照片（阻止缓存删除 & UI 销毁）
// ============================================================

// 2.1 拦截图片缓存删除（核心）
%hook MPImageCache

- (void)removeImageForKey:(id)arg0 cacheType:(long long)arg1 completion:(id)arg2 {
    NSLog(@"[MobPushKiller] 🛑 阻止删除缓存 Key: %@", arg0);
    return;  // 不删除，永久保留
}

- (void)removeImageFromMemoryForKey:(id)arg0 {
    NSLog(@"[MobPushKiller] 🛑 阻止清除内存缓存: %@", arg0);
    return;
}

- (void)removeImageFromDiskForKey:(id)arg0 {
    NSLog(@"[MobPushKiller] 🛑 阻止清除磁盘缓存: %@", arg0);
    return;
}

- (void)clearMemory {
    NSLog(@"[MobPushKiller] 🛑 阻止 clearMemory");
    return;
}

%end

// 2.2 防御性：拦截 UIImageView 置空（闪照倒计时结束会将 image = nil）
%hook UIImageView

- (void)setImage:(UIImage *)image {
    // 如果传入 nil 且当前有图，检查是否属于闪照场景（通过类名判断）
    if (image == nil && self.image != nil) {
        UIResponder *responder = self;
        while (responder) {
            NSString *className = NSStringFromClass([responder class]);
            // 常见闪照视图关键词（根据实际 App 可扩展）
            NSArray *keywords = @[@"Flash", @"Burn", @"Secret", @"Snap", @"Flicker"];
            for (NSString *kw in keywords) {
                if ([className rangeOfString:kw options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    NSLog(@"[MobPushKiller] 🛑 阻止闪照 ImageView 置空 (类: %@)", className);
                    return;  // 不执行 setImage:nil
                }
            }
            responder = [responder nextResponder];
        }
    }
    %orig;  // 其他情况正常执行
}

%end

// 2.3 防御性：拦截闪照容器视图从父视图移除
%hook UIView

- (void)removeFromSuperview {
    // 通过 accessibilityIdentifier 或类名判断是否为闪照容器
    if ([self.accessibilityIdentifier isEqualToString:@"FlashPhotoContainer"]) {
        NSLog(@"[MobPushKiller] 🛑 阻止闪照容器移除");
        return;
    }
    // 也可通过类名判断（如含有 "Flash" 或 "Burn"）
    NSString *className = NSStringFromClass([self class]);
    if ([className rangeOfString:@"Flash" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSLog(@"[MobPushKiller] 🛑 阻止闪照视图移除 (类: %@)", className);
        return;
    }
    %orig;
}

%end

// ============================================================
// 第三块（可选）：阻止闪照倒计时定时器销毁 UI
// 由于定时器通常不直接与闪照绑定，此处仅作示例
// ============================================================
/*
%hook NSTimer
- (void)invalidate {
    // 可判断 timer 的 userInfo 是否包含闪照信息，若包含则阻止失效
    // 但为了安全，默认放行，实际可依据上下文开启
    %orig;
}
%end
*/

// ============================================================
// 第四块（可选）：拦截消息模型中的“已销毁”状态（如果有）
// 假设 App 有 MPushMessage 类，属性 isDestroyed
// ============================================================
/*
@interface MPushMessage : NSObject
@property (nonatomic, assign) BOOL isDestroyed;
@end

%hook MPushMessage
- (void)setIsDestroyed:(BOOL)isDestroyed {
    if (isDestroyed) {
        NSLog(@"[MobPushKiller] 🛑 阻止设置消息为已销毁");
        return;
    }
    %orig;
}
%end
*/