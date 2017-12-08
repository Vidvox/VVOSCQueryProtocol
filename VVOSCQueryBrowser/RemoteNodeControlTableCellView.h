#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "RemoteNodeControl.h"
#import "OSCValueView.h"




@interface RemoteNodeControlTableCellView : NSTableCellView	{
	IBOutlet OSCValueView			*valueView;
	IBOutlet OSCValueView			*minView;
	IBOutlet OSCValueView			*maxView;
}

- (void) refreshWithRemoteNodeControl:(RemoteNodeControl *)n outlineView:(NSOutlineView *)ov;

@end
