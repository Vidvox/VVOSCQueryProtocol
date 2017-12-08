There's a proposal out there for querying OSC address spaces:

https://github.com/mrRay/OSCQueryProposal

This project contains a couple different implementations of this protocol:
* **VVOSCQueryProtocol.framework** is a Cocoa framework that provides classes to implement this OSC query proposal in software that already has an existing OSC implementation- it does so in a simple, generic and what i hope is a library-agnostic fashion.  By itself, this framework does *NOT* send or receive OSC data, nor does it provide classes to let you create an OSC address space- this is all functionality that has already been implemented in a variety of other OSC libraries.  Instead, this framework gives you the tools you need to add support for the OSC query protocol to whatever OSC implementation you're already working with.
* **VVOSCQueryServer** is a simple example server.  It uses VVOSCQueryProtocol.framework to create an OSC query server that provides information about an OSC address space and OSC receiver created using VVOSC.framework.
* **VVOSCQueryClient** is a simple example client that demonstrates the use of VVOSCQueryProtocol.framework to respond to new client notifications and display basic information about new servers in a text view.
* **VVOSCQueryBrowser** is a GUI that browses available OSC query servers, displays their OSC node hierarchies, creates UI items for endpoints that advertise their type, and uses VVOSC.framework to send OSC data to the remote server when the UI items are used.

The API for VVOSCQueryProtocol.framework is minimal- here are the only classes you'll need to use.  The documentation for these classes is in their headers:

* VVOSCQueryServer runs the HTTP server that describes your OSC address space to other things on the network.  Instances of VVOSCQueryServer obtain information about your address space via their delegate and its implementation of the VVOSCQueryServerDelegate protocol.
	
* VVOSCQueryRemoteServer represents an OSC query server running at a remote location.  NSNotifications are posted when instances of VVOSCQueryRemoteServer appear or disappear on your local network, and all detected instances are available via the class method +[VVOSCQueryRemoteServer remoteServers].  Instances of this class can also be created manually if you know the network address of the remote server and it's not on your local network.
	
* VVOSCQuery is a simple data structure that describes a single query received by your server.
* VVOSCQueryReply is a simple data structure that describes a single reply to an VVOSCQuery.
