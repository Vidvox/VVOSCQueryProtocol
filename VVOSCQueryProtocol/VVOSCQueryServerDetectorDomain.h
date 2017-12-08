#import <Foundation/Foundation.h>


@protocol VVOSCQueryServerDetectorDomainDelegate
@required
- (void) serviceRemoved:(NSNetService *)s;
- (void) serviceResolved:(NSNetService *)s;
@end


/*		internal class used only by the VVOSCQueryProtocol framework, you should never need to work with this outside of that framework.		*/


@interface VVOSCQueryServerDetectorDomain : NSObject <NSNetServiceBrowserDelegate,NSNetServiceDelegate>	{
	NSString				*domainString;
	NSNetServiceBrowser		*serviceBrowser;
	NSMutableArray			*services;
	
	__weak id<VVOSCQueryServerDetectorDomainDelegate>				detector;
}

- (instancetype) initWithDomain:(NSString *)dom detector:(id<VVOSCQueryServerDetectorDomainDelegate>)det;

@end
