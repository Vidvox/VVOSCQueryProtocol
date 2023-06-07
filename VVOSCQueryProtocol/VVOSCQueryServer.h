#import <Foundation/Foundation.h>
#import <VVOSCQueryProtocol/VVOSCQuery.h>
#import <VVOSCQueryProtocol/VVOSCQueryReply.h>
@class VVOSCQueryServer;


/**
Delegates of VVOSCQueryServer must respond to this protocol. This is how the query server interfaces with your OSC address space- it passes queries to the server's delegate, which assembles a reply that the server will return.
*/
@protocol VVOSCQueryServerDelegate
@required
/**
This delegate callback is performed whenever a client requests the server's HOST_INFO object.
@param s The server whose HOST_INFO information was queried.
@return The returned instance should be a init'ed with a JSON object containing the HOST_INFO data you want the server to return.  For more information, please consult the OSCQuery documentation.
*/
- (VVOSCQueryReply *) hostInfoQueryFromServer:(VVOSCQueryServer *)s;
/**
This delegate callback is performed whenever a client queries the server for information about the structure of its address space.  You should consult the documentation for VVOSCQuery for more information about the specific information being requested.
@param s The server that is being queried.
@param q The query that is being performed on the server- this consists of a path, zero or more parameters which offer cues about what kind of query is being performed on the path, and a flag indicating whether or not the query should be considered recursive.  For more information, please consult the documentation for VVOSCQuery.
@return The return instance of VVOSCQueryReply will probably be either an error of some sort (if the query was inappropriate, incomplete, invalid, etc) or a JSON object containing the information to be returned for the query.  As a convenience, VVOSCQueryReply has a class method for producing fully-formed JSON objects that comply with the OSCQuery specification- these JSON objects can then be used to create a VVOSCQueryReply instance.
*/
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s wantsReplyForQuery:(VVOSCQuery *)q;
/**
This delegate callback is performed when the server receives a JSON object from one of the clients it maintains a websocket connection with that doesn't fit anything recognized from the spec.  At this time, there is no known use for this callback, as it should theoretically never be executed- but if you want to use the existing websocket connection to pass data between clients and servers, this is the callback that you will want to use.
@param s The server that received the JSON object.
@param jsonObj The JSON object that was passed to the server.
*/
- (void) server:(VVOSCQueryServer *)s websocketDeliveredJSONObject:(NSDictionary *)jsonObj;
/**
The OSCQuery protocol includes provisions for sending raw (binary) OSC packets over the persistent websocket connection maintained between clients and server.  This delegate callback is performed whenever the server receives an OSC packet over its websocket connection.  The packet data should not be assumed to exist after this method returns, and should be copied or parsed immediately.
@param s The server that received the packet
@param packet A pointer to a block of memory containing the OSC packet data
@param packetSize The size of packet in bytes
*/
- (void) server:(VVOSCQueryServer *)s receivedOSCPacket:(const void*)packet sized:(size_t)packetSize;
/**
This delegate callback is performed when a client has informed your server that it wishes to "LISTEN" to a particular OSC address path.  After receiving this message, it becomes the delegate's responsibility to pass any OSC messages sent to that address back to the server, which will take care of sending the message to the appropriate clients.  This is accomplished via -[VVOSCQueryServer sendOSCPacketData:sized:toClientsListeningToOSCAddress:].  Delegates will only receive this callback once per OSC address, even if multiple clients requested to listen to it.
@param s The server that received the LISTEN request
@param address The address that the client requested to LISTEN to- the delegate is now responsible for passing all OSC messages sent to that address within your software to the server.
*/
- (BOOL) server:(VVOSCQueryServer *)s wantsToListenTo:(NSString *)address;
/**
This delegate callback is performed when all of the clients currently connected to the server have informed the server that they no longer wish to listen to a given address using the IGNORE attribute.  This delegate callback is only performed once, when all of the clients listening to the given address have either disconnected or explicitly sent IGNORE messages.
@param s The server that received the IGNORE request
@param address The address that the server no longer needs to listen to.
*/
- (void) server:(VVOSCQueryServer *)s wantsToIgnore:(NSString *)address;
@end




/**
Instances of this class own and run the HTTP and websocket server.  Queries received by the server are passed to its delegate, which is responsible for assembling the reply.
*/
@interface VVOSCQueryServer : NSObject	{
	NSString	*name;
	NSString	*bonjourName;
	
#if __has_feature(objc_arc)
	__weak id<VVOSCQueryServerDelegate>		delegate;
#else
	id<VVOSCQueryServerDelegate>		delegate;
#endif
}




/*!
\name Basic server operations
*/

///@{

/**	Start the query server, the port it uses will be chosen arbitrarily. */
- (void) start;
/**	Start the query server using the passed port.  If the port cannot be used because another process has bound it, the server will increment the port until an available port is found, at which point the server will be started.	*/
- (void) startWithPort:(int)n;
/**	Stops the server.	*/
- (void) stop;
/**	Returns a BOOL indicating whether or not the receiver is currently running.	*/
- (BOOL) isRunning;

///@}




/*!
\name Properties
*/

///@{

/**	The port that the server is using.	*/
@property (readonly) int webServerPort;
/**	The name of the OSCQuery server.  This value will be returned with the NAME attribute in the HOST_INFO dict the receiver will return when clients query it.	*/
@property (retain) NSString * name;
/**	The name the OSCQuery server will use when using bonjour/zeroconf to broadcast its presence on the local network.	*/
@property (retain) NSString * bonjourName;
/**	The OSCQuery spec is basically an HTTP and websocket server that provides structured data describing an OSC address space.  The HTML attribute of the OSCQuery spec provides the server with a way serve files- HTML files, image files, etc.  If the htmlDirectory attribute is non-nil, it will be treated as the root directory of your web server.	*/
@property (retain,setter=setHTMLDirectory:) NSString * htmlDirectory;
/**	VVOSCQueryServer's delegate is the interface between the OSCQuery server and the software which is controlling it.  The delegate's callbacks is how the query server obtains information about the OSC address space it needs to describe.	*/
#if __has_feature(objc_arc)
@property (weak) id<VVOSCQueryServerDelegate> delegate;
#else
@property (assign) id<VVOSCQueryServerDelegate> delegate;
#endif

///@}




/*!
\name Client/websocket methods
\brief These methods send data to all connected clients over the websocket connection.
*/
///@{

/**	Sends the passed JSON object to all clients maintaining a persistent websocket connection.  This method can be used to send non-conforming messages to clients- I'm leaving it in the public API because it provides devs with a simple way to establish custom communicate between clients and servers.	*/
- (void) sendJSONObjectToClients:(NSDictionary *)anObj;
/**	This method is used to send OSC packet data to all available clients.  If your server delegate received a server:wantsToListenTo: callback then one of its clients wishes to be informed of all OSC traffic sent to the passed OSC address in your application's address space.  This method is the appropriate way to send that OSC message data to the clients.  It is expected that the binary payload will be an OSC message, the format of which is described in the OSC specification (http://opensoundcontrol.org/spec-1_0).
@param inData The raw (binary) OSC packet, which is expected to contain an OSC message.
@param inDataSize The size of inData, in bytes
@param inAddress The OSC address that the OSC message in packet is being sent to */
- (void) sendOSCPacketData:(void*)inData sized:(size_t)inDataSize toClientsListeningToOSCAddress:(NSString *)inAddress;
/**	This method is used to inform clients that a property of some path in your app's OSC address space has changed in some way- it sends a PATH_CHANGED notification.  When clients receive this message they generally query the passed path to reload its contents.		*/
- (void) sendPathChangedToClients:(NSString *)n;
/**	This method is used to inform clients that a node in your app's OSC address space has been renamed, or moved to another spot in the address space- it sends a PATH_RENAMED notification.  You should call it every time any node in your OSC address space is renamed or moved.	*/
- (void) sendPathRenamedToClients:(NSString *)op to:(NSString *)np;
/**	This method is used to inform clients that a node in your app's OSC address space has been removed, and is no longer available- it sends a PATH_REMOVED notification.	*/
- (void) sendPathRemovedToClients:(NSString *)n;
/**	This method is used to inform clients that a node in your app's OSC address space has been created, and is now available for query- it sends a PATH_ADDED notification.  You should call it every time any node in your OSC address space is created.  If you have to create a lot of nodes and they're all in the same parent directory, it may be more efficient to simply call sendPathChangedToClients: to inform all connected clients that the address space has changed and they need to reload it.	*/
- (void) sendPathAddedToClients:(NSString *)n;

///@}




@end
