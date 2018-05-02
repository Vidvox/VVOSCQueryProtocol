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
- (void) server:(VVOSCQueryServer *)s websocketDeliveredJSONObject:(NSDictionary *)jsonObj;
- (void) server:(VVOSCQueryServer *)s receivedOSCPacket:(const void*)packet sized:(size_t)packetSize;
- (BOOL) server:(VVOSCQueryServer *)s wantsToListenTo:(NSString *)address;
- (void) server:(VVOSCQueryServer *)s wantsToIgnore:(NSString *)address;
@end




/*		instances of this class own and run the HTTP and websockets server.  pretty simple: you can 
	start it, you can stop it, you can set the bonjour name.  queries received by the server are 
	passed to its delegate, which is responsible for assembling the reply.			*/
@interface VVOSCQueryServer : NSObject	{
	NSString	*name;
	NSString	*bonjourName;
	
#if __has_feature(objc_arc)
	__weak id<VVOSCQueryServerDelegate>		delegate;
#else
	id<VVOSCQueryServerDelegate>		delegate;
#endif
}

- (void) start;
- (void) startWithPort:(int)n;
- (void) stop;
- (BOOL) isRunning;

@property (readonly) int webServerPort;
@property (retain) NSString * name;
@property (retain) NSString * bonjourName;
@property (retain,setter=setHTMLDirectory:) NSString * htmlDirectory;
#if __has_feature(objc_arc)
@property (weak) id<VVOSCQueryServerDelegate> delegate;
#else
@property (assign) id<VVOSCQueryServerDelegate> delegate;
#endif

//	these methods send data to the clients using the websocket connection
- (void) sendJSONObjectToClients:(NSDictionary *)anObj;
- (void) listenerNeedsToSendOSCData:(void*)inData sized:(size_t)inDataSize fromOSCAddress:(NSString *)inAddress;
- (void) sendPathChangedToClients:(NSString *)n;
- (void) sendPathRenamedToClients:(NSString *)op to:(NSString *)np;
- (void) sendPathRemovedToClients:(NSString *)n;
- (void) sendPathAddedToClients:(NSString *)n;

@end
