#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

%hook SKPaymentTransaction
-(long long) transactionState {
    return 1;
}
%end