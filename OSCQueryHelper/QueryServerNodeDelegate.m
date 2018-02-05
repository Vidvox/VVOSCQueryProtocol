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
	NSLog(@"%s ... %@, %@",__func__,n,msg);
	/*
	id			localQueryServer = [self queryServer];
	if (localQueryServer == nil)
		return;
	OSCPacket		*oscPacket = [OSCPacket createWithContent:msg];
	[localQueryServer
		listenerNeedsToSendOSCData:[oscPacket payload]
		sized:[oscPacket bufferLength]
		fromOSCAddress:[self address]];
	*/
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

