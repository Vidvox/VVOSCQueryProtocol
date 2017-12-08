#import "NSNetServiceAdditions.h"
#include <arpa/inet.h>

@implementation NSNetService (NSNetServiceAdditions)

- (void) getIPAddressString:(NSString **)outIPAddressString port:(unsigned short *)outPort	{
	//NSLog(@"%s ... %@",__func__,[self name]);
	
	//	get the array of addresses for the resolved service
	NSArray				*addressArray = [self addresses];
	//NSLog(@"\t\taddressArray is %@",addressArray);
	char				*charPtr = nil;
	struct sockaddr_in	*sock = nil;
	for (NSData *data in addressArray)	{
		sock = (struct sockaddr_in *)[data bytes];
		//	only proceed if it's an IPV4 address...
		if (sock->sin_family == AF_INET)	{
			charPtr = inet_ntoa(sock->sin_addr);
			if (charPtr != nil)
				break;
		}
	}
	
	if (charPtr == nil)	{
		//NSLog(@"\t\terr: couldnt find IP in %s",__func__);
		return;
	}
	
	//	find the ip address of the resolved service as a human-readable (quads) string
	NSString			*ipString = [NSString stringWithCString:charPtr encoding:NSASCIIStringEncoding];
	if (ipString == nil)
		return;
	//	find the port of the resolved service
	unsigned short		port = ntohs(sock->sin_port);
	
	//	update the vars we were passed
	*outIPAddressString = ipString;
	*outPort = port;
}

@end
