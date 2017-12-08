#import "VVOSCQuery.h"
#import "VVOSCQueryConstants.h"




@implementation VVOSCQuery


+ (void) initialize	{
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
}

- (instancetype) init	{
	self = [super init];
	if (self != nil)	{
		path = nil;
		params = nil;
		recursive = NO;
	}
	return self;
}
- (instancetype) initWithPath:(NSString *)p params:(NSDictionary *)q recursive:(BOOL)r	{
	self = [super init];
	if (self != nil)	{
		path = p;
		params = q;
		recursive = r;
	}
	return self;
}
- (void) dealloc	{
	path = nil;
	params = nil;
}
- (NSString *) description	{
	NSString		*returnMe = nil;
	NSArray			*queryKeys = (params==nil) ? nil : [params allKeys];
	NSString		*queryKeysString = (queryKeys==nil) ? nil : [queryKeys componentsJoinedByString:@"-"];
	if (queryKeysString == nil)
		returnMe = [NSString stringWithFormat:@"<VVOSCQuery \"%@\">",path];
	else
		returnMe = [NSString stringWithFormat:@"<VVOSCQuery \"%@\", %@>",path,queryKeysString];
	return returnMe;
}

@synthesize path;
@synthesize params;
@synthesize recursive;


@end
