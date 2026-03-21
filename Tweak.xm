#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PaymentManager : NSObject
- (BOOL)isVip;
- (BOOL)checkVipFromKeyChain;
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
%end