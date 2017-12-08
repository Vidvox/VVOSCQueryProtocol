#import <Foundation/Foundation.h>

@interface NSNetService (NSNetServiceAdditions)

- (void) getIPAddressString:(NSString **)outIPAddressString port:(unsigned short *)outPort;

@end
