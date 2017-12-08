#import <Cocoa/Cocoa.h>

@interface NSString (NSStringAdditions)

- (NSString *) stringBySanitizingForOSCPath;
- (NSString *) stringByDeletingLastAndAddingFirstSlash;

@end
