#import "OSCNodeAdditions.h"




@implementation OSCNode (VVOSCQueryNodeAdditions)


static BOOL			flattenSimpleOSCQArrays = NO;


+ (void) setFlattenSimpleOSCQArrays:(BOOL)n	{
	flattenSimpleOSCQArrays = n;
}
+ (BOOL) flattenSimpleOSCQArrays	{
	return flattenSimpleOSCQArrays;
}
- (VVOSCQueryReply *) getReplyForOSCQuery:(VVOSCQuery *)q	{
	//NSLog(@"%s ... %@",__func__,self);
	VVOSCQueryReply			*returnMe = nil;
	NSMutableDictionary		*replyJSONObject = nil;
	NSDictionary			*params = [q params];
	//	if there are params...
	if (params!=nil)	{
		replyJSONObject = [[NSMutableDictionary alloc] init];
		//	get a full JSON query object for myself
		//NSDictionary			*myJSONObject = [self createJSONObjectForOSCQueryRecursively:NO];
		NSDictionary			*myJSONObject = [self createJSONObjectForOSCQuery];
		//NSLog(@"\t\tmyJSONObject is %@",myJSONObject);
		//	run through all the params from the query
		[params enumerateKeysAndObjectsUsingBlock:^(NSString *key, id val, BOOL *stop)	{
			//	if there's an object in my JSON query object for this parameter, add it to the reply object
			id		myVal = [myJSONObject objectForKey:key];
			if (myVal != nil)
				[replyJSONObject setObject:myVal forKey:key];
		}];
	}
	else	{
		replyJSONObject = [self createJSONObjectForOSCQueryRecursively:YES];
	}
	
	if (replyJSONObject != nil)
		returnMe = [[VVOSCQueryReply alloc] initWithJSONObject:replyJSONObject];
	else
		returnMe = [[VVOSCQueryReply alloc] initWithErrorCode:404];
	return returnMe;
}


- (NSMutableDictionary *) createJSONObjectForOSCQuery	{
	NSMutableDictionary		*returnMe = [self createJSONObjectForOSCQueryRecursively:NO];
	
	NSMutableDictionary	*contentsDict = [[NSMutableDictionary alloc] init];
	NSArray				*origContents = [nodeContents lockCreateArrayCopy];
	for (OSCNode *tmpNode in origContents)	{
		NSDictionary		*tmpNodeJSONDict = [tmpNode createJSONObjectForOSCQueryRecursively:NO];
		NSString			*tmpKey = [tmpNode nodeName];
		if (tmpNodeJSONDict != nil && tmpKey != nil)
			[contentsDict setObject:tmpNodeJSONDict forKey:tmpKey];
	}
	if ([contentsDict count]>0)
		[returnMe setObject:contentsDict forKey:kVVOSCQ_ReqAttr_Contents];
	
	return returnMe;
}
- (NSMutableDictionary *) createJSONObjectForOSCQueryRecursively:(BOOL)isRecursive	{
	//NSLog(@"%s ... %@",__func__,self);
	NSMutableDictionary		*returnMe = [[NSMutableDictionary alloc] init];
	NSString				*tmpString = nil;
	NSNumber				*tmpNum = nil;
	NSArray					*tmpArray = nil;
	
	OSSpinLockLock(&nameLock);
	if (fullName != nil)
		[returnMe setObject:fullName forKey:kVVOSCQ_ReqAttr_Path];
	//	if there's no full name- if we can't make a path- then we need to bail and return nil immediately
	else	{
		returnMe = nil;
	}
	OSSpinLockUnlock(&nameLock);
	if (returnMe == nil)
		return nil;
	
	tmpString = [self oscDescription];
	if (tmpString != nil)
		[returnMe setObject:tmpString forKey:kVVOSCQ_ReqAttr_Desc];
	tmpArray = [self tags];
	if (tmpArray != nil)
		[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Tags];
	tmpString = [self typeTagString];
	if (tmpString != nil)
		[returnMe setObject:tmpString forKey:kVVOSCQ_ReqAttr_Type];
	tmpArray = [self extendedType];
	if (tmpArray != nil)	{
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Ext_Type];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Ext_Type];
	}
	tmpNum = [NSNumber numberWithInteger:[self access]];
	if (tmpNum != nil)
		[returnMe setObject:tmpNum forKey:kVVOSCQ_OptAttr_Access];
	
	OSSpinLockLock(&lastReceivedMessageLock);
	OSCMessage		*lastMsg = lastReceivedMessage;
	OSSpinLockUnlock(&lastReceivedMessageLock);
	
	int				lastMsgValCount = [lastMsg valueCount];
	if (lastMsg != nil && lastMsgValCount > 0)	{
		if (lastMsgValCount == 1)	{
			OSCValue		*oscVal = [lastMsg value];
			id				nsVal = (oscVal==nil) ? nil : [oscVal jsonValue];
			if (nsVal != nil)	{
				if (flattenSimpleOSCQArrays)
					[returnMe setObject:nsVal forKey:kVVOSCQ_OptAttr_Value];
				else
					[returnMe setObject:@[ nsVal ] forKey:kVVOSCQ_OptAttr_Value];
			}
		}
		else	{
			NSMutableArray		*tmpValArray = [[NSMutableArray alloc] init];
			for (OSCValue *tmpVal in [lastMsg valueArray])	{
				id				nsVal = (tmpVal==nil) ? nil : [tmpVal jsonValue];
				if (nsVal != nil)
					[tmpValArray addObject:nsVal];
			}
			[returnMe setObject:tmpValArray forKey:kVVOSCQ_OptAttr_Value];
		}
	}
	
	tmpArray = [self range];
	if (tmpArray != nil)
		[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Range];
	tmpArray = [self clipmode];
	if (tmpArray != nil)	{
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Clipmode];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Clipmode];
	}
	tmpArray = [self units];
	if (tmpArray != nil)	{
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Unit];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Unit];
	}
	
	if (isRecursive)	{
		NSMutableDictionary	*contentsDict = [[NSMutableDictionary alloc] init];
		NSArray				*origContents = [nodeContents lockCreateArrayCopy];
		for (OSCNode *tmpNode in origContents)	{
			NSDictionary		*tmpNodeJSONDict = [tmpNode createJSONObjectForOSCQueryRecursively:isRecursive];
			NSString			*tmpKey = [tmpNode nodeName];
			if (tmpNodeJSONDict != nil && tmpKey != nil)
				[contentsDict setObject:tmpNodeJSONDict forKey:tmpKey];
		}
		if ([contentsDict count]>0)
			[returnMe setObject:contentsDict forKey:kVVOSCQ_ReqAttr_Contents];
	}
	
	return returnMe;
}


@end
