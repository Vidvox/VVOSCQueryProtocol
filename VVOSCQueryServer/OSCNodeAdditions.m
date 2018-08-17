#import "OSCNodeAdditions.h"




@implementation OSCNode (VVOSCQueryNodeAdditions)


static BOOL			flattenSimpleOSCQArrays = NO;


+ (void) setFlattenSimpleOSCQArrays:(BOOL)n	{
	flattenSimpleOSCQArrays = n;
}
+ (BOOL) flattenSimpleOSCQArrays	{
	return flattenSimpleOSCQArrays;
}
+ (id) flattenEquivalentArrayContentsToSingleVal:(NSArray *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	//	return nil if passed a nil array
	if (n==nil)
		return nil;
	
	//	make a mutable array- we're going to run through the passed array recursively, and dump all the non-array vals here
	__block NSMutableArray		*allVals = [[NSMutableArray alloc] init];
	__block __weak void		(^dumpContentsBlock)(NSArray *);
	dumpContentsBlock = ^(NSArray *inArray)	{
		for (id tmpObj in inArray)	{
			if ([tmpObj isKindOfClass:[NSArray class]])
				dumpContentsBlock(tmpObj);
			else
				[allVals addObject:tmpObj];
		}
	};
	dumpContentsBlock(n);
	
	//	check the simple cases so we can return quickly if possible
	NSUInteger				allValsCount = [allVals count];
	if (allValsCount == 0)
		return nil;
	if (allValsCount == 1)
		return [allVals objectAtIndex:0];
	
	//	if i'm here, i have to run through everything and actually check stuff!
	int				tmpIndex = 0;
	id				firstObj = nil;
	for (id tmpObj in allVals)	{
		if (tmpIndex == 0)	{
			firstObj = tmpObj;
			++tmpIndex;
			continue;
		}
		
		//	if one obj is nil but the other isn't, bail ("nil" could be [NSNull null] from a JSON null)
		if (firstObj==nil && tmpObj!=nil)
			return nil;
		else if (firstObj!=nil && tmpObj==nil)
			return nil;
		//	else if they're both null
		else if (firstObj==nil && tmpObj==nil)	{
			//	intentionally blank- do nothing, they're equivalent
		}
		//	else firstObj and tmpObj are both non-nil
		else	{
			if (![firstObj isKindOfClass:[tmpObj class]])
				return nil;
			if (![firstObj isEqualTo:tmpObj])
				return nil;
		}
		
		++tmpIndex;
	}
	
	return firstObj;
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
	NSString				*tmpTypeTagString = nil;
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
	tmpTypeTagString = [self typeTagString];
	if (tmpTypeTagString != nil)
		[returnMe setObject:tmpTypeTagString forKey:kVVOSCQ_ReqAttr_Type];
	tmpArray = [self extendedType];
	if (tmpArray != nil)	{
		/*
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Ext_Type];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Ext_Type];
		*/
		
		id			flattenedObj = (!flattenSimpleOSCQArrays) ? nil : [OSCNode flattenEquivalentArrayContentsToSingleVal:tmpArray];
		if (flattenSimpleOSCQArrays && flattenedObj!=nil)
			[returnMe setObject:flattenedObj forKey:kVVOSCQ_OptAttr_Ext_Type];
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
			/*
			[returnMe setObject:tmpValArray forKey:kVVOSCQ_OptAttr_Value];
			*/
			
			id			flattenedObj = (!flattenSimpleOSCQArrays) ? nil : [OSCNode flattenEquivalentArrayContentsToSingleVal:tmpValArray];
			if (flattenSimpleOSCQArrays && flattenedObj!=nil)
				[returnMe setObject:flattenedObj forKey:kVVOSCQ_OptAttr_Value];
			else
				[returnMe setObject:tmpValArray forKey:kVVOSCQ_OptAttr_Value];
			
		}
	}
	else if (lastMsg==nil && [tmpTypeTagString isEqualToString:@"F"])	{
		[returnMe setObject:@[ [NSNumber numberWithBool:NO] ] forKey:kVVOSCQ_OptAttr_Value];
	}
	else if (lastMsg==nil && [tmpTypeTagString isEqualToString:@"T"])	{
		[returnMe setObject:@[ [NSNumber numberWithBool:YES] ] forKey:kVVOSCQ_OptAttr_Value];
	}
	
	tmpArray = [self range];
	if (tmpArray != nil)	{
		//[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Range];
		
		id			flattenedObj = (!flattenSimpleOSCQArrays) ? nil : [OSCNode flattenEquivalentArrayContentsToSingleVal:tmpArray];
		if (flattenSimpleOSCQArrays && flattenedObj!=nil)
			[returnMe setObject:flattenedObj forKey:kVVOSCQ_OptAttr_Range];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Range];
	}
	tmpArray = [self clipmode];
	if (tmpArray != nil)	{
		/*
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Clipmode];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Clipmode];
		*/
		
		id			flattenedObj = (!flattenSimpleOSCQArrays) ? nil : [OSCNode flattenEquivalentArrayContentsToSingleVal:tmpArray];
		if (flattenSimpleOSCQArrays && flattenedObj!=nil)
			[returnMe setObject:flattenedObj forKey:kVVOSCQ_OptAttr_Clipmode];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Clipmode];
		
	}
	tmpArray = [self units];
	if (tmpArray != nil)	{
		/*
		if ([tmpArray count] == 1 && flattenSimpleOSCQArrays)
			[returnMe setObject:tmpArray[0] forKey:kVVOSCQ_OptAttr_Unit];
		else
			[returnMe setObject:tmpArray forKey:kVVOSCQ_OptAttr_Unit];
		*/
		
		id			flattenedObj = (!flattenSimpleOSCQArrays) ? nil : [OSCNode flattenEquivalentArrayContentsToSingleVal:tmpArray];
		if (flattenSimpleOSCQArrays && flattenedObj!=nil)
			[returnMe setObject:flattenedObj forKey:kVVOSCQ_OptAttr_Unit];
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
