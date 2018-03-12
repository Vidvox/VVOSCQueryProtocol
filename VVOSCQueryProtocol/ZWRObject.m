#import "ZWRObject.h"

@implementation ZWRObject
- (id) initWithObject:(id)n	{
	self = [super init];
	self.object = n;
	return self;
}
@synthesize object;
@end
