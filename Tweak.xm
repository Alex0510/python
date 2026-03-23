// EgernProUnlock.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

%hook Store

// 修改Store类中的_isProUnlocked属性，始终返回YES
- (BOOL)_isProUnlocked {
    return YES;
}

// 如果存在isProUnlocked方法
- (BOOL)isProUnlocked {
    return YES;
}

// 如果存在proUnlocked方法
- (BOOL)proUnlocked {
    return YES;
}

%end

%hook LicenseValidator

// 修改许可证验证结果，始终返回有效
- (BOOL)validateLicense {
    return YES;
}

- (id)verifyType {
    return @"pro";
}

- (BOOL)isPro {
    return YES;
}

%end

%hook GetProViewController

// 修改GetProViewController，使其看起来已经购买
- (void)viewDidLoad {
    %orig;
    // 添加标签显示已解锁
    UILabel *unlockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 50)];
    unlockedLabel.text = @"Pro Features Unlocked";
    unlockedLabel.textAlignment = NSTextAlignmentCenter;
    unlockedLabel.textColor = [UIColor greenColor];
    unlockedLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:unlockedLabel];
    
    // 隐藏购买按钮
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UIButton")]) {
            UIButton *button = (UIButton *)subview;
            if ([button.titleLabel.text containsString:@"Unlock"] || 
                [button.titleLabel.text containsString:@"Purchase"]) {
                button.hidden = YES;
            }
        }
    }
}

%end

// 针对AppStorage结构体中的_isProUnlocked属性
%hook AppStorage

// Hook NSUserDefaults相关方法，确保返回正确的值
- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return @YES;
        }
    }
    return %orig;
}

- (BOOL)boolForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return YES;
        }
    }
    return %orig;
}

%end

%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return YES;
        }
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    if ([key containsString:@"pro"] || [key containsString:@"Pro"] || 
        [key containsString:@"unlock"] || [key containsString:@"Unlock"]) {
        if ([key isEqualToString:@"isProUnlocked"] || 
            [key isEqualToString:@"proUnlocked"] ||
            [key isEqualToString:@"ProUnlocked"]) {
            return @YES;
        }
    }
    return %orig;
}

%end

// 如果存在SettingsViewController，修改Pro相关设置
%hook SettingsViewController

- (void)viewDidLoad {
    %orig;
    // 禁用任何Pro限制的检查
    // 确保所有Pro功能选项可见
    // 可以通过遍历视图来启用被禁用的Pro功能
    [self performSelector:@selector(enableProFeatures) withObject:nil afterDelay:0.5];
}

- (void)enableProFeatures {
    // 启用所有可能被禁用的Pro功能
    // 遍历所有tableview cells，启用Pro功能
    UITableView *tableView = [self valueForKey:@"tableView"];
    if (tableView) {
        [tableView reloadData];
    }
}

%end

// 修改Preferences类，确保Pro功能可用
%hook Preferences

- (BOOL)isPro {
    return YES;
}

- (BOOL)hasProFeature {
    return YES;
}

%end

// 初始化函数
%ctor {
    NSLog(@"Egern Pro Unlock dylib loaded successfully!");
    
    // 使用dispatch_async确保在主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        // 发送通知，告知应用Pro已解锁
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProUnlockedNotification" object:nil];
        
        // 尝试获取Store实例并设置pro状态
        Class storeClass = NSClassFromString(@"_TtC5Egern5Store");
        if (storeClass) {
            id storeInstance = [storeClass performSelector:@selector(shared)];
            if (storeInstance) {
                [storeInstance setValue:@YES forKey:@"_isProUnlocked"];
                [storeInstance setValue:@YES forKey:@"isProUnlocked"];
            }
        }
        
        // 尝试获取AppStorage实例
        Class appStorageClass = NSClassFromString(@"_TtC5Egern13KeyValueStore");
        if (appStorageClass) {
            id storageInstance = [appStorageClass performSelector:@selector(shared)];
            if (storageInstance) {
                [storageInstance setValue:@YES forKey:@"isProUnlocked"];
                [storageInstance setValue:@YES forKey:@"proUnlocked"];
            }
        }
    });
}