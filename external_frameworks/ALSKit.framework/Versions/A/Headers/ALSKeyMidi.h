#import <Foundation/Foundation.h>


/*

	represents a single Key / MIDI receiver in an Ableton Live Project

*/

@interface ALSKeyMidi : NSObject	{

	int			channel;
	int			noteOrControllerNumber;
	BOOL		isNote;
	NSString	*keyString;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) int channel;
@property (readonly) int noteOrControllerNumber;
@property (readonly) BOOL isNote;
@property (readonly) NSString *keyString;

@end
