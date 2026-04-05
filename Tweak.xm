#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

#define LOG(fmt, ...) NSLog(@"[UnlockVIP] " fmt, ##__VA_ARGS__)

static NSArray<NSString *> *vipKeys = @[
    @"isVip", @"vipStatus", @"userType", @"isPro",
    @"hasActiveSubscription", @"isPremiumUser", @"vipExpired"
];

/* 强制 UserDefaults 返回 VIP 相关值为 YES */
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    if ([vipKeys containsObject:defaultName]) {
        LOG(@"boolForKey: %@ -> YES", defaultName);
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    id obj = %orig;
    if ([vipKeys containsObject:defaultName]) {
        if (obj == nil || [obj boolValue] == NO) {
            LOG(@"objectForKey: %@ -> @YES", defaultName);
            return @YES;
        }
    }
    return obj;
}

%end

/* 钩子：SwiftyStoreKit 收据验证类，强制返回成功 */
%hook _TtC14SwiftyStoreKit12InAppReceipt

- (void)verifyReceipt:(id)arg1 completion:(id)arg2 {
    LOG(@"InAppReceipt verifyReceipt: 强制返回成功");
    void (^completion)(BOOL, id) = arg2;
    if (completion) {
        completion(YES, @{@"status": @0, @"receipt": @{}});
    }
    // 不调用原始方法，避免网络验证
}

%end

/* 备用：钩子 AppleReceiptValidator（如果存在） */
%hook AppleReceiptValidator

- (void)validateReceipt:(id)completion {
    LOG(@"AppleReceiptValidator validateReceipt: 强制成功");
    void (^completionBlock)(BOOL, id) = completion;
    if (completionBlock) {
        completionBlock(YES, @{});
    }
}

%end

/* 修改账户界面：显示VIP并隐藏升级按钮 */
%hook AccountViewController

- (void)viewDidLoad {
    %orig;
    id vc = self;
    if ([vc respondsToSelector:@selector(vipOrPoint)]) {
        UILabel *label = [vc performSelector:@selector(vipOrPoint)];
        label.text = @"VIP会员";
    }
    if ([vc respondsToSelector:@selector(upgradeBtn)]) {
        UIButton *btn = [vc performSelector:@selector(upgradeBtn)];
        btn.hidden = YES;
    }
}

%end

/* 主界面：隐藏广告容器并强制为付费线路 */
%hook MainTunnelViewController

- (void)viewDidLoad {
    %orig;
    id vc = self;
    if ([vc respondsToSelector:@selector(adContainer)]) {
        UIView *adView = [vc performSelector:@selector(adContainer)];
        adView.hidden = YES;
    }
    if ([vc respondsToSelector:@selector(setIsFreeLine:)]) {
        [vc performSelector:@selector(setIsFreeLine:) withObject:@NO];
    }
}

%end

/* 隧道列表：强制显示所有VIP节点 */
%hook TunnelListController

- (void)viewDidLoad {
    %orig;
    id vc = self;
    if ([vc respondsToSelector:@selector(setShowFree:)]) {
        [vc performSelector:@selector(setShowFree:) withObject:@NO];
    }
    if ([vc respondsToSelector:@selector(changeType:)]) {
        [vc performSelector:@selector(changeType:) withObject:@NO];
    }
}

%end

/* 初始化 */
%ctor {
    LOG("暴雪VPN VIP解锁插件已加载");
}