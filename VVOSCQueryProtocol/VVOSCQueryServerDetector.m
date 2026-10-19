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
static dispatch_queue_t					_serverTeardownQueue = nil;




@implementation VVOSCQueryServerDetector


+ (void) initialize	{
	//NSLog(@"%s",__func__);
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
	if (_allRemoteServers == nil)	{
		_allRemoteServers = [[NSMutableArray alloc] init];
	}
	if (_serverTeardownQueue == nil)	{
		_serverTeardownQueue = dispatch_queue_create("com.vidvox.oscquery.serverteardown", DISPATCH_QUEUE_SERIAL);
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
		removalCounts = [[NSMutableDictionary alloc] init];
		discoveryQueues = [[NSMutableDictionary alloc] init];
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
	removalCounts = nil;
	discoveryQueues = nil;
}


- (void) serviceRemoved:(NSNetService *)s	{
	//NSLog(@"%s ... %@",__func__,s);
	NSString			*serviceName = [s name];
	//	count this removal against the bonjour name- a discovery that is in flight for this name compares the count before it adds anything, so a service that vanishes mid-discovery can't be added late.  per name rather than one global count, which would discard in-flight discoveries of unrelated hosts that nothing would re-resolve.  never pruned: its size is bounded by the number of distinct bonjour names we see.
	if (serviceName != nil)	{
		int				removalCount = [[removalCounts objectForKey:serviceName] intValue];
		[removalCounts setObject:[NSNumber numberWithInt:removalCount+1] forKey:serviceName];
	}
	
	//	get the IP address and port for the passed service
	NSString			*ipString = nil;
	unsigned short		port = 1234;
	[s getIPAddressString:&ipString port:&port];
	//NSLog(@"\t\tservice %@ that was removed was at %@:%d",serviceName,ipString,port);
	
	
	__block NSArray		*serversToRemove = nil;
	//	this pool has to drain before the hand-off below: objectsAtIndexes: and the notifications leave autoreleased references to the servers, and whichever reference is released last is the one that runs their dealloc
	@autoreleasepool	{
		NSMutableIndexSet	*indexesToRemove = nil;
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
			//	post a notification for each server we're removing
			for (VVOSCQueryRemoteServer *tmpRemoteServer in serversToRemove)	{
				[[NSNotificationCenter defaultCenter]
					postNotificationName:kVVOSCQueryRemoteServersRemovedServerNotification
					object:tmpRemoteServer
					userInfo:nil];
			}
			//	post a notification that the list of servers has been updated
			[[NSNotificationCenter defaultCenter]
				postNotificationName:kVVOSCQueryRemoteServersUpdatedNotification
				object:nil
				userInfo:nil];
		}
	}
	
	//	we hold the last reference to the servers now- this block does nothing but release them off the main thread, because their dealloc stops each websocket client's io loop and joins its thread
	if (serversToRemove != nil)	{
		dispatch_async(_serverTeardownQueue, ^{
			serversToRemove = nil;
		});
	}
}
- (void) serviceResolved:(NSNetService *)s	{
	//NSLog(@"%s ... %@",__func__,s);
	//NSLog(@"\t\tdomain is %@",[s domain]);
	//NSLog(@"\t\tname is %@",[s name]);
	//NSLog(@"\t\ttype is %@",[s type]);
	//NSLog(@"\t\tTXTRecordData is %@",[NSNetService dictionaryFromTXTRecordData:[s TXTRecordData]]);
	
	//	get the IP address and port for the passed service.  these have to be read here, on the thread the service belongs to: -getIPAddressString:port: hands back inet_ntoa's static buffer
	NSString			*ipString = nil;
	unsigned short		port = 1234;
	[s getIPAddressString:&ipString port:&port];
	if (ipString == nil)
		return;
	NSString			*serviceName = [s name];
	if (serviceName == nil)
		return;
	//	note how many removals this name has seen, so the block below can tell whether what it resolved is still what bonjour is advertising
	int					removalCount = [[removalCounts objectForKey:serviceName] intValue];
	
	//	making the remote server performs a blocking HOST_INFO request, so it happens on a background queue.  the queue is per bonjour name, so discoveries of one app run one after another and at most one thread is ever parked for it, while a stalled app never holds up the discovery of another.  the accepted cost is that a request that never returns blocks every later discovery of that name for the life of the process, so that app can't be rediscovered until we're relaunched.  the label carries the name so a parked discovery identifies its app in a spindump
	//	like removalCounts, this dictionary is never pruned: its size is bounded by the number of distinct bonjour names we see
	dispatch_queue_t	discoveryQueue = [discoveryQueues objectForKey:serviceName];
	if (discoveryQueue == nil)	{
		discoveryQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.vidvox.oscquery.discovery.%@",serviceName] UTF8String], DISPATCH_QUEUE_SERIAL);
		[discoveryQueues setObject:discoveryQueue forKey:serviceName];
	}
	dispatch_async(discoveryQueue, ^{
		//	make a remote server for the service
		__block VVOSCQueryRemoteServer		*newRemoteServer = [[VVOSCQueryRemoteServer alloc]
			initWithWebServerAddressString:ipString
			port:port
			bonjourName:serviceName];
		if (newRemoteServer == nil)
			return;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			//	if a service with this name was removed while we were working, -serviceRemoved: has already run and found nothing to remove- adding this server now would leave it in the list for good
			if ([[self->removalCounts objectForKey:serviceName] intValue] != removalCount)	{
				//	this server's dealloc stops its websocket client's io loop and joins its thread, so we don't release it here
				dispatch_async(_serverTeardownQueue, ^{
					newRemoteServer = nil;
				});
				return;
			}
			
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
		});
	});
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)n didFindDomain:(NSString *)d moreComing:(BOOL)m	{
	//NSLog(@"%s ... %@, %d",__func__,d,m);
	//	a repeated report of a domain we already browse must not replace its object: the old object's dealloc stops its browser, so every removal that browser would have reported is lost, while the new browser reports every service in the domain all over again
	@synchronized (self)	{
		if ([domainDict objectForKey:d] != nil)
			return;
	}
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
