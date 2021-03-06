#import <Foundation/Foundation.h>
#import "ALSKeyMidi.h"

@interface ALSClipSlot : NSObject		{

	NSString		*title;
	NSString		*userTitle;
	ALSKeyMidi		*keyMidi;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSString *title;
@property (readonly) NSString *userTitle;
@property (readonly) ALSKeyMidi *keyMidi;

@end
