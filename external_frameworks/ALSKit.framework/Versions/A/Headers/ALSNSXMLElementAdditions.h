#import <Foundation/Foundation.h>

@interface NSXMLElement (ALSNSXMLElementAdditions)

+ (NSNumber *) numberForALSAttributeString:(NSString *)s;
- (NSNumber *) valueForFirstElementNamed:(NSString *)n;
- (NSXMLElement *) firstElementForName:(NSString *)n;

@end
