#import <Foundation/Foundation.h>

%hook _TtC8CloakKit9AppState

// Hook __purchased 属性的 getter 方法，始终返回 YES
- (BOOL)__purchased {
    return YES;
}

%end

// 构造函数，确保钩子生效
%ctor {
    %init;
}