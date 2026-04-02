#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

// 声明需要 Hook 的类（基于头文件中的 @interface）
CHDeclareClass(_TtC8Qing_ios22QMessageDetailController);
CHDeclareClass(_TtC8Qing_ios22QMessageDetailOtherFlashImageCell);
CHDeclareClass(_TtC8Qing_ios17QingIMChatMessage);
CHDeclareClass(_TtC8Qing_ios21QingIMFlashPhotoPayload);
CHDeclareClass(_TtC8Qing_ios17QingIMImagePayload);

// 消息类型常量（来自头文件 enum QingIMMsgType）
#define MSG_TYPE_FLASH_PHOTO 9   // 闪照
#define MSG_TYPE_IMAGE 2         // 普通图片

// 闪照状态常量（来自头文件 enum QingIMFlashPhotoStatus）
// 0=Unknown, 1=Readable, 2=Destroyed, 3=Expired
#define FLASH_PHOTO_STATUS_READABLE 1

CHOptimizeMemory

#pragma mark - 防撤回：拦截消息撤回通知
CHMethod(0, void, _TtC8Qing_ios22QMessageDetailController, messageRecallNot) {
    // 不执行原方法，阻止撤回
    NSLog(@"[AntiRecall] Blocked message recall");
}

#pragma mark - 闪照转普通图片：在单元格设置模型时转换
CHMethod(1, void, _TtC8Qing_ios22QMessageDetailOtherFlashImageCell, setItemModel, _TtC8Qing_ios17QingIMChatMessage *, model) {
    // 获取消息类型
    NSInteger msgType = [[model valueForKey:@"msgType"] integerValue];
    if (msgType == MSG_TYPE_FLASH_PHOTO) {
        // 获取闪照载荷
        id flashPayload = [model valueForKey:@"payload"];
        if ([flashPayload isKindOfClass:CHClass(_TtC8Qing_ios21QingIMFlashPhotoPayload)]) {
            // 提取闪照关键字段
            NSString *mediaID = [flashPayload valueForKey:@"mediaID"];
            NSString *thumbHash = [flashPayload valueForKey:@"thumbHash"];
            NSNumber *width = [flashPayload valueForKey:@"width"];
            NSNumber *height = [flashPayload valueForKey:@"height"];
            
            // 创建普通图片载荷
            id imagePayload = [[CHClass(_TtC8Qing_ios17QingIMImagePayload) alloc] init];
            [imagePayload setValue:mediaID forKey:@"mediaID"];
            [imagePayload setValue:thumbHash forKey:@"thumbHash"];
            [imagePayload setValue:width forKey:@"width"];
            [imagePayload setValue:height forKey:@"height"];
            
            // 构造图片 URL（实际 URL 规则需从服务器配置获取，此处假设为常见格式）
            // 注意：应用内部可能根据 mediaID 自动加载，设置 URL 可确保正常显示
            NSString *baseURL = @"https://cdn.qing2000.com/private-flash-photo/";
            NSString *imageURL = [baseURL stringByAppendingString:mediaID];
            [imagePayload setValue:imageURL forKey:@"imageURL"];
            [imagePayload setValue:imageURL forKey:@"imageThumbURL"];
            
            // 替换消息的载荷和类型
            [model setValue:imagePayload forKey:@"payload"];
            [model setValue:@(MSG_TYPE_IMAGE) forKey:@"msgType"];
            
            NSLog(@"[AntiRecall] Converted flash photo to normal image");
        }
    }
    // 调用原方法显示单元格
    CHSuper(1, _TtC8Qing_ios22QMessageDetailOtherFlashImageCell, setItemModel, model);
}

#pragma mark - 加载时钩子
CHConstructor {
    // 加载类
    CHLoadLateClass(_TtC8Qing_ios22QMessageDetailController);
    CHLoadLateClass(_TtC8Qing_ios22QMessageDetailOtherFlashImageCell);
    CHLoadLateClass(_TtC8Qing_ios17QingIMChatMessage);
    CHLoadLateClass(_TtC8Qing_ios21QingIMFlashPhotoPayload);
    CHLoadLateClass(_TtC8Qing_ios17QingIMImagePayload);
    
    // 注册 Hook
    CHHook(0, _TtC8Qing_ios22QMessageDetailController, messageRecallNot);
    CHHook(1, _TtC8Qing_ios22QMessageDetailOtherFlashImageCell, setItemModel);
    
    NSLog(@"[AntiRecall] Loaded successfully");
}