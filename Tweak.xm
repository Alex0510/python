// Tweak.x
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>

// AES密钥和IV
static NSString * const kAESKey = @"!eRT8&^&-v+t-z2vC2fX9p^u2pDCV_Qc";
static NSString * const kAESIV = @"MLRzB6w+wY136832";

#pragma mark - AES解密类
@interface AESDecryptor : NSObject
+ (NSData *)AES128CBCDecrypt:(NSData *)data key:(NSString *)key iv:(NSString *)iv;
+ (NSString *)decryptString:(NSString *)base64String key:(NSString *)key iv:(NSString *)iv;
+ (NSDictionary *)decryptAndParseJSON:(NSString *)base64String;
+ (NSString *)encryptString:(NSString *)plainText key:(NSString *)key iv:(NSString *)iv;
@end

@implementation AESDecryptor

+ (NSData *)AES128CBCDecrypt:(NSData *)data key:(NSString *)key iv:(NSString *)iv {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return nil;
}

+ (NSString *)decryptString:(NSString *)base64String key:(NSString *)key iv:(NSString *)iv {
    if (!base64String || base64String.length == 0) return nil;
    
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    if (!encryptedData) return nil;
    
    NSData *decryptedData = [self AES128CBCDecrypt:encryptedData key:key iv:iv];
    if (!decryptedData) return nil;
    
    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)decryptAndParseJSON:(NSString *)base64String {
    NSString *decrypted = [self decryptString:base64String key:kAESKey iv:kAESIV];
    if (!decrypted) return nil;
    
    NSData *jsonData = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"[VIPUnlocker] JSON parse error: %@", error);
        return nil;
    }
    return json;
}

+ (NSString *)encryptString:(NSString *)plainText key:(NSString *)key iv:(NSString *)iv {
    if (!plainText) return nil;
    
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    bzero(ivPtr, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [plainData length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          [plainData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    
    if (cryptStatus == kCCSuccess) {
        NSData *encryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
        return [encryptedData base64EncodedStringWithOptions:0];
    }
    
    free(buffer);
    return nil;
}

+ (NSString *)convertDictionaryToJSONString:(NSDictionary *)dict {
    if (!dict) return @"{}";
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (jsonData && !error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return @"{}";
}

@end

#pragma mark - 辅助类
@interface VIPUnlockerHelper : NSObject
+ (void)forceVIPStatus;
+ (void)updateVIPDisplayForViewController:(UIViewController *)vc;
+ (NSDictionary *)modifyVIPInResponseData:(NSDictionary *)responseData;
+ (void)modifyLabelsInView:(UIView *)view;
@end

@implementation VIPUnlockerHelper

+ (void)forceVIPStatus {
    NSLog(@"[VIPUnlocker] ===== Forcing VIP status =====");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isVIPUser"];
    [defaults setObject:@(999) forKey:@"vipLevel"];
    [defaults setObject:@"永久有效" forKey:@"expireDate"];
    [defaults setObject:@(4102444800) forKey:@"expireTimestamp"];
    [defaults synchronize];
    
    // 尝试通过AppDelegate修改userInfo
    id appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate) {
        id userInfo = [appDelegate valueForKey:@"userInfo"];
        if (userInfo) {
            [userInfo setValue:@(999) forKey:@"vipLevel"];
            [userInfo setValue:@(4102444800) forKey:@"validateTime"];
            [userInfo setValue:@"永久有效" forKey:@"expireDate"];
            NSLog(@"[VIPUnlocker] Modified userInfo");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" object:nil];
}

+ (NSDictionary *)modifyVIPInResponseData:(NSDictionary *)responseData {
    if (!responseData) return responseData;
    
    NSMutableDictionary *modifiedData = [responseData mutableCopy];
    
    // 修改data字段
    id dataField = modifiedData[@"data"];
    if ([dataField isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dataDict = [dataField mutableCopy];
        [dataDict setValue:@(999) forKey:@"vipLevel"];
        [dataDict setValue:@(4102444800) forKey:@"validateTime"];
        [dataDict setValue:@"永久有效" forKey:@"expireDate"];
        [dataDict setValue:@(1) forKey:@"agent"];
        modifiedData[@"data"] = dataDict;
        NSLog(@"[VIPUnlocker] Modified VIP fields in data");
    }
    
    // 修改根级别字段
    if (modifiedData[@"vipLevel"]) [modifiedData setValue:@(999) forKey:@"vipLevel"];
    if (modifiedData[@"validateTime"]) [modifiedData setValue:@(4102444800) forKey:@"validateTime"];
    if (modifiedData[@"expireDate"]) [modifiedData setValue:@"永久有效" forKey:@"expireDate"];
    
    return modifiedData;
}

+ (void)updateVIPDisplayForViewController:(UIViewController *)vc {
    if (!vc) return;
    
    // 检查是否是账户页面 - 使用字符串类名避免前向声明问题
    if ([NSStringFromClass([vc class]) isEqualToString:@"SettingAccountVC"]) {
        // 使用KVC获取标签
        UILabel *expiredLabel = [vc valueForKey:@"lblExpiredDate"];
        if (expiredLabel && [expiredLabel isKindOfClass:[UILabel class]]) {
            expiredLabel.text = @"永久有效";
            expiredLabel.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0];
            NSLog(@"[VIPUnlocker] Set lblExpiredDate to '永久有效'");
        }
        
        // 修改购买按钮
        UIButton *purchaseBtn = [vc valueForKey:@"btnPurchaseVIP"];
        if (purchaseBtn && [purchaseBtn isKindOfClass:[UIButton class]]) {
            [purchaseBtn setTitle:@"VIP已解锁" forState:UIControlStateNormal];
            purchaseBtn.enabled = NO;
            purchaseBtn.alpha = 0.5;
            NSLog(@"[VIPUnlocker] Disabled purchase button");
        }
    }
    
    // 检查是否是主页 - 使用字符串类名
    if ([NSStringFromClass([vc class]) isEqualToString:@"HomeVC"]) {
        UILabel *vipLabel = [vc valueForKey:@"lblVipMember"];
        if (vipLabel && [vipLabel isKindOfClass:[UILabel class]]) {
            vipLabel.text = @"VIP会员";
            vipLabel.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
            NSLog(@"[VIPUnlocker] Set VIP label to 'VIP会员'");
        }
    }
    
    [self modifyLabelsInView:vc.view];
}

+ (void)modifyLabelsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            
            if ([text containsString:@"購買VIP"] || 
                [text containsString:@"购买VIP"] ||
                [text containsString:@"开通VIP"]) {
                label.text = @"永久有效";
                label.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0];
                NSLog(@"[VIPUnlocker] Changed label from '%@' to '永久有效'", text);
            }
        }
        [self modifyLabelsInView:subview];
    }
}

@end

#pragma mark - HTTPRequest 类定义
@interface HTTPRequest : NSObject
- (void)successHandler:(void (^)(NSHTTPURLResponse *, id))handler;
- (NSString *)convertDictionaryToJSONString:(NSDictionary *)dict;
@end

// 为HTTPRequest添加category来添加方法
@interface HTTPRequest (VIPUnlocker)
- (NSString *)convertDictionaryToJSONString:(NSDictionary *)dict;
@end

@implementation HTTPRequest (VIPUnlocker)
- (NSString *)convertDictionaryToJSONString:(NSDictionary *)dict {
    return [AESDecryptor convertDictionaryToJSONString:dict];
}
@end

#pragma mark - UserInfo Hook
%hook UserInfo

- (long long)vipLevel {
    return 999;
}

- (long long)validateTime {
    return 4102444800;
}

- (NSString *)expireDate {
    return @"永久有效";
}

%end

#pragma mark - SettingAccountVC Hook
%hook SettingAccountVC

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VIPUnlockerHelper updateVIPDisplayForViewController:self];
    });
}

- (void)viewDidLoad {
    %orig;
    [VIPUnlockerHelper forceVIPStatus];
}

%end

#pragma mark - HomeVC Hook
%hook HomeVC

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VIPUnlockerHelper updateVIPDisplayForViewController:self];
    });
}

%end

#pragma mark - HTTPRequest Hook
%hook HTTPRequest

- (void)successHandler:(void (^)(NSHTTPURLResponse *, id))handler {
    NSLog(@"[VIPUnlocker] HTTPRequest successHandler hooked");
    
    void (^modifiedHandler)(NSHTTPURLResponse *, id) = ^(NSHTTPURLResponse *response, id data) {
        NSLog(@"[VIPUnlocker] Intercepting response data, type: %@", NSStringFromClass([data class]));
        
        id modifiedData = data;
        
        // 处理字符串类型（加密的Base64响应）
        if ([data isKindOfClass:[NSString class]]) {
            NSString *encryptedString = (NSString *)data;
            NSLog(@"[VIPUnlocker] Received encrypted response, length: %lu", (unsigned long)encryptedString.length);
            
            NSDictionary *decryptedJSON = [AESDecryptor decryptAndParseJSON:encryptedString];
            if (decryptedJSON) {
                NSLog(@"[VIPUnlocker] Successfully decrypted response");
                NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:decryptedJSON];
                NSString *jsonString = [AESDecryptor convertDictionaryToJSONString:modifiedJSON];
                NSString *reEncrypted = [AESDecryptor encryptString:jsonString key:kAESKey iv:kAESIV];
                if (reEncrypted) {
                    modifiedData = reEncrypted;
                    NSLog(@"[VIPUnlocker] Re-encrypted modified response");
                }
            }
        }
        // 处理字典类型
        else if ([data isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VIPUnlocker] Response is dictionary, modifying directly");
            NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:(NSDictionary *)data];
            modifiedData = modifiedJSON;
        }
        // 处理NSData类型
        else if ([data isKindOfClass:[NSData class]]) {
            NSData *responseData = (NSData *)data;
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (responseString) {
                NSDictionary *decryptedJSON = [AESDecryptor decryptAndParseJSON:responseString];
                if (decryptedJSON) {
                    NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:decryptedJSON];
                    NSString *jsonString = [AESDecryptor convertDictionaryToJSONString:modifiedJSON];
                    NSString *reEncrypted = [AESDecryptor encryptString:jsonString key:kAESKey iv:kAESIV];
                    if (reEncrypted) {
                        modifiedData = [reEncrypted dataUsingEncoding:NSUTF8StringEncoding];
                    }
                }
            }
        }
        
        if (handler) {
            handler(response, modifiedData);
        }
    };
    
    objc_setAssociatedObject(self, "modified_handler", modifiedHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    %orig(modifiedHandler);
}

%end

#pragma mark - AppDelegate Hook
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    NSLog(@"[VIPUnlocker] App didFinishLaunching - AES Decryptor Ready");
    BOOL result = %orig;
    
    [VIPUnlockerHelper forceVIPStatus];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [VIPUnlockerHelper updateVIPDisplayForViewController:rootVC];
        
        // 遍历tabbar查找所有页面
        if ([rootVC isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tabBar = (UITabBarController *)rootVC;
            for (UIViewController *vc in tabBar.viewControllers) {
                [VIPUnlockerHelper updateVIPDisplayForViewController:vc];
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *nav = (UINavigationController *)vc;
                    for (UIViewController *navVC in nav.viewControllers) {
                        [VIPUnlockerHelper updateVIPDisplayForViewController:navVC];
                    }
                }
            }
        }
    });
    
    return result;
}

%end

// 构造函数
__attribute__((constructor))
static void init() {
    NSLog(@"[VIPUnlocker] ========================================");
    NSLog(@"[VIPUnlocker] LiebaoVPN VIP Unlocker Loaded!");
    NSLog(@"[VIPUnlocker] AES Key: %@", kAESKey);
    NSLog(@"[VIPUnlocker] AES IV: %@", kAESIV);
    NSLog(@"[VIPUnlocker] ========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [VIPUnlockerHelper forceVIPStatus];
    });
}