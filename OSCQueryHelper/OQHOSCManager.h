#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>



/*		these classes uses a particular OSC framework (VVOSC, a precompiled version of which is included 
	in the project file).  neither the OSC query protocol in general nor VVOSCQueryProtocol.framework 
	in particular require this framework- this is just the OSC framework i chose to use because i 
	happen to be familiar with it.  you could just as easily use literally any other OSC 
	framework/lib in its place.				*/




//	this is the name of the notification that is posted any time the host info is changed by the user
extern NSString * const TargetAppHostInfoChangedNotification;



/*	FakeOSCInPort exists because the OSCPacket class dumps packets it parses to an OSCInPort.  we don't 
want to create an actual OSCInPort, because those listen to network traffic and automatically spawn 
a bonjour service- we don't want any of that stuff, this app isn't supposed to even be capable of 
receiving OSC data.  so we make a FakeOSCInPort class which has a similar interface to OSCInPort- 
parsed messages get dumped here, where we can retrieve them.		*/
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
