#import <Foundation/Foundation.h>
#import "VVOSCQueryConstants.h"
#import "ZWRObject.h"

@class VVOSCQueryRemoteServer;




/**
Delegates of VVOSCQueryRemoteServer are required to conform to this delegate protocol, which is how the remote query server passes data it receives back to your software.
*/
@protocol VVOSCQueryRemoteServerDelegate
@required
/** This delegate callback is performed when the remote server the receiver is a delegate of closes its websocket connection.  If the remote server doesn't support websockets or the connection attempt fails for any reason, this method gets called. */
- (void) remoteServerWentOffline:(VVOSCQueryRemoteServer *)remoteServer;
/** This delegate callback is performed every time the remote server receives an undefined JSON object from the server over its persistent websocket connection.  In an ideal world you'll never see this callback- it exists primarily to allow devs a simple path for sending and receiving JSON messages between clients and servers that do not conform to the OSCQuery specification. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer websocketDeliveredJSONObject:(NSDictionary *)jsonObj;
/** This delegate callback is performed every time the remote server the receiver is a delegate of receives an OSC message from its server.  This method should get called rapidly if your software has called the startListeningTo: method on the receiver. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer receivedOSCPacket:(const void *)packet sized:(size_t)packetSize;
/** This delegate callback is performed every time the remote server sends a PATH_CHANGED notification to its clients. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathChanged:(NSString *)n;
/** This delegate callback is performed every time the remote server sends a PATH_RENAMED notification to its clients. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathRenamedFrom:(NSString *)oldName to:(NSString *)newName;
/** This delegate callback is performed every time the remote server sends a PATH_REMOVED notification to its clients. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathRemoved:(NSString *)n;
/** This delegate callback is performed every time the remote server sends a PATH_ADDED notification to its clients. */
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer pathAdded:(NSString *)n;
@end




//!	An instance of this class represents an OSCQuery server running in another process or machine.
/*!
- Instances of this class are created automatically in response to services detected via bonjour.  If you want to keep a pointer to an instance of this class that was automatically created, please use a weak ref.
- You can also create an instance of this class manually, if you know the IP and port of the remote OSCQuery server (for example, if the remote server is outside your network and bonjour can't be used).  If you create an instance in this manner, you need to retain it yourself.
- The VVOSCQueryRemoteServerDelegate protocol can be used to inform delegates of a remote server's disappearance.  you can also respond to the appearance/disappearance of remote servers using notifications:
	- kVVOSCQueryRemoteServersNewServerNotification is posted after a new server is detected (the notification object is the server)
	- kVVOSCQueryRemoteServersRemovedServerNotification is posted after a server is removed (the notification object is the server)
	- kVVOSCQueryRemoteServersUpdatedNotification is posted after a server has been added or removed
*/
@interface VVOSCQueryRemoteServer : NSObject	{
	NSString		*webServerAddressString;
	int				webServerPort;
	NSString		*bonjourName;
	
	NSString		*oscServerAddressString;
	int				oscServerPort;
	VVOSCQueryOSCTransportType		oscServerTransport;
	NSString		*oscName;
	
	NSString		*wsServerAddressString;
	int				wsServerPort;
	
	NSMutableArray	*delegateRefs;	//	array of ZWRObject instances, each instance is a zeroing weak ref to a delegate
}

/**	Returns an array containing all of the remote OSCQuery servers that were detected on the local network.  If you obtain a reference to a VVOSCQueryRemoteServer instance from this array, do not retain it- use a weak ref if you need to store a ptr to it.	*/
#if __has_feature(objc_arc)
+ (NSArray<VVOSCQueryRemoteServer*> *) remoteServers;
#else
+ (NSArray *) remoteServers;
#endif

/**	Returns an array of all the IP addresses this machine has (there will be multiple IP addresses if multiple NICs are in use)	*/
+ (NSArray *) hostIPv4Addresses;

/**
Returns an instance of this class configured with the passed data.  This method is used internally to create the privately-retained instances of VVOSCQueryRemoteServer that are automatically detected, and it can also be used to manually create instances of VVOSCQueryRemoteServer that correspond to servers that are outside the local network and thus could not be detected.
@param inWebServerAddressString The IP address of the remote OSCQuery server, expressed as a string
@param inWebServerPort The port of the remote OSCQuery server
@param inBonjourName The bonjour name of the remote server- you can supply an arbitrary name here if you're manually creating an instance of VVOSCQueryRemoteServer.
*/
- (instancetype) initWithWebServerAddressString:(NSString *)inWebServerAddressString
	port:(int)inWebServerPort
	bonjourName:(NSString *)inBonjourName;




/*!
\name Server properties
\brief Basic properties describing the remote OSCQuery server and the OSC server corresponding to it
*/
///@{

/// The IP address of the remote OSCQuery server (which is fundamentally a web server), expressed as a string.
@property (readonly) NSString * webServerAddressString;
/// The port used by the remote OSCQuery server.
@property (readonly) int webServerPort;
/// The name used by bonjour/zeroconf to refer to the remote OSCQuery server.
@property (readonly) NSString * bonjourName;
/// The IP address of the OSC server that is described by the receiver's OSCQuery server.  Most of the time this will have the same value as webServerAddressString, but the HOST_INFO object in the OSCQuery specification provides a way to run an OSCQuery server on one IP address/port that describes an OSC server on a different address/port.
@property (readonly) NSString * oscServerAddressString;
/// The port of the OSC server that is described by the receiver's OSCQuery server.  Most of the time this will have the same value as webServerPort, but the HOST_INFO object in the OSCQuery specification provides a way to run an OSCQuery server on one IP address/port that describes an OSC server on a different IP address/port.
@property (readonly) int oscServerPort;
/// The type of transport the remote server expects to use when receiving OSC messages.  Most of the time this will be UDP.
@property (readonly) VVOSCQueryOSCTransportType oscServerTransport;
/// The name of the OSCQuery server, as provided in the HOST_INFO object.
@property (readonly) NSString * oscName;
/// The IP address of the websocket server that is described by the receiver's OSCQuery server.  Most of the time this will have the same value as webServerAddressString, but the HOST_INFO object in the OSCQuery specification provides a way to run an OSCQuery server on one IP address/port that uses a websocket server on another IP address/port.
@property (readonly) NSString *wsServerAddressString;
/// The port of the websocket server that is described by the receiver's OSCQuery server.  Most of the time this will have the same value as webServerPort, but the HOST_INFO object in the OSCQuery specification provides a way to run an OSCQuery server on one IP address/port that uses a websocket server on a different IP address/port.
@property (readonly) int wsServerPort;

///@}



/*!
\name Delegate methods
\brief Delegates are informed of a variety of server events, including path add/remove/change callbacks, OSC packets delivered over the websocket connection, other miscellaneous websocket data, and offline callbacks
*/
///@{

/// Adds the passed delegate to the receiver's array of delegates.  The delegate will not be retained- a zeroing weak reference to it is used.
- (void) addDelegate:(id<VVOSCQueryRemoteServerDelegate>)n;
/// Removes the passed delegate from the receiver's array of delegates.
- (void) removeDelegate:(id<VVOSCQueryRemoteServerDelegate>)n;
/// Returns an array containing all of the receiver's delegate refs.  This is not an array of your delegates- this is an array of ZWRObject instances, each of which refers to a single delegate.
- (NSArray *) delegateRefs;

///@}




/*!
\name Basic queries
\brief All OSCQuery servers should respond to these methods- they encompass the minimum, required aspects of the OSCQuery specification.
*/
///@{

/// Synchronous- queries the remote server for its HOST_INFO
- (NSDictionary *) hostInfo;
/// Synchronous- queries the remote server for its root node, which will fully describe every node in its address space.
- (NSDictionary *) rootNode;
/// Synchronous- queries the remote server for a JSON object describing the node at the passed path
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath;
/**
Synchronous- queries the remote server for a JSON object describing the node at the passed path
@param inPath The path of the node to query
@param inQueryString The query to append to the path, as a string.  When the query is performed on the remote server, it is appended to the path in the traditional manner when performing HTTP GET queries (http://inPath?inQueryString).
@return The JSON object returned by the remote server in response to a query formed by the passed values.
*/
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString;

- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath;
- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString;

///@}




/*!
\name Websocket-related methods
\brief These methods send data over the websocket connection to the server.  Not all OSCQuery servers may respond to these- bidirectional communication and websocket-based notifications are optional.
*/
///@{

/** Sends the passed JSON object to the remote server.  This method can be used to send non-conforming messages to clients- I'm leaving it in the public API because it provides devs with a simple way to establish custom communicate between clients and servers. */
- (void) websocketSendJSONObject:(id)n;
/** Inform the remote server that you want to start receiving all the OSC messages sent to the OSC node corresponding to the passed address.  Must be paired with a matching call to -[VVOSCQueryRemoteServer stopListeningTo:].  If the remote server supports websockets, it should start sending raw OSC packets to the receiver's delegate. */
- (void) startListeningTo:(NSString *)n;
/** Inform the remote server that you no longer wish to receive any OSC messages sent to the OSC node corresponding to the passed address. */
- (void) stopListeningTo:(NSString *)n;

///@}




///	Returns a YES if the receiving instance matches the passed IP address and port.  Used for comparing remote server instances to one another, or to determine if a remote server instance found via bonjour was created by this framework or not.
- (BOOL) matchesWebIPAddress:(NSString*)inIPAddressString port:(unsigned short)inPort;


@end
