#import <Foundation/Foundation.h>

@interface ALSDevice : NSObject	{

	NSString		*deviceName;
	NSString		*userName;
	NSArray			*parameterList;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSString *deviceName;
@property (readonly) NSString *userName;
@property (readonly) NSArray *parameterList;

@end
