#import "ServerListController.h"
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "ServerTableCellView.h"
#import "ServerUIController.h"




@implementation ServerListController


- (void) awakeFromNib	{
	[[NSNotificationCenter defaultCenter]	
		addObserver:self
		selector:@selector(serverReloadNotification:)
		name:kVVOSCQueryRemoteServersUpdatedNotification
		object:nil];
	[self reloadTableView];
}


- (void) serverReloadNotification:(NSNotification *)note	{
	[self reloadTableView];
}


- (NSInteger) numberOfRowsInTableView:(NSTableView *)tv	{
	NSArray			*tmpServers = [VVOSCQueryRemoteServer remoteServers];
	return (tmpServers==nil) ? 0 : [tmpServers count];
}
- (NSView *) tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row	{
	NSArray			*tmpServers = [VVOSCQueryRemoteServer remoteServers];
	if (tmpServers==nil || row>=[tmpServers count])
		return nil;
	VVOSCQueryRemoteServer	*tmpServer = [tmpServers objectAtIndex:row];
	NSView		*returnMe = [tv makeViewWithIdentifier:@"MainCell" owner:self];
	[(ServerTableCellView*)returnMe refreshWithServer:tmpServer];
	return returnMe;
}
- (void) tableViewSelectionDidChange:(NSNotification *)note	{
	NSInteger		row = [tableView selectedRow];
	NSArray			*tmpServers = [VVOSCQueryRemoteServer remoteServers];
	VVOSCQueryRemoteServer		*tmpServer = (tmpServers==nil || row<0 || row>=[tmpServers count]) ? nil : [tmpServers objectAtIndex:row];
	//dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[serverUIController newServerChosen:tmpServer];
	//});
}


- (void) reloadTableView	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self reloadTableView];
		});
		return;
	}
	//	get the server that was originally selected
	NSInteger		row = [tableView selectedRow];
	NSArray			*tmpServers = [VVOSCQueryRemoteServer remoteServers];
	VVOSCQueryRemoteServer		*tmpServer = (tmpServers==nil || row<0 || row>=[tmpServers count]) ? nil : [tmpServers objectAtIndex:row];
	//	reload the table view
	[tableView reloadData];
	//	try to re-select the server that was originally selected (select nothing if it's gone)
	tmpServers = [VVOSCQueryRemoteServer remoteServers];
	row = (tmpServers==nil || tmpServer==nil) ? NSNotFound : [tmpServers indexOfObjectIdenticalTo:tmpServer];
	NSIndexSet		*ix = (row==NSNotFound) ? nil : [NSIndexSet indexSetWithIndex:row];
	[tableView selectRowIndexes:ix byExtendingSelection:NO];
}


- (IBAction) deleteServerClicked:(id)sender	{
	NSLog(@"%s",__func__);
}
- (IBAction) createServerClicked:(id)sender	{
	NSLog(@"%s",__func__);
}
- (IBAction) reloadListClicked:(id)sender	{
	NSLog(@"%s",__func__);
}


@end
