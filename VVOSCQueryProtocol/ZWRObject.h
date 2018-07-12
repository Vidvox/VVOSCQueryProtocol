#import <Foundation/Foundation.h>

//	This object exists solely to provide a way to have a zeroing weak reference to an NSObject in an NSArray/NSDictionary/etc.

@interface ZWRObject : NSObject
- (id) initWithObject:(id)n;
@property (nonatomic, weak) id object;
@end
