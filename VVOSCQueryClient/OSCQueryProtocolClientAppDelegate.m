#import "OSCQueryProtocolClientAppDelegate.h"




@interface OSCQueryProtocolClientAppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@end




@implementation OSCQueryProtocolClientAppDelegate


- (id) init	{
	self = [super init];
	if (self != nil)	{
		coalescingTimer = nil;
		//	register to receive notifications that the list of OSC query servers has updated
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(oscQueryServersUpdated:)
			name:kVVOSCQueryRemoteServersUpdatedNotification
			object:nil];
		//	initialize the remote server class, which will start looking for remote servers automatically...
		[VVOSCQueryRemoteServer class];
	}
	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
}


- (void) oscQueryServersUpdated:(NSNotification *)note	{
	NSLog(@"%s",__func__);
	//	multiple notifications may be fired if many servers are coming online at once, so use a timer to coalesce those updates
	@synchronized (self)	{
		if (coalescingTimer != nil)
			[coalescingTimer invalidate];
		coalescingTimer = [NSTimer
			scheduledTimerWithTimeInterval:0.25
			target:self
			selector:@selector(coalescingTimerCallback:)
			userInfo:nil
			repeats:NO];
	}
}
- (void) coalescingTimerCallback:(NSTimer *)t	{
	@synchronized (self)	{
		coalescingTimer = nil;
	}
	
	NSMutableString		*displayString = [[NSMutableString alloc] init];
	NSArray				*servers = [VVOSCQueryRemoteServer remoteServers];
	[displayString appendFormat:@"%d servers detected:\n",(servers==nil) ? 0 : [servers count]];
	[displayString appendFormat:@"**************\n"];
	for (VVOSCQueryRemoteServer *server in servers)	{
		[displayString appendFormat:@"name: \"%@\"\n",[server oscName]];
		[displayString appendFormat:@"\tbonjour: \"%@\"\n",[server bonjourName]];
		[displayString appendFormat:@"\taddress: %@:%d\n",[server webServerAddressString],[server webServerPort]];
	}
	
	[textView setString:displayString];
	
	/*
	NSArray		*servers = [VVOSCQueryRemoteServer remoteServers];
	if (servers==nil || [servers count]<1)	{
		NSLog(@"\t\tno remote servers detected, bailing...");
		return;
	}
	VVOSCQueryRemoteServer	*server = [servers objectAtIndex:0];
	NSLog(@"\t\tfirst remote server is %@",server);
	NSLog(@"\t\tfirst remote server's HOST_INFO is %@",[server hostInfo]);
	//NSLog(@"\t\tfirst remote server's root node is %@",[server rootNode]);
	*/
}


@end
