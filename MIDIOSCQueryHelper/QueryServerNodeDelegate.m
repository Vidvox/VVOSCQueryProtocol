#import "QueryServerNodeDelegate.h"




@implementation QueryServerNodeDelegate


- (id) initWithMIDIManager:(VVMIDIManager *)n forAddress:(NSString *)a	{
	//NSLog(@"%s ... %@, %@",__func__,n,a);
	self = [super init];
	if (self != nil)	{
		midiManager = n;
		address = a;
		midiMsgType = VVMIDIMsgUnknown;
		midiChannel = 0;
		midiVoice = 0;
		
		hasMin = NO;
		minVal = 0.;
		hasMax = NO;
		maxVal = 0.;
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
	[self setMIDIManager:nil];
	[self setAddress:nil];
}


- (void) sendMsg:(VVMIDIMessage *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	//NSLog(@"\t\tmidiManager is %@",midiManager);
	[midiManager sendMsg:n];
}


- (void) node:(id)n receivedOSCMessage:(OSCMessage *)msg	{
	//NSLog(@"%s ... %@, %@",__func__,n,msg);
	if (midiMsgType == VVMIDIMsgUnknown)	{
		NSLog(@"\t\terr: bailing, msg type is unknown, %s",__func__);
		return;
	}
	
	OSCValue			*oscVal = [msg value];
	if (oscVal == nil)
		return;
	
	//	we're going to want to create a new MIDI message to send.
	VVMIDIMessage		*newMsg = nil;
	
	//	MIDI is based on unsigned integer values that can possibly go as high as 14-bits, so we need to convert whatever we got to the raw integer that we're going to send
	uint32_t			msgIntVal = 0;	//	try to assemble a raw int value we can use directly
	double				msgNormVal = 0.;	//	try to assemble a normalized double val we can use if we're 14-bit
	switch ([oscVal type])	{
	case OSCValMIDI:	//	MIDI-type OSC messages can be converted perfectly, do so now
		newMsg = [[VVMIDIMessage alloc] initFromVals:[oscVal midiPort]:[oscVal midiStatus]:[oscVal midiData1]:[oscVal midiData2]];
		[self sendMsg:newMsg];
		return;	//	return, not break!
	case OSCValInt:
	case OSCVal64Int:
	case OSCValChar:
		msgNormVal = 0.;
		msgIntVal = [oscVal calculateIntValue];
		break;
	case OSCValFloat:
	case OSCValDouble:
		if (hasMin && hasMax)	{
			msgNormVal = [oscVal calculateDoubleValue];
			msgNormVal = (msgNormVal-minVal)/(maxVal-minVal);
			msgIntVal = msgNormVal * 127.0;
		}
		else	{
			msgNormVal = [oscVal calculateDoubleValue];
			msgIntVal = [oscVal calculateIntValue];
		}
		break;
	case OSCValBool:
		if ([oscVal boolValue])	{
			msgNormVal = 1.;
			msgIntVal = 127;
		}
		else	{
			msgNormVal = 0.;
			msgIntVal = 0;
		}
		break;
	case OSCValInfinity:
		msgNormVal = 1.;
		msgIntVal = 127;
		break;
	case OSCValNil:
		msgNormVal = 0.;
		msgIntVal = 0;
		break;
	case OSCValString:
	case OSCValColor:
	case OSCValTimeTag:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
	case OSCValUnknown:
		break;
	}
	//NSLog(@"\t\tmsgIntVal is %ld, msgNormVal is %0.2f",msgIntVal,msgNormVal);
	
	
	//	now that we have tried to assemble both a raw integer value and a normalized double, we can try to assemble a message
	switch (midiMsgType)	{
	case VVMIDINoteOffVal:
	case VVMIDINoteOnVal:
		{
			//	note off if velocity is 0
			if (msgIntVal == 0)
				newMsg = [[VVMIDIMessage alloc] initFromVals:VVMIDINoteOffVal:midiChannel:midiVoice:msgIntVal];
			else
				newMsg = [[VVMIDIMessage alloc] initFromVals:VVMIDINoteOnVal:midiChannel:midiVoice:msgIntVal];
		}
		break;
	case VVMIDIAfterTouchVal:
	case VVMIDIControlChangeVal:
		newMsg = [[VVMIDIMessage alloc] initFromVals:midiMsgType:midiChannel:midiVoice:msgIntVal];
		break;
	case VVMIDIProgramChangeVal:
	case VVMIDIChannelPressureVal:
		newMsg = [[VVMIDIMessage alloc] initFromVals:midiMsgType:midiChannel:msgIntVal:0];
		break;
	case VVMIDIPitchWheelVal:
		{
			uint8_t		msb = ((msgIntVal >> 7) & 0x7F);
			uint8_t		lsb = (msgIntVal & 0x7F);
			newMsg = [[VVMIDIMessage alloc] initFromVals:midiMsgType:midiChannel:msb:lsb];
		}
		break;
	//	these are included to cut down on compiler warnings (i didn't want to just add a 'default')
	case VVMIDIBeginSysexDumpVal:
	case VVMIDIMTCQuarterFrameVal:
	case VVMIDISongPosPointerVal:
	case VVMIDISongSelectVal:
	case VVMIDIUndefinedCommon1Val:
	case VVMIDIUndefinedCommon2Val:
	case VVMIDITuneRequestVal:
	case VVMIDIEndSysexDumpVal:
	case VVMIDIClockVal:
	case VVMIDITickVal:
	case VVMIDIStartVal:
	case VVMIDIContinueVal:
	case VVMIDIStopVal:
	case VVMIDIUndefinedRealtime1Val:
	case VVMIDIActiveSenseVal:
	case VVMIDIResetVal:
	case VVMIDIMsgUnknown:
		break;
	}
	
	
	//	send the msg...
	[self sendMsg:newMsg];
	
}
- (void) nodeNameChanged:(id)node	{
	[self setAddress:[node fullName]];
}
- (void) nodeDeleted:(id)node	{
	//	do nothing, passing delete messages to the query server is oustide the scope of this class
}


@synthesize midiManager;
@synthesize address;
@synthesize midiMsgType;
@synthesize midiChannel;
@synthesize midiVoice;

@synthesize hasMin;
@synthesize minVal;
@synthesize hasMax;
@synthesize maxVal;


@end
