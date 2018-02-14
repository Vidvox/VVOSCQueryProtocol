#import <Foundation/Foundation.h>
#import <VVMIDI/VVMIDI.h>
#import <VVOSC/VVOSC.h>
#import "VVOSCQueryServer.h"


/*		this class exists to bridge an OSC library (VVOSC.framework) with an OSC query library 
	(VVOSCQueryProtocol.framework).  instances of this class are created by software that wants to 
	connect the query server with an OSC address space- these instances are registered as delegates 
	of OSCNodes in the OSC address space.  when the nodes receive messages, these instances pass 
	those messages to the query server that created them.		*/


@interface QueryServerNodeDelegate : NSObject <OSCNodeDelegateProtocol>	{
	__weak VVMIDIManager	*midiManager;
	NSString				*address;
	
	//	we store the MIDI msg type, channel, and voice number here- these are used to create the MIDI message when appropriate
	VVMIDIMsgType		midiMsgType;
	int					midiChannel;
	int					midiVoice;
	
	//	we need expedited access to some basic properties of the OSC node we are a delegate of, because we want to try to normalize the incoming values to convert them to MIDI (we need to know if there is a min/max and what these vals are to do so)
	BOOL				hasMin;
	double				minVal;
	BOOL				hasMax;
	double				maxVal;
}

- (id) initWithMIDIManager:(VVMIDIManager *)n forAddress:(NSString *)a;

//	once we compose a VVMIDIMessage, pass it to this method to dispatch it to the appropriate MIDI devices
- (void) sendMsg:(VVMIDIMessage *)n;

@property (weak,setter=setMIDIManager:) VVMIDIManager *midiManager;
@property (strong) NSString * address;

@property (setter=setMIDIMsgType:) VVMIDIMsgType midiMsgType;
@property (setter=setMIDIChannel:) int midiChannel;
@property (setter=setMIDIVoice:) int midiVoice;

@property BOOL hasMin;
@property double minVal;
@property BOOL hasMax;
@property double maxVal;

@end
