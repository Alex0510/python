#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

// 假设的头文件接口（实际项目需引入真实头文件）
@protocol VIPViewControllerProtocol
@property (assign, nonatomic) long long selectIndex;
@property (strong, nonatomic) id VIPID;
- (void)upadteVipWithID:(id)vipID;
- (void)reloadLocalData;
@end

@protocol BuyVipViewProtocol
- (void)showViewWithWindow:(id)window;
- (void)surePress;
- (void)buyWithProductID:(id)productID;
- (void)completeTransaction:(id)transaction;
- (void)restorePress;
- (void)restoreSuccess;
- (void)upadteVipWithID:(id)vipID;
- (void)hideProHud:(id)hud;
- (void)showAlertWithTitle:(id)title;
@end

%hook VIPViewController

- (void)viewDidLoad {
    %orig;
    // 强制设置VIP为有效状态
    self.selectIndex = 0; // 假设0表示已选中的VIP等级
    [self upadteVipWithID:@"com.example.vip.pro"]; // 替换为实际VIP标识
    [self reloadLocalData]; // 刷新界面数据
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 每次出现时确保VIP状态有效
    self.selectIndex = 0;
    [self upadteVipWithID:@"com.example.vip.pro"];
    [self reloadLocalData];
}

%end

%hook BuyVipView

- (void)showViewWithWindow:(id)window {
    // 直接模拟购买成功，不显示购买界面
    [self surePress];
    // 不调用原始方法，避免显示窗口
    // %orig;
}

- (void)surePress {
    // 模拟购买成功流程
    [self completeTransaction:nil];
    [self upadteVipWithID:@"com.example.vip.pro"];
    [self hideProHud:nil];
    [self showAlertWithTitle:@"VIP已激活"];
}

- (void)buyWithProductID:(id)productID {
    // 直接完成交易，不发起真实支付
    [self completeTransaction:productID];
}

- (void)completeTransaction:(id)transaction {
    // 跳过收据验证，直接更新VIP状态
    [self upadteVipWithID:@"com.example.vip.pro"];
    // 如果有服务器验证，需模拟成功响应
}

- (void)restorePress {
    // 模拟恢复购买成功
    [self restoreSuccess];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 将所有交易标记为已购买，避免弹出Apple ID验证
    for (SKPaymentTransaction *transaction in transactions) {
        if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
            // 模拟完成交易
            [self completeTransaction:transaction];
            [queue finishTransaction:transaction];
        } else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
            // 将失败也转为成功
            [self completeTransaction:transaction];
            [queue finishTransaction:transaction];
        } else {
            // 其他状态直接完成
            [self completeTransaction:transaction];
            [queue finishTransaction:transaction];
        }
    }
}

%end