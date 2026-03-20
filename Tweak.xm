#import <UIKit/UIKit.h>

// 前向声明，避免未知类型错误
@class BDLiveServiceCollectionCell;
@class BDMineServiceCollectionCell;
@class BDHealthServiceCollectionCell;
@class BDOtherServiceCollectionCell;
@class BDAudioServiceCollectionViewCell;

// 宏定义，统一处理隐藏与尺寸归零
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
    /* 强制自身 frame 为零 */ \
    [(UIView *)self setFrame:CGRectZero]; \
    /* 清空 contentView，彻底消除子视图占位 */ \
    if ([self respondsToSelector:@selector(contentView)]) { \
        UIView *contentView = [self performSelector:@selector(contentView)]; \
        contentView.frame = CGRectZero; \
        [contentView setHidden:YES]; \
    } \
    [self setHidden:YES]; \
} \
%end

// 应用到目标 Cell 类
HIDE_CELL(BDLiveServiceCollectionCell)
HIDE_CELL(BDMineServiceCollectionCell)
HIDE_CELL(BDHealthServiceCollectionCell)
HIDE_CELL(BDOtherServiceCollectionCell)
HIDE_CELL(BDAudioServiceCollectionViewCell)