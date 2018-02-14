#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "LOQHOSCManager.h"
#import "LOQHMIDIManager.h"
#import "VVKQueueCenter.h"

@interface LiveOSCQueryHelperAppDelegate : NSObject <NSApplicationDelegate,VVOSCQueryServerDelegate,VVKQueueCenterDelegate>	{
	IBOutlet LOQHOSCManager		*oscm;
	IBOutlet LOQHMIDIManager	*midim;
	
	NSMutableArray			*delegates;	//	array of QueryServerNodeDelegate instances
	
	NSString				*loadedFilePath;
	NSDictionary			*fileHostInfoDict;	//	the HOST_INFO dict from the top-level object (if there is one) is stripped and retained here
	IBOutlet NSTextField 	*fileStatusField;
	
	VVOSCQueryServer		*server;
	IBOutlet NSTextField	*serverStatusField;
	
	IBOutlet NSWindow		*helpWindow;
}


@end

