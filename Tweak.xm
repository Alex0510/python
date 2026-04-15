#import <UIKit/UIKit.h>
#import "NDFloatingView.h"

%hook UIApplication

- (void)didFinishLaunching {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [NDFloatingView show];
    });
}

%end