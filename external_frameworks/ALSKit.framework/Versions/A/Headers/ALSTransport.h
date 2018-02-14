#import <Foundation/Foundation.h>
#import "ALSKeyMidi.h"


@interface ALSTransport : NSObject	{

	NSArray		*parameterList;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSArray *parameterList;

@end
