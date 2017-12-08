#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import <VVOSC/VVOSC.h>




@interface OSCQueryProtocolServerAppDelegate : NSObject <NSApplicationDelegate,OSCDelegateProtocol,VVOSCQueryServerDelegate>	{
	OSCManager			*oscm;
	OSCInPort			*oscIn;
	VVOSCQueryServer		*server;
	
	NSMutableArray		*rxOSCMsgs;	//	a buffer of received OSCMessage instances are stored here, and rendered to human-readable text in the UI
	
	IBOutlet NSTextField		*statusField;
	
	IBOutlet NSTextField		*portField;
	
	IBOutlet NSTextView			*rxOSCMessageView;
}

- (IBAction) sendPathChangedClicked:(id)sender;

- (IBAction) portFieldUsed:(id)sender;

- (IBAction) stopClicked:(id)sender;
- (IBAction) startClicked:(id)sender;

@end

