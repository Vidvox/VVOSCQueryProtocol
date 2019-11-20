#import <Cocoa/Cocoa.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "MOQHOSCManager.h"
#import "MOQHMIDIManager.h"
#import "VVKQueueCenter.h"

@interface MIDIOSCQueryHelperAppDelegate : NSObject <NSApplicationDelegate,VVOSCQueryServerDelegate,VVKQueueCenterDelegate,VVMIDIDelegateProtocol>	{
	IBOutlet MOQHOSCManager		*oscm;	//	osc manager- creates an OSC input, messages sent to that input are dispatched to the address space
	IBOutlet MOQHMIDIManager	*midim;	//	midi manager- creates a virtual destination (appears as a device to other apps) and also lets the user select a destination.  MIDI messages will be sent to both.
	
	NSMutableArray			*delegates;	//	array of QueryServerNodeDelegate instances.  each of these is a delegate of an OSCNode (the node gets a message and passes it to its delegate)
	NSMutableDictionary		*midiAddressToOSCAddressDict;	//	key is MIDI address, value is an NSMutableArray containing the OSC addresses that correspond to the key
	
	NSString				*loadedFilePath;	//	the path of the currently loaded file.
	IBOutlet NSTextField 	*fileStatusField;	//	this displays the name of the currently-loaded file in the UI
	
	VVOSCQueryServer		*server;	//	the actual OSC query server
	IBOutlet NSTextField	*serverStatusField;	//	status field in the UI that displays a clickable URL to the server
	
	IBOutlet NSWindow		*helpWindow;
}

- (IBAction) showSampleDocInFinderClicked:(id)sender;

@end

