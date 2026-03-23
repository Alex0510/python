// Tweak.x
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>

// AES密钥和IV（从你的信息中获取）
static NSString * const kAESKey = @"!eRT8&^&-v+t-z2vC2fX9p^u2pDCV_Qc";
static NSString * const kAESIV = @"MLRzB6w+wY136832";

// AES解密辅助类
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

@end

// 设置账户页面类
@interface SettingAccountVC : UIViewController
@property (nonatomic, strong) UILabel *lblExpiredDate;
@property (nonatomic, strong) UILabel *lblUserName;
@property (nonatomic, strong) UIButton *btnPurchaseVIP;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidLoad;
- (void)updateVIPInfo;
@end

// 用户信息类
@interface UserInfo : NSObject
@property (nonatomic, assign) long long vipLevel;
@property (nonatomic, assign) long long validateTime;
@property (nonatomic, copy) NSString *expireDate;
@end

// AppDelegate
@interface AppDelegate : UIResponder
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) id userInfo;
@end

// 辅助类
@interface VIPUnlockerHelper : NSObject
+ (void)forceVIPStatus;
+ (void)updateVIPDisplayForViewController:(UIViewController *)vc;
+ (NSDictionary *)modifyVIPInResponseData:(NSDictionary *)responseData;
@end

@implementation VIPUnlockerHelper

+ (void)forceVIPStatus {
    NSLog(@"[VIPUnlocker] ===== Forcing VIP status =====");
    
    // 强制设置VIP状态到UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isVIPUser"];
    [defaults setObject:@(999) forKey:@"vipLevel"];
    [defaults setObject:@"永久有效" forKey:@"expireDate"];
    [defaults setObject:@(4102444800) forKey:@"expireTimestamp"];
    [defaults synchronize];
    
    // 尝试修改AppDelegate中的userInfo
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate) {
        id userInfo = [appDelegate valueForKey:@"userInfo"];
        if (userInfo) {
            [userInfo setValue:@(999) forKey:@"vipLevel"];
            [userInfo setValue:@(4102444800) forKey:@"validateTime"];
            [userInfo setValue:@"永久有效" forKey:@"expireDate"];
            NSLog(@"[VIPUnlocker] Modified existing userInfo");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VIPStatusChanged" object:nil];
}

+ (NSDictionary *)modifyVIPInResponseData:(NSDictionary *)responseData {
    if (!responseData) return responseData;
    
    NSMutableDictionary *modifiedData = [responseData mutableCopy];
    
    // 修改data字段中的VIP信息
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
    
    // 修改根级别的VIP字段
    if (modifiedData[@"vipLevel"]) {
        [modifiedData setValue:@(999) forKey:@"vipLevel"];
    }
    if (modifiedData[@"validateTime"]) {
        [modifiedData setValue:@(4102444800) forKey:@"validateTime"];
    }
    if (modifiedData[@"expireDate"]) {
        [modifiedData setValue:@"永久有效" forKey:@"expireDate"];
    }
    
    return modifiedData;
}

+ (void)updateVIPDisplayForViewController:(UIViewController *)vc {
    if (!vc) return;
    
    // 检查是否是账户页面
    if ([vc isKindOfClass:NSClassFromString(@"SettingAccountVC")]) {
        // 直接设置过期时间标签
        UILabel *expiredLabel = [vc valueForKey:@"lblExpiredDate"];
        if (expiredLabel) {
            expiredLabel.text = @"永久有效";
            expiredLabel.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0];
            NSLog(@"[VIPUnlocker] Set lblExpiredDate to '永久有效'");
        }
        
        // 修改购买按钮
        UIButton *purchaseBtn = [vc valueForKey:@"btnPurchaseVIP"];
        if (purchaseBtn) {
            [purchaseBtn setTitle:@"VIP已解锁" forState:UIControlStateNormal];
            purchaseBtn.enabled = NO;
            purchaseBtn.alpha = 0.5;
            NSLog(@"[VIPUnlocker] Disabled purchase button");
        }
    }
    
    // 递归修改所有标签
    [self modifyLabelsInView:vc.view];
}

+ (void)modifyLabelsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            
            // 检查是否是VIP购买按钮文字
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

// Hook UserInfo 类
%hook UserInfo

- (long long)vipLevel {
    NSLog(@"[VIPUnlocker] UserInfo vipLevel getter -> 999");
    return 999;
}

- (long long)validateTime {
    NSLog(@"[VIPUnlocker] UserInfo validateTime getter -> 4102444800");
    return 4102444800;
}

- (NSString *)expireDate {
    return @"永久有效";
}

%end

// Hook SettingAccountVC
%hook SettingAccountVC

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"[VIPUnlocker] SettingAccountVC viewWillAppear");
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VIPUnlockerHelper updateVIPDisplayForViewController:self];
        [self.view setNeedsLayout];
    });
}

- (void)viewDidLoad {
    NSLog(@"[VIPUnlocker] SettingAccountVC viewDidLoad");
    %orig;
    
    [VIPUnlockerHelper forceVIPStatus];
}

%end

// Hook HomeVC
%hook HomeVC

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UILabel *vipLabel = [self valueForKey:@"lblVipMember"];
        if (vipLabel) {
            vipLabel.text = @"VIP会员";
            vipLabel.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
        }
    });
}

%end

// Hook HTTPRequest - 拦截并解密响应
%hook HTTPRequest

- (void)successHandler:(void (^)(NSHTTPURLResponse *, id))handler {
    NSLog(@"[VIPUnlocker] HTTPRequest successHandler hooked");
    
    void (^modifiedHandler)(NSHTTPURLResponse *, id) = ^(NSHTTPURLResponse *response, id data) {
        NSLog(@"[VIPUnlocker] Intercepting response data");
        
        id modifiedData = data;
        
        // 检查是否是字符串（加密的响应）
        if ([data isKindOfClass:[NSString class]]) {
            NSString *encryptedString = (NSString *)data;
            NSLog(@"[VIPUnlocker] Received encrypted response, length: %lu", (unsigned long)encryptedString.length);
            
            // 解密
            NSDictionary *decryptedJSON = [AESDecryptor decryptAndParseJSON:encryptedString];
            if (decryptedJSON) {
                NSLog(@"[VIPUnlocker] Successfully decrypted response");
                
                // 修改VIP信息
                NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:decryptedJSON];
                
                // 重新加密
                NSString *jsonString = [self convertDictionaryToJSONString:modifiedJSON];
                NSString *reEncrypted = [AESDecryptor encryptString:jsonString key:kAESKey iv:kAESIV];
                if (reEncrypted) {
                    modifiedData = reEncrypted;
                    NSLog(@"[VIPUnlocker] Re-encrypted modified response");
                }
            } else {
                NSLog(@"[VIPUnlocker] Failed to decrypt response");
            }
        }
        // 检查是否是字典（已解密的响应）
        else if ([data isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VIPUnlocker] Response is already dictionary");
            NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:(NSDictionary *)data];
            modifiedData = modifiedJSON;
        }
        // 检查是否是NSData
        else if ([data isKindOfClass:[NSData class]]) {
            NSData *responseData = (NSData *)data;
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (responseString) {
                NSDictionary *decryptedJSON = [AESDecryptor decryptAndParseJSON:responseString];
                if (decryptedJSON) {
                    NSDictionary *modifiedJSON = [VIPUnlockerHelper modifyVIPInResponseData:decryptedJSON];
                    NSString *jsonString = [self convertDictionaryToJSONString:modifiedJSON];
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

- (NSString *)convertDictionaryToJSONString:(NSDictionary *)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (jsonData && !error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return @"{}";
}

%end

// Hook AppDelegate
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    NSLog(@"[VIPUnlocker] App didFinishLaunching - AES Decryptor Ready");
    BOOL result = %orig;
    
    [VIPUnlockerHelper forceVIPStatus];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [VIPUnlockerHelper updateVIPDisplayForViewController:rootVC];
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
    
    [VIPUnlockerHelper forceVIPStatus];
}