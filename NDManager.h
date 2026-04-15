#import <Foundation/Foundation.h>

@interface ACManager : NSObject

+ (instancetype)shared;

- (void)runFullClean;
- (NSString *)currentBundle;

@end