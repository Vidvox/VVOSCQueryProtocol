#import <Cocoa/Cocoa.h>
#import <VVMIDI/VVMIDI.h>




/*		first of all, this class uses a particular MIDI framework (VVMIDI, a precompiled version of 
	which is included in the project file).  neither the OSC query protocol in general nor 
	VVOSCQueryProtocol.frameowrk in particular require this framework- this is just the MIDI 
	framework i chose to use because i happen to be familiar with it.  you could just as easily use 
	literally any other MIDI framework in its place.
	
		this is a subclass of VVMIDIManager.  this subclass exists for a couple reasons:
	- by default, midi managers create both source and destination virtual nodes.  we only want to 
	create a destination (we only want this app to appears as a "device" to other apps, we don't 
	want other apps to send MIDI data to this)
	- we don't want to send MIDI data to everything- we only want to send MIDI data to our virtual 
	destination, and to a specific destination chose by the user.
	- since we have to subclass we may as well override the setup method to handle changes to the 
	system's MIDI configuration (new MIDI device, etc)
	- since we have to subclass we may as well put the UI controller logic in here, too- the pop-up 
	button the user uses to indicate which MIDI destination this app should send data to is 
	populated by and sends data to this class.						*/




@interface MOQHMIDIManager : VVMIDIManager	{
	__weak VVMIDINode		*selectedMIDIDst;	//	the MIDI destination that the user selected
	NSString				*lastSelectedName;
	
	IBOutlet NSPopUpButton		*selectedMIDIDstPUB;
}

@property (weak) VVMIDINode * selectedMIDIDst;
@property NSString * lastSelectedName;

- (IBAction) selectedMIDIDstPUBUsed:(id)sender;

@end
