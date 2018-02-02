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
	id			localQueryServer = [self queryServer];
	if (localQueryServer == nil)
		return;
	OSCPacket		*oscPacket = [OSCPacket createWithContent:msg];
	[localQueryServer
		listenerNeedsToSendOSCData:[oscPacket payload]
		sized:[oscPacket bufferLength]
		fromOSCAddress:[self address]];
}
- (void) nodeNameChanged:(id)node	{
	[self setAddress:[node fullName]];
}
- (void) nodeDeleted:(id)node	{
	//	do nothing, passing delete messages to the query server is oustide the scope of this class
}


@synthesize queryServer;
@synthesize address;


@end
