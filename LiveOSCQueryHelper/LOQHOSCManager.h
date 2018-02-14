#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>




//	this is the name of the notification that is posted any time the host info is changed by the user
extern NSString * const TargetAppHostInfoChangedNotification;




@interface LOQHOSCManager : OSCManager	{
	IBOutlet NSTextField		*portField;	//	this app will create an OSC input that listens on this port
}

- (void) setPortInt:(int)inPortInt;

- (NSDictionary *) oscQueryHostInfo;

- (IBAction) textFieldUsed:(id)sender;

- (OSCInPort *) inPort;

@end
