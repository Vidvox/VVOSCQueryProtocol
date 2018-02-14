#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "OQHOSCManager.h"
#import "VVKQueueCenter.h"




@interface OSCQueryHelperAppDelegate : NSObject <NSApplicationDelegate,VVOSCQueryServerDelegate,VVKQueueCenterDelegate>	{
	IBOutlet OQHOSCManager	*oscm;	//	osc manager- creates an OSC input, messages sent to that input are dispatched to the address space
	
	NSMutableArray			*delegates;	//	array of QueryServerNodeDelegate instances.  each of these is a delegate of an OSCNode (the node gets a message and passes it to its delegate)
	
	NSString				*loadedFilePath;	//	the path of the currently loaded file.
	NSDictionary			*fileHostInfoDict;	//	the HOST_INFO dict from the top-level object (if there is one) is stripped and retained here
	IBOutlet NSTextField 	*fileStatusField;	//	this displays the name of the currently-loaded file in the UI
	
	VVOSCQueryServer		*server;	//	the actual OSC query server
	IBOutlet NSTextField	*serverStatusField;		//	status field in the UI that displays a clickable URL to the server
	
	IBOutlet NSWindow		*helpWindow;
}

@end

