#import "VVOSCQueryReply.h"




@implementation VVOSCQueryReply


+ (NSDictionary *) jsonObjectWithPath:(NSString *)inFullPath
contents:(NSDictionary*)inContents
description:(NSString *)inDescription
tags:(NSArray<NSString*> *)inTags
extendedType:(NSArray<NSString*> *)inExtType
type:(NSString *)inTypeTagString
access:(VVOSCQueryNodeAccess)inAccess
value:(NSArray *)inValueArray
range:(NSArray *)inRangeArray
clipmode:(NSArray *)inClipmodeArray
units:(NSArray *)inUnitsArray
critical:(BOOL)inCritical
overloads:(NSArray *)inOverloadsArray	{
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	if (inFullPath != nil)
		[returnMe setObject:inFullPath forKey:kVVOSCQ_ReqAttr_Path];
	//	if there's no full path then bail and return nil;
	else
		return nil;
	if (inContents != nil)
		[returnMe setObject:inContents forKey:kVVOSCQ_ReqAttr_Contents];
	if (inDescription != nil)
		[returnMe setObject:inDescription forKey:kVVOSCQ_ReqAttr_Desc];
	if (inTags != nil)
		[returnMe setObject:inTags forKey:kVVOSCQ_OptAttr_Tags];
	if (inExtType != nil)	{
		//if ([inExtType count] == 1)
		//	[returnMe setObject:inExtType[0] forKey:kVVOSCQ_OptAttr_Ext_Type];
		//else
			[returnMe setObject:inExtType forKey:kVVOSCQ_OptAttr_Ext_Type];
	}
	if (inTypeTagString != nil)
		[returnMe setObject:inTypeTagString forKey:kVVOSCQ_ReqAttr_Type];
	[returnMe setObject:[NSNumber numberWithInteger:inAccess] forKey:kVVOSCQ_OptAttr_Access];
	if (inValueArray != nil)	{
		//if ([inValueArray count] == 1)
		//	[returnMe setObject:inValueArray[0] forKey:kVVOSCQ_OptAttr_Value];
		//else
			[returnMe setObject:inValueArray forKey:kVVOSCQ_OptAttr_Value];
	}
	if (inRangeArray != nil)	{
		//if ([inRangeArray count] == 1)
		//	[returnMe setObject:inRangeArray[0] forKey:kVVOSCQ_OptAttr_Range];
		//else
			[returnMe setObject:inRangeArray forKey:kVVOSCQ_OptAttr_Range];
	}
	if (inClipmodeArray != nil)	{
		//if ([inClipmodeArray count] == 1)
		//	[returnMe setObject:inClipmodeArray[0] forKey:kVVOSCQ_OptAttr_Clipmode];
		//else
			[returnMe setObject:inClipmodeArray forKey:kVVOSCQ_OptAttr_Clipmode];
	}
	if (inUnitsArray != nil)	{
		//if ([inUnitsArray count] == 1)
		//	[returnMe setObject:inUnitsArray[0] forKey:kVVOSCQ_OptAttr_Unit];
		//else
			[returnMe setObject:inUnitsArray forKey:kVVOSCQ_OptAttr_Unit];
	}
	if (inCritical)
		[returnMe setObject:[NSNumber numberWithBool:inCritical] forKey:kVVOSCQ_OptAttr_Critical];
	if (inOverloadsArray)
		[returnMe setObject:inOverloadsArray forKey:kVVOSCQ_OptAttr_Overloads];
	return returnMe;
}
+ (void) initialize	{
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
}


- (instancetype) initWithJSONObject:(NSDictionary *)jo	{
	self = [super init];
	if (self != nil)	{
		jsonObject = jo;
		errCode = 0;
		if (jsonObject == nil)	{
			self = nil;
		}
	}
	return self;
}
- (instancetype) initWithErrorCode:(int)ec	{
	self = [super init];
	if (self != nil)	{
		jsonObject = nil;
		errCode = ec;
	}
	return self;
}
- (void) dealloc	{
	jsonObject = nil;
}

@synthesize jsonObject;
@synthesize errCode;

- (NSString *) description	{
	if (jsonObject != nil)
		return [NSString stringWithFormat:@"<VVOSCQueryReply: %@>",[jsonObject description]];
	else
		return [NSString stringWithFormat:@"<VVOSCQueryReply: %d>",errCode];
}


@end
