#import "RemoteNodeControl.h"
#import "RemoteNode.h"


@implementation RemoteNodeControl

- (id) initWithParent:(RemoteNode *)n typeString:(NSString *)t	{
	//NSLog(@"%s ... %@",__func__,n);
	self = [super init];
	if (self != nil)	{
		parentNode = n;
		typeString = t;
		value = nil;
		min = nil;
		max = nil;
		vals = nil;
	}
	return self;
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<RNC %@ in %@>",typeString,[parentNode name]];
}


- (OSCValue *) createCurrentOSCValue	{
	//	try to return the value
	if (value != nil)
		return value;
	//	if there wasn't a val, try to return the min
	if (min != nil)
		return min;
	//	if there was neither a val nor a min, try to return a max?
	if (max != nil)
		return max;
	//	if there have been no guidelines whatsoever then just make something up.
	unichar		tmpChar = [typeString characterAtIndex:0];
	switch (tmpChar)	{
	case 'i':
		return [OSCValue createWithInt:0];
	case 'f':
		return [OSCValue createWithFloat:0.];
	case 's':
	case 'S':
		return [OSCValue createWithString:@"Default string value"];
	case 'b':
		return [OSCValue createWithNSDataBlob:[NSMutableData dataWithLength:12]];
	case 'h':
		return [OSCValue createWithLongLong:0];
	case 't':
		return [OSCValue createTimeWithDate:[NSDate date]];
	case 'd':
		return [OSCValue createWithDouble:0.];
	case 'c':
		return [OSCValue createWithChar:'a'];
	case 'r':
		return [OSCValue createWithColor:[NSColor colorWithDeviceRed:0.25 green:0.5 blue:0.75 alpha:1.]];
	case 'm':
		return [OSCValue createWithMIDIChannel:0 status:0 data1:0 data2:0];
	case 'T':
		return [OSCValue createWithBool:YES];
	case 'F':
		return [OSCValue createWithBool:NO];
	case 'N':
		return [OSCValue createWithNil];
	case 'I':
		return [OSCValue createWithInfinity];
	//case '[':			//	indicates the start of an array
	//case ']':			//	indicates the end of an array
	case 'E':			//	SMPTE timecode. AD-HOC DATA TYPE! ONLY SUPPORTED BY THIS FRAMEWORK!
		return [OSCValue createWithSMPTEVals:OSCSMPTEFPS30:1:2:3:4:5];
	}
	return nil;
}


- (NSString *) outlineViewIdentifier	{
	return [NSString stringWithFormat:@"%@-%ld",parentNode,(parentNode==nil)?NSNotFound:[parentNode indexOfControl:self]];
}


@synthesize parentNode;
@synthesize typeString;
@synthesize value;
@synthesize min;
@synthesize max;
@synthesize vals;

@end
