#import "MOQHOSCManager.h"
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>




NSString * const TargetAppHostInfoChangedNotification = @"TargetAppHostInfoChangedNotification";




@implementation MOQHOSCManager


- (void) _generalInit	{
	[super _generalInit];
	[self setInPortLabelBase:@"MIDI OSCQuery Helper"];
}
- (void) awakeFromNib	{
	//	if there's a saved default for the IP address/port, put 'em in the fields
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSNumber			*tmpNum = nil;
	tmpNum = [def objectForKey:@"lastPort"];
	if (tmpNum == nil)
		tmpNum = [NSNumber numberWithInteger:1245];
	[self setPortInt:[tmpNum intValue]];
}
- (void) setPortInt:(int)inPortInt	{
	OSCInPort		*tmpPort = [inPortArray lockObjectAtIndex:0];
	if (tmpPort != nil && [tmpPort port] != inPortInt)	{
		[self deleteAllInputs];
		tmpPort = nil;
	}
	if (tmpPort == nil)
		tmpPort = [self createNewInputForPort:inPortInt];
	
	//int				newPortInt = [tmpPort port];
	NSString		*newPortString = [NSString stringWithFormat:@"%d",[tmpPort port]];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![[portField stringValue] isEqualToString:newPortString])
			[portField setStringValue:newPortString];
	});
}
- (NSDictionary *) oscQueryHostInfo	{
	NSMutableDictionary		*returnMe = [[NSMutableDictionary alloc] init];
	OSCInPort				*tmpPort = [self inPort];
	if (tmpPort != nil)	{
		[returnMe setObject:[NSNumber numberWithInteger:[tmpPort port]] forKey:kVVOSCQ_ReqAttr_HostInfo_OSCPort];
	}
	return returnMe;
}
- (IBAction) textFieldUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	NSUInteger		tmpInt = [portField intValue];
	
	[self setPortInt:(int)tmpInt];
	
	//	post a notification that the HOST_INFO information has changed
	[[NSNotificationCenter defaultCenter] postNotificationName:TargetAppHostInfoChangedNotification object:nil];
}
- (void) receivedOSCMessage:(OSCMessage *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	[as dispatchMessage:n];
}
- (OSCInPort *) inPort	{
	OSCInPort		*returnMe = [inPortArray lockObjectAtIndex:0];
	return returnMe;
}


@end
