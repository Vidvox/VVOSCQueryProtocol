#import "NSStringAdditions.h"
#include <arpa/inet.h>

@implementation NSString (NSStringAdditions)

- (NSString *) stringBySanitizingForOSCPath	{
	//NSLog(@"%s",__func__);
	//	if i don't have any characters, return nil immediately
	if ([self length]<1)
		return nil;
	//	if there are two slashes next to one another, return nil immediately
	if ([self rangeOfString:@"//"].location != NSNotFound)
		return nil;
	
	long			length = [self length];
	NSRange			desiredRange = NSMakeRange(0,length);
	
	//	figure out if it ends with a slash
	if ([self characterAtIndex:desiredRange.length-1] == '/')
		--desiredRange.length;
	
	//	if i start with a slash...
	if ([self characterAtIndex:0] == '/')	{
		//	if the length didn't change, i don't end with a slash- so i can just return myself
		if (length == desiredRange.length)
			return self;
		//	else if the desired range has a length of less than 1, return nil
		else if (desiredRange.length < 1)
			return nil;
		//	else if the length did change, just return a substring
		return [self substringWithRange:desiredRange];
	}
	//	else if i don't start with a slash, i'll have to add one
	else	{
		//	if the length didn't change, i don't end with a slash- i just have to add one
		if (length == desiredRange.length)
			return [NSString stringWithFormat:@"/%@",self];
		//	else if the length changed, i have to add a slash at the start and delete one at the end
		else
			return [NSString stringWithFormat:@"/%@",[self substringWithRange:desiredRange]];
	}
}
- (NSString *) stringByDeletingLastAndAddingFirstSlash	{
	NSString	*returnMe = nil;
	NSUInteger	myLength = [self length];
	if (myLength < 1)
		return nil;
	BOOL		endsWSlash = ([self characterAtIndex:myLength-1]=='/')?YES:NO;
	BOOL		startsWSlash = ([self characterAtIndex:0]=='/')?YES:NO;
	if (startsWSlash && myLength<2)
		endsWSlash = NO;
	if (startsWSlash && endsWSlash)
		returnMe = [self substringWithRange:NSMakeRange(0,myLength-1)];
	else if (startsWSlash && !endsWSlash)
		returnMe = self;
	else if (!startsWSlash && endsWSlash)
		returnMe = [NSString stringWithFormat:@"/%@",[self substringWithRange:NSMakeRange(0,myLength-1)]];
	else if (!startsWSlash && !endsWSlash)
		returnMe = [NSString stringWithFormat:@"/%@",self];
	return returnMe;
}

@end
