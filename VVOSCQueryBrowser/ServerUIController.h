#import <Cocoa/Cocoa.h>
#import <VVOSC/VVOSC.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "RemoteNode.h"




@interface ServerUIController : NSObject <VVOSCQueryRemoteServerDelegate>	{
	OSCManager				*oscm;	//	the actual OSC manager
	
	__weak VVOSCQueryRemoteServer		*server;
	NSString							*urlReplyString;	//	the URL field issues queries, which are parsed and displayed as UI items and raw JSON text.  the last received reply to these queries is stored here, as its raw text.
	NSMutableArray<RemoteNode*>			*urlReplyRemoteNodes;	//	array of RemoteNode instances created from the 
	
	IBOutlet NSTextField	*urlField;
	IBOutlet NSTabView		*tabView;
	IBOutlet NSOutlineView	*uiItemOutlineView;
	IBOutlet NSTextView		*rawJSONTextView;
}

//	the global singleton
@property (class,readonly) ServerUIController * global;

@property (weak) VVOSCQueryRemoteServer * server;

- (IBAction) urlFieldUsed:(id)sender;

- (void) newServerChosen:(VVOSCQueryRemoteServer*)n;
- (void) sendMessageToRemoteServer:(OSCMessage *)n;

@end
