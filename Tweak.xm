#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

// 声明需要使用的类（运行时获取）
CHDeclareClass(KGGuessFavorPlayViewController);
CHDeclareClass(KGDownloadCenter);
CHDeclareClass(SongInfo);

// 存储悬浮按钮和面板的关联对象键
static const void *kFloatingButtonKey = &kFloatingButtonKey;
static const void *kPanelViewKey = &kFloatingButtonKey;

// 获取当前播放 URL 的辅助函数
static NSURL *currentDownloadURL(CHClass clazz, id self) {
    // 获取当前歌曲信息
    SEL songInfoSel = NSSelectorFromString(@"currentSongInfo");
    if (![self respondsToSelector:songInfoSel]) return nil;
    id songInfo = ((id (*)(id, SEL))objc_msgSend)(self, songInfoSel);
    if (!songInfo) return nil;
    
    // 尝试获取 fileHash 或 mixId
    NSString *fileHash = nil;
    if ([songInfo respondsToSelector:NSSelectorFromString(@"fileHash")]) {
        fileHash = [songInfo valueForKey:@"fileHash"];
    } else if ([songInfo respondsToSelector:NSSelectorFromString(@"hash")]) {
        fileHash = [songInfo valueForKey:@"hash"];
    }
    if (!fileHash) return nil;
    
    // 获取 KGDownloadCenter 单例
    Class downloadCenterClass = NSClassFromString(@"KGDownloadCenter");
    if (!downloadCenterClass) return nil;
    
    // 调用 mapHashToProxyUrl:holder:error: 方法
    SEL mapSel = NSSelectorFromString(@"mapHashToProxyUrl:holder:error:");
    if (![downloadCenterClass instancesRespondToSelector:mapSel]) return nil;
    
    id downloadCenter = [downloadCenterClass sharedInstance]; // 假设有 sharedInstance 方法，若无则 alloc/init
    if (!downloadCenter) {
        downloadCenter = [[downloadCenterClass alloc] init];
    }
    
    NSError *error = nil;
    NSURL *url = ((id (*)(id, SEL, id, id, NSError **))objc_msgSend)(downloadCenter, mapSel, fileHash, nil, &error);
    return error ? nil : url;
}

// 关闭面板
static void dismissPanel(UIView *panelBg) {
    [panelBg removeFromSuperview];
}

// 显示面板
static void showPanel(UIView *parentView, NSURL *url) {
    // 半透明背景
    UIView *panelBg = [[UIView alloc] initWithFrame:parentView.bounds];
    panelBg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    panelBg.tag = 9999;
    [parentView addSubview:panelBg];
    
    // 面板容器
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 12;
    panel.clipsToBounds = YES;
    [panelBg addSubview:panel];
    
    // URL 标签
    UILabel *urlLabel = [[UILabel alloc] init];
    urlLabel.text = url.absoluteString;
    urlLabel.font = [UIFont systemFontOfSize:12];
    urlLabel.numberOfLines = 0;
    urlLabel.lineBreakMode = NSLineBreakByCharWrapping;
    [panel addSubview:urlLabel];
    
    // 跳转按钮
    UIButton *jumpBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [jumpBtn setTitle:@"跳转到 m3u8 下载器" forState:UIControlStateNormal];
    jumpBtn.backgroundColor = [UIColor systemBlueColor];
    jumpBtn.layer.cornerRadius = 8;
    [jumpBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [jumpBtn addTarget:panelBg action:@selector(jumpToM3U8App) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:jumpBtn];
    
    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor lightGrayColor];
    closeBtn.layer.cornerRadius = 8;
    [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeBtn addTarget:panelBg action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:closeBtn];
    
    // 布局 (Auto Layout)
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    urlLabel.translatesAutoresizingMaskIntoConstraints = NO;
    jumpBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    [panelBg addConstraints:@[
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:panelBg attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:panelBg attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:panel attribute:NSLayoutAttributeWidth constant:300],
    ]];
    
    [panel addConstraints:@[
        [NSLayoutConstraint constraintWithItem:urlLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTop multiplier:1 constant:20],
        [NSLayoutConstraint constraintWithItem:urlLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:15],
        [NSLayoutConstraint constraintWithItem:urlLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15],
        
        [NSLayoutConstraint constraintWithItem:jumpBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:urlLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:15],
        [NSLayoutConstraint constraintWithItem:jumpBtn attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:15],
        [NSLayoutConstraint constraintWithItem:jumpBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15],
        [NSLayoutConstraint constraintWithItem:jumpBtn attribute:NSLayoutAttributeHeight constant:40],
        
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:jumpBtn attribute:NSLayoutAttributeBottom multiplier:1 constant:10],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeLeading multiplier:1 constant:15],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeHeight constant:40],
        [NSLayoutConstraint constraintWithItem:closeBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:panel attribute:NSLayoutAttributeBottom multiplier:1 constant:-15]
    ]];
    
    // 为 panelBg 添加方法以便按钮调用
    objc_setAssociatedObject(panelBg, "url", url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 动态添加 closePanel 和 jumpToM3U8App 方法到 panelBg
    class_addMethod([panelBg class], @selector(closePanel), imp_implementationWithBlock(^(id self) {
        [self removeFromSuperview];
    }), "v@:");
    
    class_addMethod([panelBg class], @selector(jumpToM3U8App), imp_implementationWithBlock(^(id self) {
        NSURL *storedUrl = objc_getAssociatedObject(self, "url");
        // 尝试打开 m3u8 应用
        NSURL *appScheme = [NSURL URLWithString:@"m3u8app://"];
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:appScheme]) {
            [app openURL:appScheme options:@{} completionHandler:nil];
        } else {
            // 跳转到 App Store 下载页 (替换为真实应用 ID)
            NSURL *appStoreURL = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id123456789"];
            [app openURL:appStoreURL options:@{} completionHandler:nil];
        }
        [self removeFromSuperview];
    }), "v@:");
}

// Hook viewDidLoad 添加悬浮按钮
CHMethod2(void, KGGuessFavorPlayViewController, viewDidLoad) {
    CHSuper2(KGGuessFavorPlayViewController, viewDidLoad);
    
    // 添加悬浮按钮
    UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    floatBtn.frame = CGRectMake(0, 0, 50, 50);
    floatBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.9];
    floatBtn.layer.cornerRadius = 25;
    [floatBtn setTitle:@"⏬" forState:UIControlStateNormal];
    [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // 按钮点击事件
    [floatBtn addTarget:self action:@selector(floatButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // 布局
    floatBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:floatBtn];
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-20],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-100],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeWidth constant:50],
        [NSLayoutConstraint constraintWithItem:floatBtn attribute:NSLayoutAttributeHeight constant:50]
    ]];
    
    // 存储按钮引用以便移除
    objc_setAssociatedObject(self, kFloatingButtonKey, floatBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 添加按钮点击方法
CHMethod0(void, KGGuessFavorPlayViewController, floatButtonTapped) {
    NSURL *url = currentDownloadURL([self class], self);
    if (!url) {
        // URL 获取失败，显示提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"无法获取下载链接" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 移除已存在的面板
    UIView *existingPanel = [self.view viewWithTag:9999];
    [existingPanel removeFromSuperview];
    
    // 显示新面板
    showPanel(self.view, url);
}

// 可选：当页面消失时移除按钮和面板
CHMethod1(void, KGGuessFavorPlayViewController, viewDidDisappear, BOOL, animated) {
    CHSuper1(KGGuessFavorPlayViewController, viewDidDisappear, animated);
    
    UIButton *floatBtn = objc_getAssociatedObject(self, kFloatingButtonKey);
    [floatBtn removeFromSuperview];
    objc_setAssociatedObject(self, kFloatingButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIView *panel = [self.view viewWithTag:9999];
    [panel removeFromSuperview];
}

// 构造函数
CHConstructor {
    @autoreleasepool {
        // 注册需要 hook 的类
        CHLoadLateClass(KGGuessFavorPlayViewController);
        CHHook2(KGGuessFavorPlayViewController, viewDidLoad);
        CHHook1(KGGuessFavorPlayViewController, viewDidDisappear);
        CHHook0(KGGuessFavorPlayViewController, floatButtonTapped); // 动态添加的方法，但 CaptainHook 需要预先声明？这里用 CHHook0 注册已存在的方法，但 floatButtonTapped 是我们添加的，可能需要在类加载后添加。这里暂时使用 runtime 添加方法。
    }
}

// 由于 floatButtonTapped 是动态添加的，我们需要在类加载后通过 runtime 添加该方法
// 可以在 CHConstructor 中通过 class_addMethod 添加，但 CaptainHook 的 CHMethod0 会自动生成实现并添加？CaptainHook 的 CHMethod0 实际上会创建一个 IMP，但不会自动添加到类中。我们需要手动添加。

// 修正方案：在 hook 了 viewDidLoad 之后，使用 class_addMethod 将 floatButtonTapped 的实现添加到类中。
// 我们可以在 CHConstructor 中先注册类，然后添加方法。
// 但 CaptainHook 的 CHMethod0 宏已经定义了一个 C 函数，我们需要获取该函数指针。

// 为了简化，我们可以直接使用 block 添加，但为了保持 CaptainHook 风格，我们仍用 CHMethod0 定义，然后手动添加。

// 修改：在 CHConstructor 中，找到类后，添加方法。
CHConstructor {
    @autoreleasepool {
        Class targetClass = objc_getClass("KGGuessFavorPlayViewController");
        if (targetClass) {
            // Hook viewDidLoad
            CHHook2(targetClass, viewDidLoad);
            CHHook1(targetClass, viewDidDisappear);
            
            // 添加 floatButtonTapped 方法
            IMP imp = imp_implementationWithBlock(^(id self) {
                NSURL *url = currentDownloadURL([self class], self);
                if (!url) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"无法获取下载链接" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }
                UIView *existingPanel = [self.view viewWithTag:9999];
                [existingPanel removeFromSuperview];
                showPanel(((UIViewController *)self).view, url);
            });
            class_addMethod(targetClass, @selector(floatButtonTapped), imp, "v@:");
        }
    }
}