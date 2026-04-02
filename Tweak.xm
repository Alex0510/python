#import <UIKit/UIKit.h>

// 消息类型常量（基于头文件 enum QingIMMsgType）
#define MSG_TYPE_FLASH_PHOTO 9   // msgtFlashPhoto
#define MSG_TYPE_IMAGE 2         // msgtImage

// 闪照状态常量（基于头文件 enum QingIMFlashPhotoStatus）
// 0=Unknown, 1=Readable, 2=Destroyed, 3=Expired
#define FLASH_PHOTO_STATUS_READABLE 1

%hook _TtC8Qing_ios22QMessageDetailController

// 防撤回：拦截消息撤回通知
- (void)messageRecallNot {
    // 不执行原方法，阻止撤回
    NSLog(@"[AntiRecall] Blocked message recall");
}

%end

%hook _TtC8Qing_ios22QMessageDetailOtherFlashImageCell

- (void)setItemModel:(_TtC8Qing_ios17QingIMChatMessage *)model {
    // 获取消息类型
    NSInteger msgType = [[model valueForKey:@"msgType"] integerValue];
    if (msgType == MSG_TYPE_FLASH_PHOTO) {
        // 获取闪照载荷
        id flashPayload = [model valueForKey:@"payload"];
        Class flashPayloadClass = NSClassFromString(@"_TtC8Qing_ios21QingIMFlashPhotoPayload");
        if ([flashPayload isKindOfClass:flashPayloadClass]) {
            // 提取闪照关键字段
            NSString *mediaID = [flashPayload valueForKey:@"mediaID"];
            NSString *thumbHash = [flashPayload valueForKey:@"thumbHash"];
            NSNumber *width = [flashPayload valueForKey:@"width"];
            NSNumber *height = [flashPayload valueForKey:@"height"];
            
            // 创建普通图片载荷
            Class imagePayloadClass = NSClassFromString(@"_TtC8Qing_ios17QingIMImagePayload");
            id imagePayload = [[imagePayloadClass alloc] init];
            [imagePayload setValue:mediaID forKey:@"mediaID"];
            [imagePayload setValue:thumbHash forKey:@"thumbHash"];
            [imagePayload setValue:width forKey:@"width"];
            [imagePayload setValue:height forKey:@"height"];
            
            // 构造图片 URL（实际 URL 规则需根据应用服务器配置，此处假设）
            NSString *imageURL = [NSString stringWithFormat:@"https://cdn.qing2000.com/private-flash-photo/%@", mediaID];
            [imagePayload setValue:imageURL forKey:@"imageURL"];
            [imagePayload setValue:imageURL forKey:@"imageThumbURL"];
            
            // 替换载荷和消息类型
            [model setValue:imagePayload forKey:@"payload"];
            [model setValue:@(MSG_TYPE_IMAGE) forKey:@"msgType"];
            
            NSLog(@"[AntiRecall] Converted flash photo to normal image (mediaID: %@)", mediaID);
        }
    }
    // 调用原方法显示单元格
    %orig;
}

%end