#import <Foundation/Foundation.h>
#import "VVOSCQuery.h"
#import "VVOSCQueryReply.h"
@class VVOSCQueryServer;


/*		delegates of VVOSCQueryServer must respond to this protocol.  this is how the query server 
		interfaces with your OSC address space- it passes queries to the server's delegate, which 
		assembles a reply that the server will return.			*/
@protocol VVOSCQueryServerDelegate
@required
- (VVOSCQueryReply *) hostInfoQueryFromServer:(VVOSCQueryServer *)s;
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s wantsReplyForQuery:(VVOSCQuery *)q;
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s websocketDeliveredJSONObject:(NSDictionary *)jsonObj;
@end




/*		instances of this class own and run the HTTP and websockets server.  pretty simple: you can 
	start it, you can stop it, you can set the bonjour name.  queries received by the server are 
	passed to its delegate, which is responsible for assembling the reply.			*/
@interface VVOSCQueryServer : NSObject	{
	NSString	*name;
	NSString	*bonjourName;
	
	__weak id<VVOSCQueryServerDelegate>		delegate;
}

- (void) start;
- (void) startWithPort:(int)n;
- (void) stop;
- (BOOL) isRunning;

@property (readonly) int webServerPort;
@property (retain) NSString * name;
@property (retain) NSString * bonjourName;
@property (weak) id<VVOSCQueryServerDelegate> delegate;

- (void) sendJSONObjectToClients:(NSDictionary *)anObj;

@end
