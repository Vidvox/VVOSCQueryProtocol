#import "VVOSCQueryServerDetectorDomain.h"
#import "VVOSCQueryConstants.h"




@implementation VVOSCQueryServerDetectorDomain


+ (void) initialize	{
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
}
- (instancetype) initWithDomain:(NSString *)dom detector:(id)det	{
	self = [super init];
	if (self != nil)	{
		domainString = dom;
		serviceBrowser = nil;
		services = [[NSMutableArray alloc] init];
		detector = det;
		
		serviceBrowser = [[NSNetServiceBrowser alloc] init];
		[serviceBrowser setDelegate:self];
		[serviceBrowser searchForServicesOfType:@"_oscjson._tcp." inDomain:domainString];
	}
	return self;
}
- (void) dealloc	{
	detector = nil;
	domainString = nil;
	if (serviceBrowser != nil)	{
		[serviceBrowser stop];
		serviceBrowser = nil;
	}
	[services removeAllObjects];
	services = nil;
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)n didFindService:(NSNetService *)x moreComing:(BOOL)m	{
	NSLog(@"%s",__func__);
	if (n==nil || x==nil)
		return;
	@synchronized (self)	{
		[services addObject:x];
		[x setDelegate:self];
		[x resolveWithTimeout:10];
	}
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)n didNotSearch:(NSDictionary *)err	{
	//NSLog(@"%s ... %@",__func__,err);
	NSLog(@"\t\terr, didn't search: %s, %@",__func__,err);
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)n didRemoveService:(NSNetService *)s moreComing:(BOOL)m	{
	//NSLog(@"%s",__func__);
	//	tell the domainManager the service is being removed
	if (detector != nil)	{
		[detector serviceRemoved:s];
	}
	//	remove the object from the array
	@synchronized (self)	{
		[services removeObject:n];
	}
}




- (void)netService:(NSNetService *)n didNotResolve:(NSDictionary *)err	{
	//NSLog(@"%s",__func__);
	NSLog(@"\t\terr resolving domain: %@",err);
	//	tell the net service to stop
	[n stop];
	//	remove the service from the array
	@synchronized (self)	{
		[services removeObject:n];
	}
}
- (void)netServiceDidResolveAddress:(NSNetService *)n	{
	//NSLog(@"%s",__func__);
	//	tell the net service to stop, since it's resolved the address
	[n stop];
	//	tell the detector about the resolved service
	if (detector!=nil)	{
		[detector serviceResolved:n];
	}
}


@end
