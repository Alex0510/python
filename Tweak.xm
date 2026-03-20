#import <UIKit/UIKit.h>

%hook BDNewNavigationTitleViewTagView

// Hook 实例初始化方法（代码创建）
- (id)init {
    self = %orig; // 调用原始 init
    if (self) {
        self.hidden = YES; // 直接设置隐藏
    }
    return self;
}

// Hook 从归档初始化（如 storyboard/xib）
- (id)initWithCoder:(NSCoder *)coder {
    self = %orig; // 调用原始 initWithCoder:
    if (self) {
        self.hidden = YES;
    }
    return self;
}

// 可选：确保在布局时也隐藏（防止被其他逻辑覆盖）
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}

// 或者使用 didMoveToSuperview（当视图被添加到父视图时）
/*
- (void)didMoveToSuperview {
    %orig;
    self.hidden = YES;
}
*/

%end