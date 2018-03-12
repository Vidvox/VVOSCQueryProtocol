#import <Foundation/Foundation.h>
#import "VVOSCQueryConstants.h"

@class VVOSCQueryRemoteServer;




/*		a remote server's delegate is required to conform to this protocol.  this is how the remote 
	query server communicates with your software- it receives data from the server it's connected 
	to, and passes that data to its delegate.				*/
@protocol VVOSCQueryRemoteServerDelegate
@required
- (void) remoteServerWentOffline:(VVOSCQueryRemoteServer *)remoteServer;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer websocketDeliveredJSONObject:(NSDictionary *)jsonObj;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer receivedOSCPacket:(const void *)packet sized:(size_t)packetSize;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathChanged:(NSString *)n;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathRenamedFrom:(NSString *)oldName to:(NSString *)newName;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathRemoved:(NSString *)n;
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathAdded:(NSString *)n;
@end




/*		this is one of the "main classes" in the VVOSCQueryProtocol framework- an instance of this 
		class represents an OSC query server running somewhere else.
		
	- instances of this class are created automatically in response to services detected via bonjour.
	- you can also create an instance of this class manually, if you know the IP and port of the remote 
	OSC query server (for example, if the remote server is outside your network and bonjour won't work)
	- if the remote OSC query server supports the OSC_IP, OSC_PORT, OSC_TRANSPORT, and NAME keys 
	then instances of this class will have their 'oscServerAddressString', 'oscServerPort', 
	'oscServerTransport', and 'oscName' variables set appropriately.
	- you should probably avoid retaining instances of this class that were created and managed by 
	the framework- use a weak ref if you want to store a ptr to an instance of this class.  if you 
	do retain an instance, make sure you release it in response to the appropriate 
	'remoteServerWentOffline:' method.
	- the VVOSCQueryRemoteServerDelegate protocol can be used to inform delegates of a remote 
	server's disappearance.  you can also respond to the appearance/disappearance of remote s
	ervers using notifications:
		- kVVOSCQueryRemoteServersNewServerNotification is posted after a new server is detected (the notification object is the server)
		- kVVOSCQueryRemoteServersRemovedServerNotification is posted after a server is removed (the notification object is the server)
		- kVVOSCQueryRemoteServersUpdatedNotification is posted after a server has been added or removed			*/
@interface VVOSCQueryRemoteServer : NSObject	{
	NSString		*webServerAddressString;
	int				webServerPort;
	NSString		*bonjourName;
	
	NSString				*oscServerAddressString;
	int						oscServerPort;
	VVOSCQueryOSCTransportType	oscServerTransport;
	NSString				*oscName;
	
	NSString		*wsServerAddressString;
	int				wsServerPort;
	
	NSMutableArray		*delegateRefs;	//	array of ZWRObject instances, each instance is a zeroing weak ref to a delegate
}

//	you should try to avoid retaining any of these remote servers- use a weak ref if you want to store a ptr to one of them.
#if __has_feature(objc_arc)
+ (NSArray<VVOSCQueryRemoteServer*> *) remoteServers;
#else
+ (NSArray *) remoteServers;
#endif

//	returns an array of all the IP addresses this machine has
+ (NSArray *) hostIPv4Addresses;

- (instancetype) initWithWebServerAddressString:(NSString *)inWebServerAddressString
	port:(int)inWebServerPort
	bonjourName:(NSString *)inBonjourName;

//	basic properties describing the remote OSC query server and the OSC server corresponding to it
@property (readonly) NSString * webServerAddressString;
@property (readonly) int webServerPort;
@property (readonly) NSString * bonjourName;
@property (readonly) NSString * oscServerAddressString;
@property (readonly) int oscServerPort;
@property (readonly) VVOSCQueryOSCTransportType oscServerTransport;
@property (readonly) NSString * oscName;
@property (readonly) NSString *wsServerAddressString;
@property (readonly) int wsServerPort;

//	delegates are informed of a variety of server events, including path add/remove/change callbacks, OSC packets delivered over the websocket connection, other miscellaneous websocket data, and offline callbacks
- (void) addDelegate:(id<VVOSCQueryRemoteServerDelegate>)n;
- (void) removeDelegate:(id<VVOSCQueryRemoteServerDelegate>)n;
- (NSArray *) delegateRefs;

//	synchronous- queries the remote server for its host info
- (NSDictionary *) hostInfo;
//	synchronous- queries the remote server for its root node, which will fullly describe every node in its address space
- (NSDictionary *) rootNode;
//	synchronous- queries the remote server for a JSON object describing the node at the passed path
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath;
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString;
- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath;
- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString;

//	these methods send data over the websocket connection to the server
- (void) websocketSendJSONObject:(id)n;
- (void) startListeningTo:(NSString *)n;
- (void) stopListeningTo:(NSString *)n;

//	returns a YES if the receiving instance matches the passed IP address and port.  used for comparing remote server instances to one another, or to determine if a remote server instance found via bonjour was created by this farmework or not
- (BOOL) matchesWebIPAddress:(NSString*)inIPAddressString port:(unsigned short)inPort;


@end
