#import "VVOSCQueryBrowserAppDelegate.h"

@interface VVOSCQueryBrowserAppDelegate ()
@property (strong) id activity;
@property (weak) IBOutlet NSWindow *window;
@end

@implementation VVOSCQueryBrowserAppDelegate

- (id) init	{
	self = [super init];
	if (self != nil)	{
		//	disable app nap
		self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"OSCQuery Browser"];
	}
	return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


@end
