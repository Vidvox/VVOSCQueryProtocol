#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "RemoteNode.h"




@interface RemoteNodeTableCellView : NSTableCellView	{
	IBOutlet NSTextField		*fullPathLabel;
	IBOutlet NSTextField		*typeTagStringLabel;
	IBOutlet NSTextField		*descriptionLabel;
}

- (void) refreshWithRemoteNode:(RemoteNode *)n;

@end
