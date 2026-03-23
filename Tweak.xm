// Tweak.xm - 专门针对 DDVipViewController
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void FomzPro_ActivateVIP() {
    Class loginManagerClass = NSClassFromString(@"DDLoginManager");
    if (loginManagerClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        id loginManager = nil;
        
        if ([loginManagerClass respondsToSelector:sharedSel]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            loginManager = [loginManagerClass performSelector:sharedSel];
            #pragma clang diagnostic pop
        }
        
        if (loginManager) {
            SEL setVipSel = NSSelectorFromString(@"setVipStatus:");
            if ([loginManager respondsToSelector:setVipSel]) {
                NSNumber *value = [NSNumber numberWithBool:YES];
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [loginManager performSelector:setVipSel withObject:value];
                #pragma clang diagnostic pop
            }
        }
    }
}

%hook DDVipViewController

- (void)onPayButtonTouch {
    FomzPro_ActivateVIP();
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRecoveryButtonTouch {
    FomzPro_ActivateVIP();
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onItemViewTouchWithGesture:(id)sender {
    FomzPro_ActivateVIP();
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIButton *payButton = [self valueForKey:@"payButton"];
        if (payButton) payButton.hidden = YES;
        
        UILabel *payDesLabel = [self valueForKey:@"payDesLabel"];
        if (payDesLabel) {
            payDesLabel.text = @"已解锁";
            payDesLabel.textColor = [UIColor systemGreenColor];
        }
    });
}

%end

%hook NSObject

- (BOOL)vipStatus { return YES; }
- (BOOL)isVIP { return YES; }
- (BOOL)isVip { return YES; }
- (BOOL)isProUser { return YES; }
- (BOOL)hasProPermission { return YES; }
- (BOOL)isPro { return YES; }
- (long long)vipExpiredTs { return 4092599349; }

%end

%ctor {
    NSLog(@"FomzPro: Loaded");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        FomzPro_ActivateVIP();
    });
}