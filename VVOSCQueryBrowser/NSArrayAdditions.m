#import "NSArrayAdditions.h"

@implementation NSArray (NSArrayAdditions)

- (NSColor *) rgbaColorFromContents	{
	if ([self count] < 3)
		return nil;
	NSNumber		*tmpR = [self objectAtIndex:0];
	NSNumber		*tmpG = [self objectAtIndex:1];
	NSNumber		*tmpB = [self objectAtIndex:2];
	NSNumber		*tmpA = ([self count]<4) ? nil : [self objectAtIndex:3];
	NSColor			*tmpColor = [NSColor
		colorWithDeviceRed:[tmpR doubleValue]
		green:[tmpG doubleValue]
		blue:[tmpB doubleValue]
		alpha:(tmpA==nil)?1.:[tmpA doubleValue]];
	return tmpColor;
}

@end
