#import <UIKit/UIKit.h>

#define MSG_TYPE_FLASH_PHOTO 9
#define MSG_TYPE_IMAGE 2

%hook _TtC8Qing_ios22QMessageDetailController

// 阻止撤回通知（有参数版本）
- (void)messageRecallNot:(id)arg1 {
    NSLog(@"[AntiRecall] Blocked message recall notification");
    return;
}

// 阻止撤回通知（无参数版本）
- (void)messageRecallNot {
    NSLog(@"[AntiRecall] Blocked message recall (no param)");
    return;
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
            
            // 构造图片 URL（请根据实际 CDN 地址修改）
            NSString *baseURL = @"https://cdn.qing.com/media/";
            NSString *imageURL = [NSString stringWithFormat:@"%@%@", baseURL, mediaID];
            [imagePayload setValue:imageURL forKey:@"imageURL"];
            [imagePayload setValue:imageURL forKey:@"imageThumbURL"];
            
            // 设置下载状态为已完成（2 可能代表已完成）
            [imagePayload setValue:@2 forKey:@"downloadState"];
            [imagePayload setValue:nil forKey:@"localImage"];
            
            [model setValue:imagePayload forKey:@"payload"];
            [model setValue:@(MSG_TYPE_IMAGE) forKey:@"msgType"];
            
            // 强制刷新当前 cell
            UITableView *tableView = (UITableView *)[(UIView *)self superview];
            while (tableView && ![tableView isKindOfClass:[UITableView class]]) {
                tableView = (UITableView *)[tableView superview];
            }
            if (tableView) {
                NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell *)self];
                if (indexPath) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            
            NSLog(@"[AntiRecall] Converted flash photo (mediaID: %@) to normal image", mediaID);
        }
    }
    %orig;
}

%end