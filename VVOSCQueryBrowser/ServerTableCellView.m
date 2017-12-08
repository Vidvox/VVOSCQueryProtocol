#import "ServerTableCellView.h"

@implementation ServerTableCellView

- (void) refreshWithServer:(VVOSCQueryRemoteServer *)s	{
	NSString		*tmpString = nil;
	
	tmpString = (s==nil) ? @"???" : [NSString stringWithFormat:@"%@/%@",[s bonjourName],[s oscName]];
	[nameField setStringValue:tmpString];
	
	tmpString = (s==nil) ? @"???" : [NSString stringWithFormat:@"%@:%d",[s webServerAddressString],[s webServerPort]];
	if (tmpString == nil)
		tmpString = @"???";
	[addressField setStringValue:tmpString];
}

@end
