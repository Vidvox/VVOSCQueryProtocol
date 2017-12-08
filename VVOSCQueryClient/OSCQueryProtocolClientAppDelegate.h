#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>

@interface OSCQueryProtocolClientAppDelegate : NSObject <NSApplicationDelegate>	{
	IBOutlet NSTextView		*textView;
	
	NSTimer			*coalescingTimer;
}

@end

