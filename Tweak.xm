#import <UIKit/UIKit.h>

// 前向声明，确保类名可被识别
@class BDLiveServiceCollectionCell;
@class BDMineServiceCollectionCell;
@class BDHealthServiceCollectionCell;
@class BDOtherServiceCollectionCell;
@class BDAudioServiceCollectionViewCell;

%hook BDLiveServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    [(UIView *)self setFrame:CGRectZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

%hook BDMineServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    [(UIView *)self setFrame:CGRectZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

%hook BDHealthServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    [(UIView *)self setFrame:CGRectZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

%hook BDOtherServiceCollectionCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    [(UIView *)self setFrame:CGRectZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end

%hook BDAudioServiceCollectionViewCell

- (id)init {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    if (self) {
        [self setHidden:YES];
        [(UIView *)self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame = CGRectZero;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    [(UIView *)self setFrame:CGRectZero];
    if ([self respondsToSelector:@selector(contentView)]) {
        UIView *contentView = [self performSelector:@selector(contentView)];
        contentView.frame = CGRectZero;
        [contentView setHidden:YES];
    }
    [self setHidden:YES];
}

%end