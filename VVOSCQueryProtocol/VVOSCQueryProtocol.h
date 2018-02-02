#import <Cocoa/Cocoa.h>

/*		there's a proposal out there for querying OSC address spaces:

https://github.com/mrRay/OSCQueryProposal

this framework aims to provide classes to make it easier to implement this OSC query proposal in 
software that already has an existing OSC implementation- it does so in a simple, generic and what i 
hope is a library-agnostic fashion.

this framework does *NOT* send or receive OSC data, nor does it provide classes to let you create an 
OSC address space- this is all functionality that has already been implemented in a variety of other 
OSC libraries.  instead, this framework tries to give you the tools you need to add support for the 
OSC query protocol to whatever OSC implementation you're already working with.

here's the nickel tour:

	- VVOSCQueryServer runs the HTTP server that describes your OSC address space to other things on 
	the network.  instances of VVOSCQueryServer obtain information about your address space via 
	their delegate and its implementation of the VVOSCQueryServerDelegate protocol.
	
	- VVOSCQueryRemoteServer represents an OSC query server running at a remote location.  
	NSNotifications are posted when instances of VVOSCQueryRemoteServer appear or disappear on your 
	local network, and all detected instances are available via the class method 
	+[VVOSCQueryRemoteServer remoteServers].  instances of this class can also be created manually 
	if you know the network address of the remote server and it's not on your local network.
	
	- VVOSCQuery is a simple data structure that describes a single query received by your server.
	- VVOSCQueryReply is a simple data structure that describes a single reply to an VVOSCQuery.


*/

#import <VVOSCQueryProtocol/VVOSCQueryServer.h>
#import <VVOSCQueryProtocol/VVOSCQuery.h>
#import <VVOSCQueryProtocol/VVOSCQueryReply.h>
#import <VVOSCQueryProtocol/VVOSCQueryRemoteServer.h>

