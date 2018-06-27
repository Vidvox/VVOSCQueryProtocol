#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import <VVOSC/VVOSC.h>




@interface OSCQueryProtocolServerAppDelegate : NSObject <NSApplicationDelegate,OSCDelegateProtocol,VVOSCQueryServerDelegate,OSCAddressSpaceDelegateProtocol>	{
	OSCManager			*oscm;
	OSCInPort			*oscIn;
	VVOSCQueryServer	*server;
	NSMutableArray		*delegates;	//	we create delegates for OSCNodes in the address space- these delegates send vals from the address space to the query server, and are retained here.
	
	NSString			*loadedFilePath;	//	the path of the currently loaded file.
	
	NSMutableArray		*rxOSCMsgs;	//	a buffer of received OSCMessage instances are stored here, and rendered to human-readable text in the UI
	
	IBOutlet NSTextField		*statusField;
	
	IBOutlet NSTextField		*portField;
	
	IBOutlet NSTextView			*rxOSCMessageView;
}

- (IBAction) sendPathChangedClicked:(id)sender;

- (IBAction) portFieldUsed:(id)sender;

- (IBAction) stopClicked:(id)sender;
- (IBAction) startClicked:(id)sender;

- (IBAction) sliderUsed:(id)sender;
- (IBAction) renameButtonUsed:(id)sender;

- (IBAction) doSomethingClicked:(id)sender;

- (IBAction) showSampleDocInFinderClicked:(id)sender;

@end

