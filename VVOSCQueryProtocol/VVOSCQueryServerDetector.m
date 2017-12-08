#import "VVOSCQueryServerDetector.h"
#import "NSNetServiceAdditions.h"
#import "CURLDL.h"




@interface VVOSCQueryRemoteServer ()
@property (retain,setter=setOSCServerAddressString:) NSString * oscServerAddressString;
@property (assign,setter=setOSCServerPort:) int oscServerPort;
@property (assign,setter=setOSCServerTransport:) VVOSCQueryOSCTransportType oscServerTransport;
@property (retain,setter=setOSCName:) NSString * oscName;
@end




NSMutableArray<VVOSCQueryRemoteServer*>	*_allRemoteServers = nil;
static VVOSCQueryServerDetector			*_global = nil;




@implementation VVOSCQueryServerDetector


+ (void) initialize	{
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
	if (_allRemoteServers == nil)	{
		_allRemoteServers = [[NSMutableArray alloc] init];
	}
	if (_global == nil)	{
		_global = [[VVOSCQueryServerDetector alloc] init];
	}
}


- (instancetype) init	{
	//NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		domainBrowser = [[NSNetServiceBrowser alloc] init];
		[domainBrowser setDelegate:self];
		[domainBrowser searchForRegistrationDomains];
		domainDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
	if (domainBrowser != nil)	{
		[domainBrowser stop];
		domainBrowser = nil;
	}
	domainDict = nil;
}


- (void) serviceRemoved:(NSNetService *)s	{
	//NSLog(@"%s ... %@",__func__,s);
	NSString			*serviceName = [s name];
	//	get the IP address and port for the passed service
	NSString			*ipString = nil;
	unsigned short		port = 1234;
	[s getIPAddressString:&ipString port:&port];
	//NSLog(@"\t\tservice %@ that was removed was at %@:%d",serviceName,ipString,port);
	
	
	NSMutableIndexSet	*indexesToRemove = nil;
	NSArray				*serversToRemove = nil;
	int					tmpIndex = 0;
	@synchronized ([VVOSCQueryRemoteServer class])	{
		if (serviceName != nil)	{
			for (VVOSCQueryRemoteServer *remoteServer in _allRemoteServers)	{
				//	we're checking for matches using bonjour name.  the NSNetService we were passed does not have an IP address or port, so the bonjour name is really the best we can do here.
				NSString		*tmpString = [remoteServer bonjourName];
				if (tmpString!=nil && [tmpString isEqualToString:serviceName])	{
					if (indexesToRemove == nil)
						indexesToRemove = [[NSMutableIndexSet alloc] init];
					[indexesToRemove addIndex:tmpIndex];
				}
				++tmpIndex;
			}
		}
		//NSLog(@"\t\tindexesToRemove are %@",indexesToRemove);
		if (indexesToRemove != nil)	{
			serversToRemove = [_allRemoteServers objectsAtIndexes:indexesToRemove];
			[_allRemoteServers removeObjectsAtIndexes:indexesToRemove];
		}
	}
	
	//	if there are servers to remove...
	if (serversToRemove != nil)	{
		//	post a notification for each server we're removing then delete all of them
		for (VVOSCQueryRemoteServer *tmpRemoteServer in serversToRemove)	{
			[[NSNotificationCenter defaultCenter]
				postNotificationName:kVVOSCQueryRemoteServersRemovedServerNotification
				object:tmpRemoteServer
				userInfo:nil];
		}
		serversToRemove = nil;
		//	post a notification that the list of servers has been updated
		[[NSNotificationCenter defaultCenter]
			postNotificationName:kVVOSCQueryRemoteServersUpdatedNotification
			object:nil
			userInfo:nil];
	}
}
- (void) serviceResolved:(NSNetService *)s	{
	//NSLog(@"%s ... %p",__func__,s);
	//NSLog(@"\t\tdomain is %@",[s domain]);
	//NSLog(@"\t\tname is %@",[s name]);
	//NSLog(@"\t\ttype is %@",[s type]);
	//NSLog(@"\t\tTXTRecordData is %@",[NSNetService dictionaryFromTXTRecordData:[s TXTRecordData]]);
	
	//	get the IP address and port for the passed service
	NSString			*ipString = nil;
	unsigned short		port = 1234;
	[s getIPAddressString:&ipString port:&port];
	if (ipString == nil)
		return;
	
	//	make a remote server for the service
	VVOSCQueryRemoteServer		*newRemoteServer = [[VVOSCQueryRemoteServer alloc]
		initWithWebServerAddressString:ipString
		port:port
		bonjourName:[s name]];
	if (newRemoteServer == nil)
		return;
	
	//	add the remote server to the list of remote servers
	@synchronized ([VVOSCQueryRemoteServer class])	{
		[_allRemoteServers addObject:newRemoteServer];
	}
	
	//	post a notification that we made a new server
	NSNotificationCenter		*nc = [NSNotificationCenter defaultCenter];
	[nc
		postNotificationName:kVVOSCQueryRemoteServersNewServerNotification
		object:newRemoteServer
		userInfo:nil];
	//	post a notification that the list of servers was updated
	[nc
		postNotificationName:kVVOSCQueryRemoteServersUpdatedNotification
		object:nil
		userInfo:nil];
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)n didFindDomain:(NSString *)d moreComing:(BOOL)m	{
	//NSLog(@"%s ... %@, %d",__func__,d,m);
	VVOSCQueryServerDetectorDomain	*newDomain = [[VVOSCQueryServerDetectorDomain alloc]
		initWithDomain:d
		detector:self];
	if (newDomain != nil)	{
		@synchronized (self)	{
			[domainDict setObject:newDomain forKey:d];
		}
	}
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)n didNotSearch:(NSDictionary *)err	{
	//NSLog(@"%s ... %@",__func__,err);
	NSLog(@"\t\terr, %s: %@",__func__,err);
}


@end
