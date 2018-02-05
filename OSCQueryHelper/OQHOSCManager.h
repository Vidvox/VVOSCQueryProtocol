#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>



//	this is the name of the notification that is posted any time the host info is changed by the user
extern NSString * const TargetAppHostInfoChangedNotification;




@interface FakeOSCInPort : NSObject
- (void) _addMessage:(OSCMessage *)n;
- (NSArray *) dumpArray;
@end




@interface OQHOSCManager : OSCManager	{
	OSCOutPort		*outPort;	//	configured to send OSC data to remote app (sends OSC packets that were sent to the query server over websocket connection)
	
	IBOutlet NSTextField		*ipField;	//	IP of remote app to use in query server's HOST_INFO dict
	IBOutlet NSTextField		*portField;	//	port of remote app to use in query server's HOST_INFO dict
	IBOutlet NSPopUpButton		*outputDestinationButton;	//	list of destinations to be used in query server's HOST_INFO dict
}

- (void) setIPString:(NSString *)inIPString portInt:(NSUInteger)inPortInt;

- (NSDictionary *) oscQueryHostInfo;

- (void) oscOutputsChangedNotification:(NSNotification *)note;
- (IBAction) textFieldUsed:(id)sender;
- (IBAction) outputDestinationButtonUsed:(id)sender;

- (OSCOutPort *) outPort;

@end
