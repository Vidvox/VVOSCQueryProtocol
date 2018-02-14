#import <Foundation/Foundation.h>

@interface ALSMixer : NSObject	{

	NSArray		*parameterList;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSArray *parameterList;

@end
