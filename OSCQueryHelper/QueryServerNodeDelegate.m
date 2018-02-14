#import "QueryServerNodeDelegate.h"




@implementation QueryServerNodeDelegate


- (id) initWithQueryServer:(VVOSCQueryServer *)n forAddress:(NSString *)a	{
	//NSLog(@"%s ... %@, %@",__func__,n,a);
	self = [super init];
	if (self != nil)	{
		queryServer = n;
		address = a;
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
	[self setQueryServer:nil];
	[self setAddress:nil];
}


- (void) node:(id)n receivedOSCMessage:(OSCMessage *)msg	{
	//NSLog(@"%s ... %@, %@",__func__,n,msg);
	//	intentionally blank- the messages we receive from OSCNodes are coming exclusively from clients, so there's no point in telling the osc query server to stream the values.  the fact that we don't have access to the OSC address space of the app we're "helping" means that this application should not be capable of streaming values at all.
}
- (void) nodeNameChanged:(id)node	{
	NSString		*newName = [node fullName];
	NSString		*oldName = [self address];
	NSLog(@"%s ... %@ -> %@",__func__,oldName,newName);
	[self setAddress:newName];
	
	if (queryServer != nil)	{
		if (newName!=nil && oldName!=nil)
			[queryServer sendPathRenamedToClients:oldName to:newName];
	}
}
- (void) nodeDeleted:(id)node	{
	NSString		*oldName = [self address];
	NSLog(@"%s ... %@",__func__,oldName);
	if (queryServer != nil)	{
		[queryServer sendPathRemovedToClients:oldName];
	}
}


@synthesize queryServer;
@synthesize address;


@end

