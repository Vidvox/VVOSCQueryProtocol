#import <Foundation/Foundation.h>
#import "VVOSCQueryRemoteServer.h"
#import "VVOSCQueryServerDetectorDomain.h"


/*		this is an internal class- you should never have to interact with it directly, and it should 
		only be used by VVOSCQueryRemoteServer.		*/


extern NSMutableArray<VVOSCQueryRemoteServer*>		*_allRemoteServers;


@interface VVOSCQueryServerDetector : NSObject <NSNetServiceBrowserDelegate,VVOSCQueryServerDetectorDomainDelegate>	{
	NSNetServiceBrowser		*domainBrowser;
	NSMutableDictionary		*domainDict;
	NSMutableDictionary		*removalCounts;	//	main thread only.  key is a bonjour name, value is the number of times a service with that name has been removed
}
@end
