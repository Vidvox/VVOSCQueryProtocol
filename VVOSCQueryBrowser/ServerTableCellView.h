#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>

@interface ServerTableCellView : NSTableCellView	{
	IBOutlet NSTextField		*nameField;
	//IBOutlet NSTextField		*ipField;
	//IBOutlet NSTextField		*portField;
	IBOutlet NSTextField		*addressField;
}

- (void) refreshWithServer:(VVOSCQueryRemoteServer *)s;

@end
