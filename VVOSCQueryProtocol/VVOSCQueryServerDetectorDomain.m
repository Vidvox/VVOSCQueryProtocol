#import "VVOSCQueryServerDetectorDomain.h"
#import "VVOSCQueryConstants.h"
#import "NSNetServiceAdditions.h"




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
	//	a service's delegate is a plain assign, so a resolve left running would call back into this freed object
	for (NSNetService *tmpService in services)	{
		[self _stopService:tmpService];
	}
	[services removeAllObjects];
	services = nil;
}


//	the delegate is cleared before the stop, so nothing the stop ends can call back in
- (void) _stopService:(NSNetService *)s	{
	[s setDelegate:nil];
	[s stop];
}
//	a resolve that ends without an IPv4 address is retried for as long as bonjour advertises the service, because bonjour reports a service only once- without the retry, an app whose first resolve brings no usable address is never listed at all
- (void) _resolveService:(NSNetService *)s	{
	if (s == nil)
		return;
	//	the delegate is set here, not by the caller: a retry resolves a service that -_stopService: has just cleared
	[s setDelegate:self];
	[s resolveWithTimeout:10];
	
	__weak VVOSCQueryServerDetectorDomain		*bss = self;
	//	17s, by which time the resolve above has ended either with an address or with -netService:didNotResolve:
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 17.0*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		VVOSCQueryServerDetectorDomain		*ss = bss;
		if (ss == nil)
			return;
		//	by identity, never equality: -[NSNetService isEqual:] matches any service with the same name, type and domain, so an equality test would find the instance that replaced this one and re-resolve this stale one forever
		@synchronized (ss)	{
			if ([ss->services indexOfObjectIdenticalTo:s] == NSNotFound)
				return;
		}
		//	the same test -[VVOSCQueryServerDetector serviceResolved:] applies, so the two can't disagree about what a usable address is
		NSString			*ipString = nil;
		unsigned short		port = 1234;
		[s getIPAddressString:&ipString port:&port];
		if (ipString != nil)
			return;
		//	the stop is what lets a resolve be started again, and the resolve arms the next check
		[ss _stopService:s];
		[ss _resolveService:s];
	});
}
//	stopping the service we stored is what keeps a resolve left running from completing against a same-name re-registration and listing that host twice.  -[NSNetService isEqual:] compares name, type and domain, so this matches the instance we stored even when the browser hands us a different object
- (void) _removeService:(NSNetService *)s	{
	@synchronized (self)	{
		for (NSNetService *tmpService in services)	{
			if ([tmpService isEqual:s])
				[self _stopService:tmpService];
		}
		[services removeObject:s];
	}
	//	the detector is told last, so anything it asks us about sees the removal
	if (detector != nil)	{
		[detector serviceRemoved:s];
	}
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)n didFindService:(NSNetService *)x moreComing:(BOOL)m	{
	//NSLog(@"%s",__func__);
	if (n==nil || x==nil)
		return;
	//	finding a name we are already storing means bonjour swallowed its removal: the app quit and registered again while these callbacks were being batched.  the entry we hold belongs to a process that has gone, so it is replaced rather than skipped, and the detector gets the removal it was never given
	BOOL				alreadyStored = NO;
	@synchronized (self)	{
		alreadyStored = [services containsObject:x];
	}
	//	the old entry has to go before the new instance is stored, because the removal matches by name, type and domain and would take the new instance with it
	if (alreadyStored)
		[self _removeService:x];
	
	@synchronized (self)	{
		[services addObject:x];
	}
	[self _resolveService:x];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)n didNotSearch:(NSDictionary *)err	{
	//NSLog(@"%s ... %@",__func__,err);
	NSLog(@"\t\terr, didn't search: %s, %@",__func__,err);
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)n didRemoveService:(NSNetService *)s moreComing:(BOOL)m	{
	//NSLog(@"%s",__func__);
	[self _removeService:s];
}




- (void)netService:(NSNetService *)n didNotResolve:(NSDictionary *)err	{
	//NSLog(@"%s",__func__);
	NSLog(@"\t\terr resolving domain: %@",err);
	//	the service stays in the array, stopped, until -_resolveService:'s check retries it.  dropping it here is what left an app that was slow to answer unlisted until it re-registered
	[self _stopService:n];
}
- (void)netServiceDidResolveAddress:(NSNetService *)n	{
	//NSLog(@"%s",__func__);
	//	an instalment with no IPv4 address is no use to us, so this one is left resolving for the next instalment- bonjour may deliver several, and -_resolveService:'s check retries the service if none of them is usable
	NSString			*ipString = nil;
	unsigned short		port = 1234;
	[n getIPAddressString:&ipString port:&port];
	if (ipString == nil)
		return;
	//	tell the net service to stop, since it's resolved the address
	[self _stopService:n];
	//	tell the detector about the resolved service
	if (detector!=nil)	{
		[detector serviceResolved:n];
	}
}


@end
