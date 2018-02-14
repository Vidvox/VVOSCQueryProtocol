#import "OQHOSCManager.h"
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#include <mutex>




using namespace std;

@interface FakeOSCInPort ()	{
	NSMutableArray	*array;
	mutex			lock;
}
@end

@implementation FakeOSCInPort
- (id) init	{
	self = [super init];
	if (self != nil)	{
		array = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void) dealloc	{
	array = nil;
}
- (void) _addMessage:(OSCMessage *)n	{
	lock_guard<mutex>		tmpLock(lock);
	if (n != nil)
		[array addObject:n];
}
- (NSArray *) dumpArray	{
	lock_guard<mutex>		tmpLock(lock);
	NSArray		*returnMe = [array copy];
	[array removeAllObjects];
	return returnMe;
}
@end




NSString * const TargetAppHostInfoChangedNotification = @"TargetAppHostInfoChangedNotification";




@implementation OQHOSCManager


- (void) _generalInit	{
	[super _generalInit];
	[self setInPortLabelBase:@"OSCQuery Helper"];
	
	
}


- (void) awakeFromNib	{
	NSArray			*ipv4s = [OSCManager hostIPv4Addresses];
	//	if there's a saved default for the IP address/port, put 'em in the fields
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSString			*tmpString = nil;
	NSNumber			*tmpNum = nil;
	//tmpString = [def objectForKey:@"lastIPAddress"];
	if (tmpString == nil && [ipv4s count]>0)
		tmpString = [ipv4s objectAtIndex:0];
	if (tmpString == nil)
		tmpString = @"127.0.0.1";
	tmpNum = [def objectForKey:@"lastPort"];
	if (tmpNum == nil)
		tmpNum = [NSNumber numberWithInteger:1240];
	[self setIPString:tmpString portInt:[tmpNum intValue]];
	
	//	fake an outputs-changed notification to make sure my list of destinations updates (in case it refreshes before i'm awake)
	[self oscOutputsChangedNotification:nil];
	//	register to receive notifications that the list of osc outputs has changed
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oscOutputsChangedNotification:) name:OSCOutPortsChangedNotification object:nil];
}

- (void) setIPString:(NSString *)inIPString portInt:(NSUInteger)inPortInt	{
	//	update the out port and the UI
	if (outPort != nil)	{
		[self removeOutput:outPort];
		outPort = nil;
	}
	outPort = [self createNewOutputToAddress:inIPString atPort:(int)inPortInt withLabel:@"OSCQuery Helper"];
	//	update the UI
	[ipField setStringValue:[outPort addressString]];
	[portField setIntValue:[outPort port]];
	//	update the user defaults
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	[def setObject:[outPort addressString] forKey:@"lastIPAddress"];
	[def setObject:[NSNumber numberWithInt:[outPort port]] forKey:@"lastPort"];
	[def synchronize];
	
	//	...do NOT post a notification that the HOST_INFO information has changed here!
}

- (NSDictionary *) oscQueryHostInfo	{
	NSMutableDictionary		*returnMe = [[NSMutableDictionary alloc] init];
	//	if the IP address we're sending to is equivalent to localhost, we don't have to include it in the returned object
	NSArray			*hostIPs = [OSCManager hostIPv4Addresses];
	NSString		*currentIP = [outPort addressString];
	if (currentIP!=nil && ![hostIPs containsObject:currentIP])
		[returnMe setObject:currentIP forKey:kVVOSCQ_ReqAttr_HostInfo_OSCIP];
	//	we always have to include the port
	[returnMe setObject:[NSNumber numberWithInteger:[outPort port]] forKey:kVVOSCQ_ReqAttr_HostInfo_OSCPort];
	return returnMe;
}

- (void) oscOutputsChangedNotification:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self oscOutputsChangedNotification:note];
		});
		return;
	}
	
	NSMutableArray			*portLabelArray = nil;
	
	//	remove the items in the pop-up button
	[outputDestinationButton removeAllItems];
	//	get an array of the out port labels
	portLabelArray = [[self outPortLabelArray] mutableCopy];
	//	remove the output corresponding to my out port
	[portLabelArray removeObject:@"OSCQuery Helper"];
	//	push the labels to the pop-up button of destinations
	[outputDestinationButton addItemsWithTitles:portLabelArray];
	//	make sure no destinations appear selected
	[outputDestinationButton selectItem:nil];
}
- (IBAction) outputDestinationButtonUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	OSCOutPort		*selectedPort = nil;
	selectedPort = [self findOutputWithLabel:[outputDestinationButton titleOfSelectedItem]];
	if (selectedPort == nil)
		return;
	//	push the data of the selected output to the fields
	[ipField setStringValue:[selectedPort addressString]];
	[portField setStringValue:[NSString stringWithFormat:@"%d",[selectedPort port]]];
	//	bump the fields (which updates the manualOutPort, which is the only out port sending data)
	[self textFieldUsed:nil];
	//	make sure no destinations appear selected
	[outputDestinationButton selectItem:nil];
}
- (IBAction) textFieldUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	
	NSString		*tmpIPString = [ipField stringValue];
	NSArray			*ipv4s = [OSCManager hostIPv4Addresses];
	if ([tmpIPString isEqualToString:@"127.0.0.1"] || [tmpIPString caseInsensitiveCompare:@"localhost"]==NSOrderedSame)	{
		if ([ipv4s count]>0)
			tmpIPString = [ipv4s objectAtIndex:0];
	}
	NSUInteger		tmpInt = [portField intValue];
	
	[self setIPString:tmpIPString portInt:tmpInt];
	
	//	post a notification that the HOST_INFO information has changed
	[[NSNotificationCenter defaultCenter] postNotificationName:TargetAppHostInfoChangedNotification object:nil];
}
- (void) receivedOSCMessage:(OSCMessage *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	[as dispatchMessage:n];
}
- (OSCOutPort *) outPort	{
	return outPort;
}


@end
