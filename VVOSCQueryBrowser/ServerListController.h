#import <Cocoa/Cocoa.h>

@class ServerUIController;

@interface ServerListController : NSObject	{
	IBOutlet NSTableView		*tableView;
	IBOutlet ServerUIController	*serverUIController;
}

- (void) reloadTableView;

- (IBAction) deleteServerClicked:(id)sender;
- (IBAction) createServerClicked:(id)sender;
- (IBAction) reloadListClicked:(id)sender;

@end
