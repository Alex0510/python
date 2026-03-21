#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PaymentManager : NSObject
@property (nonatomic, assign) BOOL isVip;
- (BOOL)checkVipFromKeyChain;
- (id)getDataFromKeychainWithKey:(id)key;
- (id)keyForVip;
@end

@interface VIPController : UIViewController
@property (nonatomic, assign) BOOL isVip;
- (void)viewDidLoad;
- (void)applyTheme;
@end

%ctor {
    NSLog(@"AddonsPro loaded: Unlocking VIP features...");
}

%hook PaymentManager

- (BOOL)isVip {
    return YES;
}

- (BOOL)checkVipFromKeyChain {
    return YES;
}

- (id)getDataFromKeychainWithKey:(id)key {
    id result = %orig;
    if ([key isEqualToString:[self keyForVip]] || [key isEqualToString:@"vip_key"]) {
        return @(YES);
    }
    return result;
}

%end

%hook VIPController

- (BOOL)isVip {
    return YES;
}

- (void)viewDidLoad {
    %orig;
    self.isVip = YES;
    [self applyTheme];
}

%end