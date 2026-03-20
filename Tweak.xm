#import <UIKit/UIKit.h>

%hook BDLiveServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
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
    // 强制转换为 UIView 以访问 frame 属性
    CGRect frame = [(UIView *)self frame];
    frame.size.width = 0;
    frame.size.height = 0;
    [(UIView *)self setFrame:frame];

    // 可选：保持隐藏
    [self setHidden:YES];
}

%end