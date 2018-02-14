#import "LOQHMIDIManager.h"

@implementation LOQHMIDIManager

- (void) generalInit	{
	[super generalInit];
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
- (void) sendMsg:(VVMIDIMessage *)m	{
	//NSLog(@"%s ... %@",__func__,m);
	//	we only want to send the message to my virtual destination, and to the destination specified
	[virtualDest sendMsg:m];
}
- (NSString *) receivingNodeName	{
	return @"To Live OSCQuery Helper";
}
- (NSString *) sendingNodeName	{
	return @"From Live OSCQuery Helper";
}

@end
