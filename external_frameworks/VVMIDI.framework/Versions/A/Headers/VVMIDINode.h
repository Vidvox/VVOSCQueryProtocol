
#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>
#import <VVMIDI/VVMIDIMessage.h>




extern BOOL			_VVMIDIFourteenBitCCs;	//	NO by default. according to MIDI spec, CCs 32-63 are the LSBs of 14-bit values (CCs 0-31 are the MSBs).  some controllers/apps don't support the spec properly, and expect these CCs to be 64 different (low-res) values.  set this BOOL to NO if you want this fmwk to treat CCs 0-63 as 7-bit vals, in violation of the spec.  note that if this BOOL is YES, CCs 0-31 will be treated as 7-bit values until the corresponding value from CC32-63 is received, at which point it will automatically switch to 14-bit.
extern double		_machTimeToNsFactor;



@interface VVMIDINode : NSObject {
	MIDIEndpointRef			endpointRef;	//	the endpoint for this particular node
	NSMutableDictionary		*properties;	//	dict or source properties (just for the hell of it)
	MIDIPortRef				portRef;		//	the port is owned by the client, and connects it to the endpoint
	CAClockRef				mtcClockRef;
	CAClockRef				bpmClockRef;
	BOOL					procRunning;	//	YES while MIDI callback is executing- limit access to CoreMIDI vars to times when this is NO.
	
	NSString				*name;
	NSString				*deviceName;
	id						delegate;		//	the delegate will be passed any data i receive
	BOOL					sender;			//	if it's a midi-sending endpoint, this will be YES
	BOOL					virtualSender;	//	whether or not the sender is locally owned
	//	make sure processing sysex can happen across multiple iterations of the callback loop
	BOOL					processingSysex;
	int						processingSysexIterationCount;
	NSMutableArray			*sysexArray;	//	received sysex data is added to this array.  array is instance in node because a sysex dump may be split up across several MIDI packets, so we need something persistent...
	//	the node will always *process* midi, but it will only send/receive midi if 'enabled' is YES
	BOOL					enabled;
	
	int						twoPieceCCVals[16][64];	//	midi CCs 0-31 are the MSBs ("coarse") of values, and CCs 32-64 are the LSBs ("fine"). in order to reconstruct the full 32-bit value from either received piece, i need to store both "pieces" of it (for each channel).  all the LSBs are set to -1 until an actual value is received: if the LSBs aren't being used, then the math changes subtly (7-bit 127 as 1.0 vs 7-bit MSB not being 1.0)
	
	//	this mutex makes sure multiple threads sending to this node simultaneously don't collide
	pthread_mutex_t			sendingLock;
	
	//	if i'm a sender, these variables are used to store a packet list
	MIDIPacketList			*packetList;
	MIDIPacket				*currentPacket;
	Byte					scratchStruct[4];
}

- (instancetype) initReceiverWithEndpoint:(MIDIEndpointRef)e;
- (instancetype) initReceiverWithName:(NSString *)n;
- (instancetype) initSenderWithEndpoint:(MIDIEndpointRef)e;
- (instancetype) initSenderWithName:(NSString *)n;

- (instancetype) commonInit;

- (void) loadProperties;
- (void) receivedMIDI:(NSArray *)a;

- (void) sendMsg:(VVMIDIMessage *)m;
- (void) sendMsgs:(NSArray *)a;

- (BOOL) sender;
- (BOOL) receiver;

- (MIDIEndpointRef) endpointRef;
- (NSMutableDictionary *) properties;
- (CAClockRef) mtcClockRef;
@property (assign,readwrite) BOOL procRunning;
- (NSString *) name;
- (NSString *) deviceName;
- (NSString *) fullName;
- (id) delegate;
- (void) setDelegate:(id)n;
- (BOOL) processingSysex;
- (void) setProcessingSysex:(BOOL)n;
- (int) processingSysexIterationCount;
- (void) setProcessingSysexIterationCount:(int)n;
- (NSMutableArray *) sysexArray;
@property (assign,readwrite) BOOL enabled;
- (void) _getValsForCC:(int)cc channel:(int)c toMSB:(int *)msb LSB:(int *)lsb;
- (void) _setValsForCC:(int)cc channel:(int)c fromMSB:(int)msb LSB:(int)lsb;
- (double) MTCQuarterFrameSMPTEAsDouble;
- (double) MTCFPS;
- (double) midiClockBeats;
- (double) midiClockBPM;

@end

void myMIDIReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon);
void senderReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon);
void clockListenerProc(void *userData, CAClockMessage msg, const void *param);
