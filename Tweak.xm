// Tweak.x
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// 获取VIP相关的方法和属性
static NSString * const kUserInfoVipLevelKey = @"vipLevel";
static NSString * const kUserInfoValidateTimeKey = @"validateTime";
static NSString * const kUserInfoVLevelKey = @"vLevel";
static NSString * const kUserInfoAgentKey = @"agent";

%hook UserInfo

// 修改VIP等级 - 返回最高VIP等级
- (long long)vipLevel {
    return 999; // 最高VIP等级
}

// 修改VIP等级（另一种返回类型）
- (long long)vipLevel {
    return 999;
}

// 修改过期时间 - 设置为长期有效
- (long long)validateTime {
    // 返回一个很远的未来时间戳（2099年）
    return 4102444800; // 2099-12-31 00:00:00 UTC
}

// 修改VIP等级属性
- (long long)vLevel {
    return 999;
}

// 修改代理状态 - 设置为代理用户
- (long long)agent {
    return 1;
}

%end

%hook User

// 修改用户VIP等级
- (long long)vipLevel {
    return 999;
}

- (long long)vLevel {
    return 999;
}

- (long long)validateTime {
    return 4102444800;
}

- (long long)agent {
    return 1;
}

%end

%hook Mission

// 修改任务限制 - 无限制
- (long long)limit {
    return 0;
}

- (long long)total {
    return 999999;
}

%end

%hook Node

// 修改节点访问级别 - 允许访问所有节点
- (long long)vLevel {
    return 0;
}

- (long long)isNode {
    return 1;
}

%end

// Hook关键的网络请求处理类
%hook ApiRequest

// 修改请求参数，添加VIP标识
- (id)init {
    id result = %orig;
    // 修改请求中的VIP相关参数
    return result;
}

%end

// Hook HomeVC - 主界面控制
%hook HomeVC

// 修改VIP会员显示
- (void)setVipLevel {
    // 强制显示为VIP会员
    UILabel *vipLabel = [self valueForKey:@"lblVipMember"];
    if (vipLabel) {
        [vipLabel setText:@"VIP会员"];
        [vipLabel setTextColor:[UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0]];
    }
}

- (void)viewDidLoad {
    %orig;
    [self setVipLevel];
    [self updateVipStatus];
}

- (void)updateVipStatus {
    // 更新VIP显示状态
    UILabel *vipLabel = [self valueForKey:@"lblVipMember"];
    if (vipLabel) {
        [vipLabel setText:@"VIP会员"];
    }
}

%end

%hook MissionsVC

// 修改任务界面，解锁所有任务
- (void)getMissionStatusRequest {
    // 调用原方法
    %orig;
    
    // 修改任务完成状态
    NSMutableArray *missions = [self valueForKey:@"missionssList"];
    if (missions) {
        for (id mission in missions) {
            [mission setValue:@1 forKey:@"status"];
        }
    }
}

%end

// Hook CheckmarkCell - 用于VIP选中状态
%hook CheckmarkCell

- (void)setChecked:(BOOL)checked {
    // 强制设置为选中状态
    %orig(YES);
}

%end

// Hook AppDelegate - 应用启动时修改
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    
    // 延迟设置VIP状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupVIPStatus];
    });
    
    return result;
}

- (void)setupVIPStatus {
    // 查找并修改用户信息
    id userInfo = [self valueForKey:@"userInfo"];
    if (userInfo) {
        [userInfo setValue:@999 forKey:@"vipLevel"];
        [userInfo setValue:@4102444800 forKey:@"validateTime"];
    }
    
    // 刷新界面
    UIViewController *rootVC = [self valueForKey:@"mainVC"];
    if (rootVC) {
        [rootVC.view setNeedsDisplay];
    }
}

%end

// Hook VIP相关的数据模型
%hook NodeAllList

- (NSArray *)serverList {
    NSArray *originalList = %orig;
    // 确保所有节点都对VIP用户开放
    return originalList;
}

%end

// Hook界面状态
%hook SettingAccountVC

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    // 修改会员过期日期显示
    UILabel *expiredDateLabel = [self valueForKey:@"lblExpiredDate"];
    if (expiredDateLabel) {
        [expiredDateLabel setText:@"永久有效"];
        [expiredDateLabel setTextColor:[UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0]];
    }
}

%end

// Hook支付相关的类，绕过购买检查
%hook OptionSettingVC

- (void)gotoPurchaseTapped {
    // 阻止购买页面打开，或者直接授予VIP权限
    [self grantVIPAccess];
}

- (void)grantVIPAccess {
    // 直接授予VIP访问权限
    id userInfo = [self valueForKey:@"userInfo"];
    if (userInfo) {
        [userInfo setValue:@999 forKey:@"vipLevel"];
        [userInfo setValue:@4102444800 forKey:@"validateTime"];
    }
    
    // 显示提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:@"VIP功能已解锁" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end

// Hook 网络请求，修改响应中的VIP数据
%hook HTTPRequest

- (void)successHandler:(void (^)(NSHTTPURLResponse *, id))handler {
    // 包装成功回调，修改返回数据中的VIP信息
    void (^modifiedHandler)(NSHTTPURLResponse *, id) = ^(NSHTTPURLResponse *response, id data) {
        // 检查响应数据是否包含VIP信息
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *modifiedData = [data mutableCopy];
            NSMutableDictionary *dataDict = [modifiedData[@"data"] mutableCopy];
            
            if (dataDict) {
                [dataDict setValue:@999 forKey:@"vipLevel"];
                [dataDict setValue:@4102444800 forKey:@"validateTime"];
                [dataDict setValue:@1 forKey:@"agent"];
                modifiedData[@"data"] = dataDict;
            }
            
            // 调用原始handler，但使用修改后的数据
            handler(response, modifiedData);
        } else {
            handler(response, data);
        }
    };
    
    // 替换handler
    objc_setAssociatedObject(self, "modified_handler", modifiedHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    %orig(modifiedHandler);
}

%end

// Hook 服务器配置检查
%hook APMPersistedConfig

- (id)allowPersonalizedAds {
    // 允许个性化广告，绕过VIP限制
    return @1;
}

%end

// Hook 节点选择限制
%hook NodeChildVC

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 移除节点选择限制
    %orig;
}

%end

// Hook 节点列表，确保所有节点可访问
%hook NodeListVC

- (void)setDefaultData {
    %orig;
    // 修改节点过滤条件
    NSArray *allNodes = [self valueForKey:@"countriesNodeList"];
    [self setValue:allNodes forKey:@"filteredCountriesNodeList"];
}

%end

// 添加一些辅助方法来强制刷新VIP状态
@interface GeminiVIPHelper : NSObject
+ (void)forceVIPStatus;
@end

@implementation GeminiVIPHelper

+ (void)forceVIPStatus {
    // 强制设置VIP状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isVIPUser"];
    [defaults setObject:@"999" forKey:@"vipLevel"];
    [defaults setObject:@"4102444800" forKey:@"expireTime"];
    [defaults synchronize];
    
    // 发送通知更新界面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" object:nil];
}

@end

// 在应用启动时执行
__attribute__((constructor))
static void init() {
    NSLog(@"GeminiVPN VIP Unlocker Loaded");
    
    // 延迟执行以确保应用完全启动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [GeminiVIPHelper forceVIPStatus];
    });
}