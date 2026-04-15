#import <UIKit/UIKit.h>
#import "NDFloatingView.h"

%hook UIDevice

- (NSUUID *)identifierForVendor {
    return [NSUUID UUID];
}

%end

%hook NSUUID

+ (NSUUID *)UUID {
    return %orig;
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [NDFloatingView show];
    });
}
