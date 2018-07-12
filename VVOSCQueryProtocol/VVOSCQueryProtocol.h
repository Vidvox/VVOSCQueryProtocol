#import <Cocoa/Cocoa.h>

/*!
\mainpage VVOSCQueryProtocol Framework

\section INTRO_SECTION Orientation

There's a proposal out there for querying the structure of remote OSC address spaces, and establishing bidirectional communication with it for the purpose of monitoring changes to its structure and streaming values:

https://github.com/Vidvox/OSCQueryProposal

This framework aims to provide classes that implement the OSCQuery specification in software that already has an existing OSC implementation.  It does so in a simple, generic, OSC-library-agnostic fashion, so adding support for OSCQuery is a matter of "adding a minimal amount of code" instead of "change all of my existing OSC code to try out this weird new thing".

This framework does *NOT* send or receive or parse OSC data, nor does it provide classes to let you create an OSC address space- this is all functionality that has already been implemented in a variety of other OSC libraries.  Instead, this framework tries to give you the tools you need to add support for the OSCQuery spec to whatever OSC implementation you're already working with.

This framework has a relatively small interface- here are the only classes you should have to deal with:

- VVOSCQueryServer runs the HTTP server that describes your OSC address space to other things on the network.  Instances of VVOSCQueryServer obtain information about your address space via their delegate and its implementation of the VVOSCQueryServerDelegate protocol.

- VVOSCQueryRemoteServer represents an OSCQuery server running at a remote location.  NSNotifications are posted when instances of VVOSCQueryRemoteServer appear or disappear on your local network, and all detected instances are available via the class method +[VVOSCQueryRemoteServer remoteServers].  Instances of this class can also be created manually if you know the network address of the remote server and it's not on your local network.

- VVOSCQuery is a simple data structure that describes a single query received by your server.
- VVOSCQueryReply is a simple data structure that describes a single reply to an VVOSCQuery.

- The OSCQuery specification makes use of structured JSON objects to exchange data- there are a number of \ref OSCQUERYCONSTANTS which define the strings used to create these objects.


*/

#import <VVOSCQueryProtocol/VVOSCQueryServer.h>
#import <VVOSCQueryProtocol/VVOSCQuery.h>
#import <VVOSCQueryProtocol/VVOSCQueryReply.h>
#import <VVOSCQueryProtocol/VVOSCQueryRemoteServer.h>

