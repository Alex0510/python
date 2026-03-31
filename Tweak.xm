// QingAntiRecallAndFlash.xm
// 基于 qing.txt 真实类名，修复前向声明错误

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================================
// 声明需要用到的类（避免前向声明错误）
// ============================================================

@interface QingIMChatMessage : NSObject
@property (nonatomic, copy) NSString *_msgID;
@property (nonatomic, strong) id _payload;
@property (nonatomic) BOOL _isRecalled;
- (void)set_isRecalled:(BOOL)isRecalled;
- (void)set_payload:(id)payload;
@end

@interface QingIMFlashPhotoPayload : NSObject
@property (nonatomic, copy) NSString *mediaID;
@property (nonatomic, copy) NSString *thumbHash;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@end

@interface QingIMImagePayload : NSObject
@property (nonatomic, copy) NSString *mediaID;
@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, copy) NSString *imageThumbURL;
@property (nonatomic, copy) NSString *thumbHash;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@end

// 撤回请求类（用于可选 hook）
@interface QingIMRecallMessageRequest : NSObject
@property (nonatomic) long long convType;
@property (nonatomic, copy) NSString *convID;
@property (nonatomic, copy) NSString *msgID;
- (void)send; // 假设的发送方法
@end

// ============================================================
// 防撤回：禁止标记 _isRecalled 为 YES
// ============================================================

%hook QingIMChatMessage

- (void)set_isRecalled:(BOOL)isRecalled {
    if (isRecalled) {
        NSLog(@"[AntiRecall] 阻止撤回消息 msgId=%@", self._msgID);
        return; // 不调用原始方法，消息保持未撤回状态
    }
    %orig;
}

// ============================================================
// 闪照转普通图片：在设置 payload 时替换
// ============================================================

- (void)set_payload:(id)payload {
    Class flashClass = NSClassFromString(@"QingIMFlashPhotoPayload");
    if (flashClass && [payload isKindOfClass:flashClass]) {
        NSLog(@"[FlashToImage] 检测到闪照 payload，转换为普通图片 payload");
        
        Class imageClass = NSClassFromString(@"QingIMImagePayload");
        if (imageClass) {
            id imagePayload = [[imageClass alloc] init];
            // 复制闪照中的媒体信息
            [imagePayload setValue:[payload valueForKey:@"mediaID"] forKey:@"mediaID"];
            [imagePayload setValue:[payload valueForKey:@"thumbHash"] forKey:@"thumbHash"];
            [imagePayload setValue:[payload valueForKey:@"width"] forKey:@"width"];
            [imagePayload setValue:[payload valueForKey:@"height"] forKey:@"height"];
            // 构造图片 URL（需根据实际业务调整）
            NSString *mediaID = [payload valueForKey:@"mediaID"];
            [imagePayload setValue:[NSString stringWithFormat:@"https://qing.com/image/%@", mediaID] forKey:@"imageURL"];
            [imagePayload setValue:[NSString stringWithFormat:@"https://qing.com/thumb/%@", mediaID] forKey:@"imageThumbURL"];
            
            payload = imagePayload;
            // 可选：修改消息类型（假设消息有 _msgType 字段，2 表示图片）
            // [self setValue:@2 forKey:@"_msgType"];
        }
    }
    %orig(payload);
}

%end

// ============================================================
// 可选：拦截撤回请求的发送（双重保险）
// ============================================================

%hook QingIMRecallMessageRequest

- (void)send {
    NSLog(@"[AntiRecall] 拦截撤回请求发送，msgID=%@", self.msgID);
    // 不调用原始方法，阻止请求发出
    // return;
    %orig; // 如果希望完全阻止，注释掉这一行
}

%end

// ============================================================
// UI 提示：为转换后的消息添加标签（简化版）
// ============================================================

%hook UITableViewCell

- (UIView *)contentView {
    // 仅处理聊天消息 Cell（根据实际 Cell 类名调整）
    NSString *cellClass = NSStringFromClass(self.class);
    if (![cellClass containsString:@"QMessageDetail"]) {
        return %orig;
    }
    
    UIView *cv = %orig;
    
    // 获取消息对象（假设 Cell 有 message 属性）
    id message = nil;
    if ([self respondsToSelector:@selector(message)]) {
        message = [self performSelector:@selector(message)];
    }
    if (!message) return cv;
    
    id payload = [message valueForKey:@"_payload"];
    NSString *tipText = nil;
    
    // 如果 payload 是图片类型且之前是闪照（需要额外标记，这里简单判断 payload 类名）
    Class imageClass = NSClassFromString(@"QingIMImagePayload");
    if (imageClass && [payload isKindOfClass:imageClass]) {
        // 由于无法区分是原始图片还是转换来的，可以添加自定义标记
        // 在 set_payload: 中给 message 添加一个属性，这里略
        // tipText = @"该闪照已自动转为普通图片";
    }
    
    if (tipText) {
        CGFloat labelTop = cv.frame.size.height - 14;
        CGFloat labelLeft = 12;
        CGRect labelFrame = CGRectMake(labelLeft, labelTop, cv.frame.size.width - 24, 14);
        NSInteger tag = 20250403;
        UILabel *tipLabel = (UILabel *)[self viewWithTag:tag];
        if (!tipLabel) {
            tipLabel = [[UILabel alloc] init];
            tipLabel.tag = tag;
            tipLabel.font = [UIFont systemFontOfSize:10];
            tipLabel.textColor = [UIColor grayColor];
            tipLabel.backgroundColor = [UIColor clearColor];
            [self addSubview:tipLabel];
        }
        tipLabel.frame = labelFrame;
        tipLabel.text = tipText;
    }
    
    return cv;
}

%end

// ============================================================
// 构造函数
// ============================================================

%ctor {
    NSLog(@"[QingAntiRecallAndFlash] Loaded successfully. Hooks installed.");
}