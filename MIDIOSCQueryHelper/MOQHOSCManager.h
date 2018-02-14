#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>




//	this is the name of the notification that is posted any time the host info is changed by the user
extern NSString * const TargetAppHostInfoChangedNotification;




/*		this class uses a particular OSC framework (VVOSC, a precompiled version of which is included 
	in the project file).  neither the OSC query protocol in general nor VVOSCQueryProtocol.framework 
	in particular require this framework- this is just the OSC framework i chose to use because i 
	happen to be familiar with it.  you could just as easily use literally any other OSC 
	framework/lib in its place.				*/




@interface MOQHOSCManager : OSCManager	{
	IBOutlet NSTextField		*portField;	//	this app will create an OSC input that listens on this port
}

- (void) setPortInt:(int)inPortInt;

- (NSDictionary *) oscQueryHostInfo;

- (IBAction) textFieldUsed:(id)sender;

- (OSCInPort *) inPort;

@end
