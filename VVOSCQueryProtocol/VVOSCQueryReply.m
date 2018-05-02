#import "VVOSCQueryReply.h"




@implementation VVOSCQueryReply


+ (NSDictionary *) jsonObjectWithPath:(NSString *)inFullPath
contents:(NSArray<NSDictionary*>*)inContents
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
	if (inExtType != nil)
		[returnMe setObject:inExtType forKey:kVVOSCQ_OptAttr_Ext_Type];
	if (inTypeTagString != nil)
		[returnMe setObject:inTypeTagString forKey:kVVOSCQ_ReqAttr_Type];
	[returnMe setObject:[NSNumber numberWithInteger:inAccess] forKey:kVVOSCQ_OptAttr_Access];
	if (inValueArray != nil)
		[returnMe setObject:inValueArray forKey:kVVOSCQ_OptAttr_Value];
	if (inRangeArray != nil)
		[returnMe setObject:inRangeArray forKey:kVVOSCQ_OptAttr_Range];
	if (inClipmodeArray != nil)
		[returnMe setObject:inClipmodeArray forKey:kVVOSCQ_OptAttr_Clipmode];
	if (inUnitsArray != nil)
		[returnMe setObject:inUnitsArray forKey:kVVOSCQ_OptAttr_Unit];
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


@end
