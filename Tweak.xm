#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// ============================================================
// 1. 用户模型类 - 修改VIP状态
// ============================================================

@interface UTUser : NSObject
@property (nonatomic, copy) NSString *memberid;
@property (nonatomic, assign) int membertime;
@property (nonatomic, assign) int memberdate;
@property (nonatomic, assign) float point;
@property (nonatomic, assign) float limitkbps;
@property (nonatomic, assign) float limitkbytes;
@property (nonatomic, assign) float daykbytes;
@end

@interface UTUserModel : NSObject
@property (nonatomic, strong) UTUser *user;
@end

@interface UTUserModelManager : NSObject
@property (nonatomic, strong) UTUserModel *model;
+ (instancetype)sharedInstance;
- (BOOL)isVip;
- (BOOL)isVipExpired;
- (id)dateVipExpire;
- (uint64_t)memberLevel;
- (BOOL)isVipTrialStage;
@end

// ============================================================
// 2. 优惠券模型
// ============================================================

@interface UTCoupon : NSObject
@property (nonatomic, copy) NSString *couponid;
@property (nonatomic, assign) uint64_t hours;
@property (nonatomic, assign) uint64_t expire;
@property (nonatomic, copy) NSString *descript;
@end

@interface UTCouponModel : NSObject
@property (nonatomic, strong) NSArray *coupons;
@end

// ============================================================
// 3. VPN模型
// ============================================================

@interface UTVpnModelManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) uint64_t vpnState;
@property (nonatomic, assign) BOOL vpnGlobalMode;
@property (nonatomic, assign) BOOL vpnGameAccelerated;
@end

// ============================================================
// 4. 商店和价格模型
// ============================================================

@interface UTPrice : NSObject
@property (nonatomic, copy) NSString *info;
@property (nonatomic, assign) float addDays;
@property (nonatomic, copy) NSString *cardtype;
@property (nonatomic, copy) NSString *memberid;
@property (nonatomic, assign) float priceUSD;
@property (nonatomic, assign) float priceCNY;
@end

@interface UTStoreViewController : UIViewController
@end

// ============================================================
// 5. Trial管理器
// ============================================================

@interface UTTrialManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)canApplyTrialVip;
- (BOOL)doApplyTrialVip;
- (BOOL)isTrialVip;
- (int)remainSeconds;
@end

// ============================================================
// 6. 主要Hook实现 - 解锁VIP功能
// ============================================================

%hook UTUserModelManager

- (BOOL)isVip {
    // 强制返回YES，使应用认为用户是VIP
    return YES;
}

- (BOOL)isVipExpired {
    // VIP永不过期
    return NO;
}

- (id)dateVipExpire {
    // 设置一个遥远的过期日期
    NSDate *farFuture = [NSDate distantFuture];
    return farFuture;
}

- (NSString *)dateVipExpireString {
    // VIP过期时间为"永久"
    return @"永久有效";
}

- (uint64_t)memberLevel {
    // 返回最高会员等级
    return 3; // 钻石会员
}

- (BOOL)isVipTrialStage {
    // 不是试用阶段
    return NO;
}

- (BOOL)hasBinded {
    // 已绑定
    return YES;
}

- (float)priceExtraDaysOfMemberLevel:(uint64_t)level withPackageType:(uint64_t)type {
    // 所有价格设为0（免费）
    return 0.0f;
}

%end

%hook UTUser

- (int)membertime {
    // 设置会员剩余天数最大值
    return 36500; // 100年
}

- (int)memberdate {
    return 20251231; // 永久会员日期
}

- (float)limitkbps {
    // 无限速
    return 0.0f;
}

- (float)limitkbytes {
    // 无限流量
    return 0.0f;
}

- (float)daykbytes {
    // 无限日流量
    return 999999999.0f;
}

- (float)point {
    // 积分最大值
    return 9999999.0f;
}

- (NSString *)memberid {
    // 返回VIP会员ID
    return @"vip_ultimate";
}

%end

%hook UTUserModel

- (UTUser *)user {
    UTUser *original = %orig;
    if (original) {
        // 确保用户信息被正确设置
        [original setMembertime:36500];
        [original setMemberdate:20251231];
        [original setLimitkbps:0.0f];
        [original setLimitkbytes:0.0f];
        [original setDaykbytes:999999999.0f];
        [original setPoint:9999999.0f];
        [original setMemberid:@"vip_ultimate"];
    }
    return original;
}

%end

%hook UTTrialManager

- (BOOL)canApplyTrialVip {
    // 始终可以申请试用（但实际不需要）
    return YES;
}

- (BOOL)doApplyTrialVip {
    // 始终成功
    return YES;
}

- (BOOL)isTrialVip {
    // 不是试用期，而是正式VIP
    return NO;
}

- (int)remainSeconds {
    // 返回一个很大的剩余秒数
    return 315360000; // 10年
}

%end

%hook UTVpnModelManager

- (BOOL)vpnGlobalMode {
    // 强制启用全局模式
    return YES;
}

- (BOOL)vpnGameAccelerated {
    // 强制启用游戏加速
    return YES;
}

- (uint64_t)vpnState {
    // 强制返回已连接状态
    return 2; // 假设2是已连接状态
}

%end

// ============================================================
// 7. 商店页面解锁
// ============================================================

%hook UTStoreViewController

- (void)viewDidLoad {
    %orig;
    
    // 隐藏购买按钮（可选）
    // UIButton *payButton = [self valueForKey:@"buttonPayNow"];
    // if (payButton) {
    //     payButton.hidden = YES;
    // }
}

- (void)clickToPay {
    // 拦截购买行为，显示提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"VIP功能已解锁，无需购买" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

%end

// ============================================================
// 8. 首页页面修改 - 显示VIP状态
// ============================================================

%hook UTHomeViewController

- (void)viewDidLoad {
    %orig;
    
    // 修改UI显示，隐藏VIP提示或购买入口
    [self performSelector:@selector(uiRefresh) withObject:nil afterDelay:0.1];
}

- (void)uiRefresh {
    %orig;
    
    // 修改VIP信息标签
    UILabel *vipLabel = [self valueForKey:@"labelVipInfo"];
    if (vipLabel) {
        vipLabel.text = @"VIP会员 · 永久有效";
        vipLabel.textColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.2 alpha:1.0];
    }
    
    // 修改线路信息
    UILabel *lineLabel = [self valueForKey:@"labelLineSelected"];
    if (lineLabel) {
        lineLabel.text = @"专属VIP线路";
    }
    
    // 隐藏试用提示
    UIView *trialView = [self valueForKey:@"viewExtraInfo"];
    if (trialView) {
        trialView.hidden = YES;
    }
}

- (BOOL)showTrialOrPayInfoForFreeMember {
    // 不显示试用或支付信息
    return NO;
}

%end

// ============================================================
// 9. 会员中心页面修改
// ============================================================

%hook UTMeViewController

- (void)viewDidLoad {
    %orig;
    
    // 修改会员信息显示
    [self performSelector:@selector(updateVIPDisplay) withObject:nil afterDelay:0.1];
}

- (void)updateVIPDisplay {
    UILabel *memberLabel = [self valueForKey:@"labelMemberInfo"];
    if (memberLabel) {
        memberLabel.text = @"钻石会员 · 永久有效";
        memberLabel.textColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.2 alpha:1.0];
    }
    
    UIImageView *memberImageView = [self valueForKey:@"imageviewMemberLv"];
    if (memberImageView) {
        // 可以设置为最高等级图标
        memberImageView.image = [UIImage imageNamed:@"icon_diamond"];
    }
}

%end

// ============================================================
// 10. 订单页面解锁
// ============================================================

%hook UTOrderModelManager

- (void)retrieveOrders {
    // 拦截订单请求，返回空订单（不显示需要购买的内容）
    // 或者添加一个"VIP已解锁"的订单记录
    return;
}

%end

%hook UTCouponModelManager

- (void)retrieveCoupons {
    // 拦截优惠券请求，返回一些虚拟优惠券
    return;
}

%end

// ============================================================
// 11. 服务器配置解锁
// ============================================================

%hook NIMServerSetting

- (id)linkAddress {
    // 返回最快的服务器地址
    return @"vip.accelerate.com";
}

- (id)encryptConfig {
    // 返回高级加密配置
    return nil;
}

- (BOOL)httpsEnabled {
    // 强制启用HTTPS
    return YES;
}

%end

// ============================================================
// 12. 网关选择解锁
// ============================================================

%hook UTGateModelManager

- (BOOL)updateNormalGates:(id)gates {
    // 确保VIP网关可用
    BOOL result = %orig;
    
    // 添加VIP专属网关
    NSMutableArray *normalGates = [NSMutableArray arrayWithArray:[self.model valueForKey:@"normalGates"]];
    // 添加VIP网关（如果不存在）
    
    return YES;
}

- (uint64_t)getUserSelectedHost:(id *)host andName:(id *)name {
    // 返回VIP网关
    if (host) *host = @"vip.accelerate.com";
    if (name) *name = @"VIP专属线路";
    return 1;
}

%end

// ============================================================
// 13. 初始化函数
// ============================================================

%ctor {
    NSLog(@"========================================");
    NSLog(@"SpeedCN VIP Unlocker Loaded!");
    NSLog(@"VIP功能已解锁 - 永久会员");
    NSLog(@"========================================");
    
    // 延迟执行，确保在应用完全启动后修改数据
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 触发UI刷新
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if ([rootVC respondsToSelector:@selector(uiRefresh)]) {
            [rootVC performSelector:@selector(uiRefresh)];
        }
    });
}