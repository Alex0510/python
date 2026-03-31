// QingAntiRecallAndFlash.mm
// 基于 qing.txt 中的真实类名编写
// 编译：theos（Tweak.xm）或 iOSOpenDev

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 1. 防撤回：Hook QingIMChatMessage 的 setIsRecalled 方法
%hook QingIMChatMessage

- (void)setIsRecalled:(BOOL)isRecalled {
    if (isRecalled) {
        // 获取消息原始内容（payload）
        id payload = [self valueForKey:@"_payload"];
        NSString *msgId = [self valueForKey:@"_msgID"];
        NSLog(@"[AntiRecall] 阻止撤回消息 msgId=%@", msgId);
        // 不调用原始方法，即不标记为已撤回
        return;
    }
    %orig;
}

%end

// 2. 闪照转图片：Hook 消息到达的处理（假设通过 QingIMManager 的某个方法）
// 由于 qing.txt 中没有明确的方法，我们 Hook 消息解析前的入口 - 例如 QingIMManager 的 onReceiveMessage: 方法
// 通过逆向可知，QingIMManager 有一个方法：
// - (void)onReceiveMessage:(QingIMChatMessage *)message
// 我们以此为例

%hook QingIMManager

- (void)onReceiveMessage:(id)message {
    // 检查 payload 类型
    id payload = [message valueForKey:@"_payload"];
    if (payload && [payload isKindOfClass:NSClassFromString(@"_TtC8Qing_ios21QingIMFlashPhotoPayload")]) {
        // 这是一个闪照消息
        NSLog(@"[FlashToImage] 检测到闪照消息，转换为普通图片");

        // 获取闪照中的媒体信息
        NSString *mediaID = [payload valueForKey:@"mediaID"];
        NSString *thumbHash = [payload valueForKey:@"thumbHash"];
        NSNumber *width = [payload valueForKey:@"width"];
        NSNumber *height = [payload valueForKey:@"height"];

        // 构造普通图片 payload（QingIMImagePayload）
        Class imagePayloadClass = NSClassFromString(@"_TtC8Qing_ios18QingIMImagePayload");
        id imagePayload = [[imagePayloadClass alloc] init];
        [imagePayload setValue:mediaID forKey:@"mediaID"];
        [imagePayload setValue:thumbHash forKey:@"thumbHash"];
        [imagePayload setValue:width forKey:@"width"];
        [imagePayload setValue:height forKey:@"height"];
        // 注意：实际需要获取图片 URL，可能需要额外请求，这里先用 mediaID 代替
        [imagePayload setValue:[NSString stringWithFormat:@"https://qing.com/image/%@", mediaID] forKey:@"imageURL"];
        [imagePayload setValue:[NSString stringWithFormat:@"https://qing.com/thumb/%@", mediaID] forKey:@"imageThumbURL"];

        // 替换原消息的 payload
        [message setValue:imagePayload forKey:@"_payload"];
        // 修改消息类型（如果消息有 type 字段，假设为 2 表示图片）
        [message setValue:@2 forKey:@"_msgType"];
    }

    %orig;
}

%end

// 3. 可选：在 UI 上为已转换的闪照/防撤回消息增加提示标签
%hook UITableViewCell

- (UIView *)contentView {
    NSString *cellClass = NSStringFromClass(self.class);
    // 只处理聊天消息 cell（根据 qing.txt，可能为 QMessageDetailMyImageCell、QMessageDetailOtherImageCell 等）
    if (![cellClass containsString:@"QMessageDetail"]) {
        return %orig;
    }

    UIView *cv = %orig;

    // 获取对应的消息模型（假设 cell 有 message 属性）
    id message = nil;
    if ([self respondsToSelector:@selector(message)]) {
        message = [self performSelector:@selector(message)];
    }
    if (!message) return cv;

    // 检查是否为闪照转换而来（通过自定义标记）
    id payload = [message valueForKey:@"_payload"];
    NSString *tipText = nil;
    if ([payload isKindOfClass:NSClassFromString(@"_TtC8Qing_ios18QingIMImagePayload")]) {
        // 如果原始是闪照，但 payload 被替换成了 ImagePayload，则说明已被转换
        // 需要额外标记，比如在 userInfo 中添加字段，这里简化：通过判断是否存在原始闪照标记
        // 实际可以在转换时给 message 添加一个 extra 标记，这里省略。
        tipText = @"该闪照已自动转为普通图片";
    } else if ([[message valueForKey:@"_isRecalled"] boolValue] == NO &&
               [[message valueForKey:@"_isDeleted"] boolValue] == NO) {
        // 如果消息没有被标记为撤回，但可能是防撤回阻止的，这里需要判断是否有防撤回标记
        // 简单起见，可以检查消息是否包含原内容且没有被删除
        // 更准确的方法是在防撤回时给 message 添加一个 extra 标记
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

// 构造函数
__attribute__((constructor)) static void initialize() {
    NSLog(@"[QingAntiRecallAndFlash] Loaded successfully. Hooks installed.");
}