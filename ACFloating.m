#import <UIKit/UIKit.h>
#import "ACManager.h"

@interface ACFloating : UIWindow
@property (nonatomic, strong) UIButton *btn;
@end

@implementation ACFloating

- (instancetype)init {

    self = [super initWithFrame:CGRectMake(100, 200, 70, 70)];

    if (self) {

        // ✅ 关键1：必须有 rootVC
        UIViewController *vc = [UIViewController new];
        self.rootViewController = vc;

        // ✅ 关键2：windowLevel 提高
        self.windowLevel = UIWindowLevelAlert + 100;

        // UI
        self.backgroundColor = [UIColor clearColor];

        self.btn = [UIButton buttonWithType:UIButtonTypeSystem];
        self.btn.frame = CGRectMake(0, 0, 70, 70);
        self.btn.layer.cornerRadius = 35;
        self.btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

        [self.btn setTitle:@"Clean" forState:UIControlStateNormal];
        [self.btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

        [self.btn addTarget:self action:@selector(run) forControlEvents:UIControlEventTouchUpInside];

        [vc.view addSubview:self.btn];

        // ✅ 关键3：必须显示
        [self makeKeyAndVisible];
    }

    return self;
}

- (void)run {

    NSLog(@"[AllClean] 按钮点击");

    dispatch_async(dispatch_get_main_queue(), ^{
        [[ACManager shared] runFullClean];
    });
}

@end