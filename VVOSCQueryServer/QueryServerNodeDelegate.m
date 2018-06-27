#import "QueryServerNodeDelegate.h"




@implementation QueryServerNodeDelegate


- (id) initWithQueryServer:(VVOSCQueryServer *)n forAddress:(NSString *)a	{
	//NSLog(@"%s ... %p, %@, %@",__func__,self,n,a);
	self = [super init];
	if (self != nil)	{
		queryServer = n;
		address = a;
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s ... %p",__func__,self);
	[self setQueryServer:nil];
	[self setAddress:nil];
}


- (void) node:(id)n receivedOSCMessage:(OSCMessage *)msg	{
	//NSLog(@"%s ... %p, %@, %@",__func__,self,n,msg);
	id			localQueryServer = [self queryServer];
	if (localQueryServer == nil)
		return;
	OSCPacket		*oscPacket = [OSCPacket createWithContent:msg];
	[localQueryServer
		sendOSCPacketData:[oscPacket payload]
		sized:[oscPacket bufferLength]
		toClientsListeningToOSCAddress:[self address]];
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
