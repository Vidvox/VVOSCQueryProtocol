#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "OQHOSCManager.h"




@interface OSCQueryHelperAppDelegate : NSObject <NSApplicationDelegate,VVOSCQueryServerDelegate>	{
	IBOutlet OQHOSCManager	*oscm;
	
	NSMutableArray			*delegates;	//	array of QueryServerNodeDelegate instances
	
	NSString				*loadedFilePath;
	NSDictionary			*fileHostInfoDict;	//	the HOST_INFO dict from the top-level object (if there is one) is stripped and retained here
	IBOutlet NSTextField 	*fileStatusField;
	
	VVOSCQueryServer		*server;
	IBOutlet NSTextField	*serverStatusField;
	
	IBOutlet NSWindow		*helpWindow;
}

//- (OSCManager *) oscManager;

@end

