#import <UIKit/UIKit.h>

#define MSG_TYPE_FLASH_PHOTO 9
#define MSG_TYPE_IMAGE 2

%hook _TtC8Qing_ios22QMessageDetailController

- (void)messageRecallNot {
    // 阻止消息撤回
    NSLog(@"[AntiRecall] Blocked message recall");
}

%end

%hook _TtC8Qing_ios22QMessageDetailOtherFlashImageCell

- (void)setItemModel:(id)model {
    NSInteger msgType = [[model valueForKey:@"msgType"] integerValue];
    if (msgType == MSG_TYPE_FLASH_PHOTO) {
        id flashPayload = [model valueForKey:@"payload"];
        Class flashPayloadClass = NSClassFromString(@"_TtC8Qing_ios21QingIMFlashPhotoPayload");
        if ([flashPayload isKindOfClass:flashPayloadClass]) {
            NSString *mediaID = [flashPayload valueForKey:@"mediaID"];
            NSString *thumbHash = [flashPayload valueForKey:@"thumbHash"];
            NSNumber *width = [flashPayload valueForKey:@"width"];
            NSNumber *height = [flashPayload valueForKey:@"height"];
            
            Class imagePayloadClass = NSClassFromString(@"_TtC8Qing_ios17QingIMImagePayload");
            id imagePayload = [[imagePayloadClass alloc] init];
            [imagePayload setValue:mediaID forKey:@"mediaID"];
            [imagePayload setValue:thumbHash forKey:@"thumbHash"];
            [imagePayload setValue:width forKey:@"width"];
            [imagePayload setValue:height forKey:@"height"];
            
            // 构造图片 URL（需根据实际 CDN 地址调整）
            NSString *imageURL = [NSString stringWithFormat:@"https://cdn.qing2000.com/private-flash-photo/%@", mediaID];
            [imagePayload setValue:imageURL forKey:@"imageURL"];
            [imagePayload setValue:imageURL forKey:@"imageThumbURL"];
            
            [model setValue:imagePayload forKey:@"payload"];
            [model setValue:@(MSG_TYPE_IMAGE) forKey:@"msgType"];
            
            NSLog(@"[AntiRecall] Converted flash photo (mediaID: %@)", mediaID);
        }
    }
    %orig;
}

%end