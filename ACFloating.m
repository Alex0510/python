#import <UIKit/UIKit.h>
#import "ACManager.h"

@interface ACFloating : UIWindow
@end

@implementation ACFloating

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(100, 200, 70, 70)];

    self.windowLevel = UIWindowLevelAlert + 10;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.layer.cornerRadius = 35;
    self.hidden = NO;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = self.bounds;

    [btn setTitle:@"Clean" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    [btn addTarget:self action:@selector(run) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:btn];

    return self;
}

- (void)run {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ACManager shared] runFullClean];
    });
}

@end
