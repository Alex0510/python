#import <UIKit/UIKit.h>

// =============================== BDLiveServiceCollectionCell ===============================
%hook BDLiveServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        // 禁用自动布局转换，使 frame 修改生效
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        // 移除所有已有约束
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        // 强制几何属性归零
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        // 处理 contentView
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)setBounds:(CGRect)bounds {
    bounds = CGRectZero;
    %orig;
}

- (void)setCenter:(CGPoint)center {
    center = CGPointZero;
    %orig;
}

- (CGSize)intrinsicContentSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    [self setFrame:CGRectZero];
    [self setBounds:CGRectZero];
    [self setCenter:CGPointZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        contentView.bounds = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

// =============================== BDMineServiceCollectionCell ===============================
%hook BDMineServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)setBounds:(CGRect)bounds {
    bounds = CGRectZero;
    %orig;
}

- (void)setCenter:(CGPoint)center {
    center = CGPointZero;
    %orig;
}

- (CGSize)intrinsicContentSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    [self setFrame:CGRectZero];
    [self setBounds:CGRectZero];
    [self setCenter:CGPointZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        contentView.bounds = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

// =============================== BDHealthServiceCollectionCell ===============================
%hook BDHealthServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)setBounds:(CGRect)bounds {
    bounds = CGRectZero;
    %orig;
}

- (void)setCenter:(CGPoint)center {
    center = CGPointZero;
    %orig;
}

- (CGSize)intrinsicContentSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    [self setFrame:CGRectZero];
    [self setBounds:CGRectZero];
    [self setCenter:CGPointZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        contentView.bounds = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

// =============================== BDOtherServiceCollectionCell ===============================
%hook BDOtherServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)setBounds:(CGRect)bounds {
    bounds = CGRectZero;
    %orig;
}

- (void)setCenter:(CGPoint)center {
    center = CGPointZero;
    %orig;
}

- (CGSize)intrinsicContentSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    [self setFrame:CGRectZero];
    [self setBounds:CGRectZero];
    [self setCenter:CGPointZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        contentView.bounds = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

// =============================== BDAudioServiceCollectionViewCell ===============================
%hook BDAudioServiceCollectionViewCell

- (id)init {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
        for (NSLayoutConstraint *constraint in [(UIView *)self constraints]) {
            [(UIView *)self removeConstraint:constraint];
        }
        [self setFrame:CGRectZero];
        [self setBounds:CGRectZero];
        [self setCenter:CGPointZero];
        [self setHidden:YES];
        if ([self respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [self performSelector:@selector(contentView)];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            for (NSLayoutConstraint *c in contentView.constraints) {
                [contentView removeConstraint:c];
            }
            contentView.frame = CGRectZero;
            contentView.bounds = CGRectZero;
            [contentView setHidden:YES];
        }
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)setBounds:(CGRect)bounds {
    bounds = CGRectZero;
    %orig;
}

- (void)setCenter:(CGPoint)center {
    center = CGPointZero;
    %orig;
}

- (CGSize)intrinsicContentSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    [self setFrame:CGRectZero];
    [self setBounds:CGRectZero];
    [self setCenter:CGPointZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        contentView.bounds = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end