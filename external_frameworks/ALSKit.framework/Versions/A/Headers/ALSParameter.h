#import <Foundation/Foundation.h>
#import "ALSKeyMidi.h"

@interface ALSParameter : NSObject	{

	NSString		*title;
	ALSKeyMidi		*keyMidi;
	double			value;
	BOOL			hasValue;
}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSString *title;
@property (readonly) ALSKeyMidi *keyMidi;
@property (readonly) double value;
@property (readonly) BOOL hasValue;

@end
