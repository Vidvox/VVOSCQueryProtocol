#import <Foundation/Foundation.h>

@interface ALSDeviceChain : NSObject	{

	NSArray		*devices;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSArray *devices;

@end
