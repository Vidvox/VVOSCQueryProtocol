#import <Foundation/Foundation.h>

//	zeroing weak reference object

@interface ZWRObject : NSObject
- (id) initWithObject:(id)n;
@property (nonatomic, weak) id object;
@end
