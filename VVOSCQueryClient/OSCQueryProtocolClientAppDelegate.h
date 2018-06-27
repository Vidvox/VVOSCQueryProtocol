#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import <VVOSC/VVOSC.h>

@interface OSCQueryProtocolClientAppDelegate : NSObject <NSApplicationDelegate,VVOSCQueryRemoteServerDelegate,OSCDelegateProtocol>	{
	IBOutlet NSTextView		*textView;
	
	NSTimer			*coalescingTimer;
	
	OSCManager			*oscm;
	OSCInPort			*oscIn;
}

- (IBAction) listenClicked:(id)sender;
- (IBAction) ignoreClicked:(id)sender;
- (IBAction) testClicked:(id)sender;

@end

