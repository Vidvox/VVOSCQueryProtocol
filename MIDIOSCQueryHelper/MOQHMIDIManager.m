#import "MOQHMIDIManager.h"

@implementation MOQHMIDIManager

- (void) generalInit	{
	[super generalInit];
	selectedMIDIDst = nil;
	lastSelectedName = nil;
}
- (void) awakeFromNib	{
	[super awakeFromNib];
	
	//	load the last chosen midi dst from the user defaults
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSString			*tmpString = [def objectForKey:@"lastMIDIDst"];
	if (tmpString != nil)	{
		//	just update the last selected name local var, the UI will update itself using this
		lastSelectedName = tmpString;
	}
}
- (void) createVirtualNodes	{
	//NSLog(@"%s",__func__);
	
	//	we only want to create the "sender" virtual node (the one that pretends i'm a "MIDI device")
	
	/*
		make the sender- this node "owns" the destination: it is responsible for telling
		any endpoints connected to this destination that it has received midi data
	*/
	if (virtualDest != nil)	{
		virtualDest = nil;
	}
	virtualDest = [[[self sendingNodeClass] alloc] initSenderWithName:[self sendingNodeName]];
	if (virtualDest != nil)
		[virtualDest setDelegate:self];
}
- (void) setupChanged	{
	//NSLog(@"%s",__func__);
	[super setupChanged];
	
	//	reload the contents of the pop-up button, re-select the appropriate item
	NSMenu			*tmpMenu = [selectedMIDIDstPUB menu];
	[tmpMenu removeAllItems];
	for (NSString *tmpName in [self destNodeFullNameArray])	{
		[tmpMenu addItemWithTitle:tmpName action:nil keyEquivalent:@""];
	}
	//	re-select the appropriate item from the pop-up button
	if (lastSelectedName == nil)
		[selectedMIDIDstPUB selectItem:nil];
	else
		[selectedMIDIDstPUB selectItemWithTitle:lastSelectedName];
	
	//	update my selected midi destination variable using the last name selected by the user
	selectedMIDIDst = (lastSelectedName==nil) ? nil : [self findDestNodeWithFullName:lastSelectedName];
}
- (void) sendMsg:(VVMIDIMessage *)m	{
	//NSLog(@"%s ... %@",__func__,m);
	//NSLog(@"\t\tselectedMIDIDst is %@",selectedMIDIDst);
	//	we only want to send the message to my virtual destination, and to the destination specified
	[selectedMIDIDst sendMsg:m];
	[virtualDest sendMsg:m];
}
- (NSString *) receivingNodeName	{
	return @"To Live OSCQuery Helper";
}
- (NSString *) sendingNodeName	{
	return @"From Live OSCQuery Helper";
}

@synthesize selectedMIDIDst;
@synthesize lastSelectedName;

- (IBAction) selectedMIDIDstPUBUsed:(id)sender	{
	//	update the last selected name
	lastSelectedName = [sender titleOfSelectedItem];
	if (lastSelectedName != nil)	{
		//	update my user defaults so we start with this MIDI destination next time we're launched
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		[def setObject:lastSelectedName forKey:@"lastMIDIDst"];
		[def synchronize];
	}
	
	//	update the local MIDI destination var
	selectedMIDIDst = [self findDestNodeWithFullName:lastSelectedName];
}

@end
