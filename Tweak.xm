#import <UIKit/UIKit.h>

%hook BDLiveServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES]; // 改为方法调用
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    [self setHidden:YES]; // 确保始终隐藏
}

%end