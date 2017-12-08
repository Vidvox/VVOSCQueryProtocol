#import <Foundation/Foundation.h>
#import "VVOSCQueryRemoteServer.h"
#import "VVOSCQueryServerDetectorDomain.h"


/*		this is an internal class- you should never have to interact with it directly, and it should 
		only be used by VVOSCQueryRemoteServer.		*/


extern NSMutableArray<VVOSCQueryRemoteServer*>		*_allRemoteServers;


@interface VVOSCQueryServerDetector : NSObject <NSNetServiceBrowserDelegate,VVOSCQueryServerDetectorDomainDelegate>	{
	NSNetServiceBrowser		*domainBrowser;
	NSMutableDictionary		*domainDict;
}
@end
