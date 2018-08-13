#import "NSArrayAdditions.h"
#import "NSStringAdditions.h"

@implementation NSString (NSStringAdditions)

- (NSColor *) rgbaColorFrom8BPCHexContents	{
	const char			*cStr = [self UTF8String];
	size_t				strLen = [self length];
	uint32_t			parsedInt = 0;
	int					maxChannelIndex = 3;
	uint8_t				parsedVals[4] = { 255, 255, 255, 255 };
	
	/*
	//	this is what the following should equate to, logically
	if (strLen == <RGB instead of RGBA, which is technically malformed>)	{
		parsedVals[0] = (parsedInt >> 16) & 0xFF
		parsedVals[1] = (parsedInt >> 8) & 0xFF
		parsedVals[2] = (parsedInt >> 0) & 0xFF
	}
	else	{
		parsedVals[0] = (parsedInt >> 24) & 0xFF
		parsedVals[1] = (parsedInt >> 16) & 0xFF
		parsedVals[2] = (parsedInt >> 8) & 0xFF
		parsedVals[3] = (parsedInt >> 0) & 0xFF
	}
	*/
	
	if (*cStr == '#')	{
		if (strLen==9 || strLen==7)	{
			parsedInt = strtol(cStr+1, NULL, 16);
			if (strLen == 7)
				maxChannelIndex = 2;
		}
		else
			return nil;
	}
	else if (cStr[0]=='0' && (cStr[1]=='x' || cStr[1]=='X'))	{
		if (strLen==10 || strLen==8)	{
			parsedInt = strtol(cStr+2, NULL, 16);
			if (strLen == 8)
				maxChannelIndex = 2;
		}
		else
			return nil;
	}
	else
		return nil;
	
	for (int valIndex=0; valIndex<=maxChannelIndex; ++valIndex)	{
		int				bitShiftAmount = (maxChannelIndex - valIndex) * 8;	//	8 bits per channel
		parsedVals[valIndex] = (parsedInt >> bitShiftAmount) & 0xFF;
	}
	NSColor			*returnMe = [NSColor
		colorWithDeviceRed:((double)parsedVals[0])/255.
		green:((double)parsedVals[1])/255.
		blue:((double)parsedVals[2])/255.
		alpha:((double)parsedVals[3])/255.];
	return returnMe;
}

@end
