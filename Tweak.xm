#import <UIKit/UIKit.h>

// 宏定义，简化重复代码
#define HIDE_CELL(class_name) \
%hook class_name \
- (id)init { \
    self = %orig; \
    if (self) { \
        [self setHidden:YES]; \
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO]; \
    } \
    return self; \
} \
\
- (id)initWithCoder:(NSCoder *)coder { \
    self = %orig; \
    if (self) { \
        [self setHidden:YES]; \
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO]; \
    } \
    return self; \
} \
\
- (void)setFrame:(CGRect)frame { \
    frame = CGRectZero; \
    %orig; \
} \
\
- (void)layoutSubviews { \
    %orig; \
    /* 确保自身 frame 为零 */ \
    [(UIView *)self setFrame:CGRectZero]; \
    /* 清空 contentView */ \
    if ([self respondsToSelector:@selector(contentView)]) { \
        UIView *contentView = [self performSelector:@selector(contentView)]; \
        contentView.frame = CGRectZero; \
        [contentView setHidden:YES]; \
    } \
    [self setHidden:YES]; \
} \
%end

// 应用到所有需要隐藏的 Cell 类
HIDE_CELL(BDLiveServiceCollectionCell)
HIDE_CELL(BDMineServiceCollectionCell)
HIDE_CELL(BDHealthServiceCollectionCell)
HIDE_CELL(BDOtherServiceCollectionCell)
HIDE_CELL(BDAudioServiceCollectionViewCell)