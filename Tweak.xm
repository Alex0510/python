#import <UIKit/UIKit.h>

%hook BDLiveServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];   // 初始隐藏（可选）
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];   // 初始隐藏（可选）
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    // 强制设置宽度和高度为 0
    CGRect frame = self.frame;
    frame.size.width = 0;
    frame.size.height = 0;
    self.frame = frame;

    // 可选：继续隐藏（若同时需要隐藏，可保留）
    [self setHidden:YES];
}

%end