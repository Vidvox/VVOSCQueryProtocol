#import "RemoteNode.h"
#import <VVOSC/VVOSC.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>
#import "RemoteNodeControl.h"
#import "NSArrayAdditions.h"
#import "ServerUIController.h"




@implementation RemoteNode


- (id) initWithParent:(RemoteNode *)p dict:(NSDictionary *)d	{
	//NSLog(@"%s ... %@",__func__,[d objectForKey:kVVOSCQ_ReqAttr_Path]);
	//NSLog(@"\t\tdict is %@",d);
	self = [super init];
	if (self != nil)	{
		parentNode = p;
		dict = d;
		//controls = [[NSMutableArray alloc] init];
		//contents = [[NSMutableArray alloc] init];
		controls = nil;
		contents = nil;
		
		//	if there's no path, we need to bail immediately and return nil b/c there's something wrong with the source dict and we shouldn't proceed
		if ([d objectForKey:kVVOSCQ_ReqAttr_Path] == nil)	{
			self = nil;
			return self;
		}
		
		
		//	if this is ever non-nil, something went wrong and we need to bail
		__block NSError				*nsErr = nil;
		/*	make a block that will parse a type string, a JSON object array containing values corresponding 
		to the OSC type tag string structure, and another JSON object array containing range dicts 
		corresponding to the OSC type tag string structure.			*/
		__block __weak void			(^parseBlock)(NSString *typeString, NSArray *jsonValArray, NSArray *jsonRangeArray);
		parseBlock = ^(NSString *typeString, NSArray *jsonValArray, NSArray *jsonRangeArray)	{
			//NSLog(@"parseBlock() in %s",__func__);
			//NSLog(@"\t\ttypeString is %@, valArray is %@, rangeArray is %@",typeString,jsonValArray,jsonRangeArray);
			if (nsErr != nil)	{
				NSLog(@"ERR: %@",nsErr);
				return;
			}
			//	make sure all of the passed values are of the appropriate type, bail if something's wrong
			if (typeString!=nil && ![typeString isKindOfClass:[NSString class]])
				nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"type string is not a string" }];
			if (nsErr != nil)	{
				NSLog(@"ERR: %@",nsErr);
				return;
			}

			
			if (jsonValArray!=nil && ![jsonValArray isKindOfClass:[NSArray class]])	{
				nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"json VALUE array was not an array" }];
				NSLog(@"ERR: %@",nsErr);
				nsErr = nil;
				jsonValArray = nil;
			}
			if (jsonRangeArray!=nil && ![jsonRangeArray isKindOfClass:[NSArray class]])	{
				nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"json RANGE array was not an array" }];
				NSLog(@"ERR: %@",nsErr);
				nsErr = nil;
				jsonRangeArray = nil;
			}
			
			//NSLog(@"ParseBlock()");
			//NSLog(@"\t\ttypeString is %@",typeString);
			//NSLog(@"\t\tjsonValArray is %@",jsonValArray);
			//NSLog(@"\t\tjsonRangeArray is %@",jsonRangeArray);
			
			//	bail immediately if there's no type string, because w/o this we can't parse anything
			if (typeString == nil)
				return;
			int					typeCharIndex = 0;
			int					arrayIndex = 0;
			id					jsonObj = nil;
			NSDictionary		*jsonRangeDict = nil;
			id					tmpObj = nil;
			OSCValue			*tmpOSCVal = nil;
			//	we want to run through the type tag string, json val array, and json range array all at the same time, calling the block recursively when we encounter tuples
			for (typeCharIndex=0; typeCharIndex<[typeString length]; ++typeCharIndex)	{
				//	make sure that the val and range arrays are long enough to accommodate this entry in the type tag string
				if (jsonValArray!=nil && arrayIndex>=[jsonValArray count])	{
					nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"not enough entries in val array for type tage string" }];
					NSLog(@"ERR: %@",nsErr);
					nsErr = nil;
					jsonValArray = nil;
				}
				if (jsonRangeArray!=nil && arrayIndex>=[jsonRangeArray count])	{
					nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"not enough entries in range array for type tag string" }];
					NSLog(@"ERR: %@",nsErr);
					nsErr = nil;
					jsonRangeArray = nil;
				}
				
				//	get the object and range dict corresponding to the character at this index
				jsonObj = (jsonValArray==nil) ? nil : [jsonValArray objectAtIndex:arrayIndex];
				jsonRangeDict = (jsonRangeArray==nil) ? nil : [jsonRangeArray objectAtIndex:arrayIndex];
				
				//	we're going to try to populate these in the following switch statement, and they will be put together after it
				RemoteNodeControl	*newRemoteNodeControl = nil;
				OSCValue			*newOSCVal = nil;	//	'VALUE'
				OSCValue			*newOSCMin = nil;	//	'RANGE'-'MIN'
				OSCValue			*newOSCMax = nil;	//	'RANGE'-'MAX'
				NSMutableArray<OSCValue*>	*newOSCVals = nil;	//	'RANGE'-'VALS'
				
				//	get the character from the type tag string at this index
				unichar			tmpTypeChar = [typeString characterAtIndex:typeCharIndex];
				NSString		*tmpTypeString = [[NSString alloc] initWithCharacters:&tmpTypeChar length:1];
				
				switch (tmpTypeChar)	{
				case 'i':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSNumber class]])
						newOSCVal = [OSCValue createWithInt:[jsonObj intValue]];
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMin = [OSCValue createWithInt:[tmpObj intValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMax = [OSCValue createWithInt:[tmpObj intValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSNumber class]])	{
								tmpOSCVal = [OSCValue createWithInt:[tmpObj intValue]];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					break;
				case 'f':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSNumber class]])
						newOSCVal = [OSCValue createWithFloat:[jsonObj floatValue]];
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMin = [OSCValue createWithFloat:[tmpObj floatValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMax = [OSCValue createWithFloat:[tmpObj floatValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSNumber class]])	{
								tmpOSCVal = [OSCValue createWithFloat:[tmpObj floatValue]];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					break;
				case 's':
				case 'S':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSString class]])
						newOSCVal = [OSCValue createWithString:jsonObj];
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSString class]])
						newOSCMin = [OSCValue createWithString:tmpObj];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSString class]])
						newOSCMax = [OSCValue createWithString:tmpObj];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSString class]])	{
								tmpOSCVal = [OSCValue createWithString:tmpObj];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					
					break;
				case 'b':	//	blob
					//	not supported yet- maybe base64 data encoding?
					break;
				case 'h':	//	64 bit int
					//	not supported yet- maybe base64 data encoding?
					
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSNumber class]])
						newOSCVal = [OSCValue createWithLongLong:[jsonObj longLongValue]];
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMin = [OSCValue createWithDouble:[tmpObj longLongValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMax = [OSCValue createWithDouble:[tmpObj longLongValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSNumber class]])	{
								tmpOSCVal = [OSCValue createWithLongLong:[tmpObj longLongValue]];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					break;
				case 't':	//	time tag
					//	not supported yet- maybe base64 data encoding?
					break;
				case 'd':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSNumber class]])
						newOSCVal = [OSCValue createWithDouble:[jsonObj doubleValue]];
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMin = [OSCValue createWithDouble:[tmpObj doubleValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSNumber class]])
						newOSCMax = [OSCValue createWithDouble:[tmpObj doubleValue]];
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSNumber class]])	{
								tmpOSCVal = [OSCValue createWithDouble:[tmpObj doubleValue]];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					break;
				case 'c':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj != nil)	{
						if ([jsonObj isKindOfClass:[NSString class]])	{
							if ([jsonObj length]>0)
								newOSCVal = [OSCValue createWithChar:[jsonObj characterAtIndex:0]];
							else
								newOSCVal = [OSCValue createWithChar:' '];
						}
						else if ([jsonObj isKindOfClass:[NSNumber class]])	{
							unichar		tmpChar = [jsonObj intValue];
							newOSCVal = [OSCValue createWithChar:tmpChar];
						}
					}
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj != nil)	{
						if ([tmpObj isKindOfClass:[NSString class]])	{
							if ([tmpObj length]>0)
								newOSCMin = [OSCValue createWithChar:[tmpObj characterAtIndex:0]];
							else
								newOSCMin = [OSCValue createWithChar:' '];
						}
						else if ([tmpObj isKindOfClass:[NSNumber class]])	{
							unichar		tmpChar = [tmpObj intValue];
							newOSCMin = [OSCValue createWithChar:tmpChar];
						}
					}
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj != nil)	{
						if ([tmpObj isKindOfClass:[NSString class]])	{
							if ([tmpObj length]>0)
								newOSCMax = [OSCValue createWithChar:[tmpObj characterAtIndex:0]];
							else
								newOSCMax = [OSCValue createWithChar:' '];
						}
						else if ([tmpObj isKindOfClass:[NSNumber class]])	{
							unichar		tmpChar = [tmpObj intValue];
							newOSCMax = [OSCValue createWithChar:tmpChar];
						}
					}
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSString class]])	{
								if ([tmpObj length]>0)
									tmpOSCVal = [OSCValue createWithChar:[tmpObj characterAtIndex:0]];
								else
									tmpOSCVal = [OSCValue createWithChar:' '];
								[newOSCVals addObject:tmpOSCVal];
							}
							else if ([tmpObj isKindOfClass:[NSNumber class]])	{
								unichar		tmpChar = [tmpObj intValue];
								tmpOSCVal = [OSCValue createWithChar:tmpChar];
								[newOSCVals addObject:tmpOSCVal];
							}
						}
					}
					
					break;
				case 'r':
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					if (jsonObj!=nil && [jsonObj isKindOfClass:[NSArray class]] && [(NSArray*)jsonObj count]>=3)	{
						NSColor		*tmpColor = [jsonObj rgbaColorFromContents];
						if (tmpColor == nil)	{
							nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"malformed entry, couldn't make color value from array of values" }];
							NSLog(@"ERR: %@",nsErr);
							nsErr = nil;
						}
						else
							newOSCVal = [OSCValue createWithColor:tmpColor];
					}
					
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Min];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						NSColor		*tmpColor = [tmpObj rgbaColorFromContents];
						if (tmpColor == nil)	{
							nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"malformed entry, couldn't make color min from array of values" }];
							NSLog(@"ERR: %@",nsErr);
							nsErr = nil;
						}
						else
							newOSCMin = [OSCValue createWithColor:tmpColor];
					}
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Max];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						NSColor		*tmpColor = [tmpObj rgbaColorFromContents];
						if (tmpColor == nil)	{
							nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"malformed entry, couldn't make color max from array of values" }];
							NSLog(@"ERR: %@",nsErr);
							nsErr = nil;
						}
						else
							newOSCMax = [OSCValue createWithColor:tmpColor];
					}
					tmpObj = jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals];
					if (tmpObj!=nil && [tmpObj isKindOfClass:[NSArray class]])	{
						newOSCVals = [[NSMutableArray alloc] init];
						for (tmpObj in jsonRangeDict[kVVOSCQ_OptAttr_Range_Vals])	{
							if ([tmpObj isKindOfClass:[NSArray class]])	{
								NSColor		*tmpColor = [tmpObj rgbaColorFromContents];
								if (tmpColor == nil)	{
									nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"malformed entry, couldn't make color VALS entry from array of values" }];
									NSLog(@"ERR: %@",nsErr);
									nsErr = nil;
								}
								else	{
									tmpOSCVal = [OSCValue createWithColor:tmpColor];
									[newOSCVals addObject:tmpOSCVal];
								}
							}
						}
					}
					
					break;
				case 'm':	//	midi
					//	not supported yet, no idea
					break;
				case 'T':	//	true
				case 'F':	//	false
				case 'N':	//	nil
				case 'I':	//	infinity
					newRemoteNodeControl = [[RemoteNodeControl alloc] initWithParent:self typeString:tmpTypeString];
					break;
				case '[':
					{
						//	'[' starts a group, so find the index in 'typeString' of the corresponding ']', create a new "type substring".  throw an error if there's no close brace.
						NSRange		closeBraceRange = [typeString rangeOfString:@"]" options:0 range:NSMakeRange(typeCharIndex,[typeString length]-typeCharIndex)];
						if (closeBraceRange.location==NSNotFound)	{
							nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"Malformed type tag string, missing close brace" }];
							NSLog(@"ERR: %@",nsErr);
							return;
						}
						NSRange			typeSubstringRange;
						typeSubstringRange.location = typeCharIndex + 1;
						typeSubstringRange.length = closeBraceRange.location - typeSubstringRange.location;
						NSString		*typeSubstring = [typeString substringWithRange:typeSubstringRange];
						//	get the objects at jsonValArray[arrayIndex] and jsonRangeArray[arrayIndex], they should both be arrays- throw an error if they are not
						NSArray			*tmpValArray = nil;
						NSArray			*tmpRangeArray = nil;
						if (jsonValArray != nil)	{
							tmpValArray = jsonValArray[arrayIndex];
							if (tmpValArray==nil)	{
								nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"Missing val array" }];
								NSLog(@"ERR: %@",nsErr);
								nsErr = nil;
								jsonValArray = nil;
							}
							else if (![tmpValArray isKindOfClass:[NSArray class]])	{
								nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"Malformed val array" }];
								NSLog(@"ERR: %@",nsErr);
								nsErr = nil;
								jsonValArray = nil;
							}
						}
						if (jsonRangeArray != nil)	{
							tmpRangeArray = jsonRangeArray[arrayIndex];
							if (tmpRangeArray==nil)	{
								nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"Missing range array" }];
								NSLog(@"ERR: %@",nsErr);
								nsErr = nil;
								jsonRangeArray = nil;
							}
							else if (![tmpRangeArray isKindOfClass:[NSArray class]])	{
								nsErr = [NSError errorWithDomain:[self className] code:__LINE__ userInfo:@{  NSLocalizedDescriptionKey: @"Malformed range array" }];
								NSLog(@"ERR: %@",nsErr);
								nsErr = nil;
								jsonRangeArray = nil;
							}
						}
						//	call this block recursively with the type substring, and the arrays we just pulled out
						parseBlock(typeSubstring, tmpValArray, tmpRangeArray);
						//	if nsErr is non-nil, there was a problem and i need to return immediately
						if (nsErr != nil)	{
							NSLog(@"ERR: %@",nsErr);
							return;
						}
						//	this was started by a '[', so set 'typeCharIndex' to the index of the corresponding ']', as if we just finished processing it this pass
						typeCharIndex = (int)closeBraceRange.location;
						//	...when 'typeCharIndex' increments, it will be on the next value in the type tag string, and the array index will automatically increment as well
					}
					break;
				}
				
				//	if we made a new remote node value, finish populating it with whatever values we've extracted so far, then add it to our array
				if (newRemoteNodeControl != nil)	{
					//NSLog(@"\t\tmade a newRemoteNodeControl, %@",newRemoteNodeControl);
					//NSLog(@"\t\tdefault val is %@",newOSCVal);
					if (newOSCVal != nil)
						[newRemoteNodeControl setValue:newOSCVal];
					if (newOSCMin != nil)
						[newRemoteNodeControl setMin:newOSCMin];
					if (newOSCMax != nil)
						[newRemoteNodeControl setMax:newOSCMax];
					if (newOSCVals != nil)
						[newRemoteNodeControl setVals:newOSCVals];
					if (self->controls == nil)
						self->controls = [[NSMutableArray alloc] init];
					[self->controls addObject:newRemoteNodeControl];
				}
				
				//	increment arrayIndex!
				++arrayIndex;
			}
		};
		//	execute the block, which will run recursively, populating 'controls'
		parseBlock(dict[kVVOSCQ_ReqAttr_Type], dict[kVVOSCQ_OptAttr_Value], dict[kVVOSCQ_OptAttr_Range]);
		
		
		
		
		
		
		
		
		/*
		NSString	*tmpString = [dict objectForKey:kVVOSCQ_OptAttr_Type];
		int			index = 0;
		for (int i=0; i<[tmpString length]; ++i)	{
			NSString			*typeString = [NSString stringWithFormat:@"%c",[tmpString characterAtIndex:i]];
			if (![typeString isEqualToString:@","])	{
				RemoteNodeControl		*tmpValue = [[RemoteNodeControl alloc] initWithParent:self typeString:typeString index:index];
				if (controls == nil)
					controls = [[NSMutableArray alloc] init];
				[controls addObject:tmpValue];
			}
			++index;
		}
		*/
		
		NSDictionary	*contentsDict = [dict objectForKey:kVVOSCQ_ReqAttr_Contents];
		[contentsDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *val, BOOL *stop)	{
			if ([val isKindOfClass:[NSDictionary class]])	{
				RemoteNode		*newNode = [[RemoteNode alloc] initWithParent:self dict:val];
				if (self->contents == nil)
					self->contents = [[NSMutableArray alloc] init];
				[self->contents addObject:newNode];
			}
		}];
		[contents sortUsingComparator:(NSComparator)^(id obj1, id obj2)	{
			NSString		*str1 = nil;
			NSString		*str2 = nil;
			if ([obj1 isKindOfClass:[RemoteNode class]])
				str1 = [obj1 name];
			else
				str1 = [NSString stringWithFormat:@"%@-%d",[[obj1 parentNode] name],[(RemoteNodeControl*)obj1 index]];
			if ([obj2 isKindOfClass:[RemoteNode class]])
				str2 = [obj2 name];
			else
				str2 = [NSString stringWithFormat:@"%@-%d",[[obj2 parentNode] name],[(RemoteNodeControl*)obj2 index]];
			return [str1 caseInsensitiveCompare:str2];
		}];
	}
	return self;
}
- (void) dealloc	{
	parentNode = nil;
	dict = nil;
	controls = nil;
	contents = nil;
}
- (NSString *) description	{
	return [NSString stringWithFormat:@"<RemoteNode %@>",[self name]];
}


- (NSString *) typeString	{
	return [dict objectForKey:kVVOSCQ_ReqAttr_Type];
}
- (int) controlCount	{
	return (controls==nil) ? 0 : (int)[controls count];
}
- (int) contentsCount	{
	return (contents==nil) ? 0 : (int)[contents count];
}
- (NSString *) name	{
	return [[self fullPath] lastPathComponent];
}
- (NSString *) fullPath	{
	return [dict objectForKey:kVVOSCQ_ReqAttr_Path];
}
- (NSString *) oscDescription	{
	return [dict objectForKey:kVVOSCQ_ReqAttr_Desc];
}


- (void) sendMessage	{
	//NSLog(@"%s ... %@",__func__,self);
	//	create an OSCMessage that targets this node
	NSString		*tmpAddress = [dict objectForKey:kVVOSCQ_ReqAttr_Path];
	if (tmpAddress == nil)
		return;
	//	bail immediately if there's no type string, because w/o this we can't parse anything
	NSString				*typeString = [self typeString];
	if (typeString == nil)
		return;
	//	we're going to populate this message, and then send it somewhere
	OSCMessage		*newMsg = [[OSCMessage alloc] initWithAddress:tmpAddress];
	
	int				typeCharIndex = 0;
	int				arrayIndex = 0;
	OSCValue		*tupleInProgress = nil;
	NSMutableArray<OSCValue*>		*cachedTuples = [[NSMutableArray alloc] init];
	//	run through the type tag string
	for (typeCharIndex=0; typeCharIndex<[typeString length]; ++typeCharIndex)	{
		//	make sure arrayIndex is within the bounds of the controls array
		//if (arrayIndex >= [controls count])
		//	break;
		
		unichar			tmpTypeChar = [typeString characterAtIndex:typeCharIndex];
		//NSLog(@"\t\tprocessing type char %c",tmpTypeChar);
		NSString		*tmpTypeString = [[NSString alloc] initWithCharacters:&tmpTypeChar length:1];
		OSCValue		*oscValForThisChar = nil;
		switch (tmpTypeChar)	{
		case 'i':
		case 'f':
		case 's':
		case 'S':
		case 'd':
		case 'c':
		case 'r':
		case 'T':	//	true
		case 'F':	//	false
		case 'N':	//	nil
		case 'I':	//	infinity
		case 'h':	//	64 bit int
			//	ask the corresponding control to create a current OSC value- if it can't, bail because somethign went wrong
			oscValForThisChar = (arrayIndex>=[controls count]) ? nil : [[controls objectAtIndex:arrayIndex] createCurrentOSCValue];
			if (oscValForThisChar == nil)	{
				NSLog(@"\t\terr: couldn't make value for control in %s, bailing",__func__);
				newMsg = nil;
				return;
			}
			//	make sure that the type tag string of the current OSC value matches the type tag string we were looking for
			if ([[oscValForThisChar typeTagString] isEqualToString:tmpTypeString])	{
				//	if the type tag string matches then we're good to go- we can add this value to either the message or the tuple in progress and increment the array index
				if (tupleInProgress != nil)
					[tupleInProgress addValue:oscValForThisChar];
				else
					[newMsg addValue:oscValForThisChar];
				++arrayIndex;
			}
			//	T and F get mixed up easily in this app because they're kinda messed up- they're types with no accompanying value, which doesn't fit well with the class/object models
			else if (([[oscValForThisChar typeTagString] isEqualToString:@"T"] || [[oscValForThisChar typeTagString] isEqualToString:@"F"])	&&
			([tmpTypeString isEqualToString:@"T"] || [tmpTypeString isEqualToString:@"F"]))	{
				if ([tmpTypeString isEqualToString:@"T"])
					[newMsg addValue:[OSCValue createWithBool:YES]];
				else
					[newMsg addValue:[OSCValue createWithBool:NO]];
			}
			//	else there was a type tag string mismatch- log the error and bail
			else	{
				NSLog(@"\t\terr: type mismatch, expected \"%@\" and got \"%@\" in %s",tmpTypeString, [OSCValue typeTagStringForType:[oscValForThisChar type]], __func__);
				NSLog(@"\t\toscValForThisChar was %@",oscValForThisChar);
				oscValForThisChar = nil;
				newMsg = nil;
				return;
			}
			break;
		case '[':
			//NSLog(@"\t\tstarting a tuple, msg is %@",newMsg);
			//	we're starting a tuple- if there's a tuple in progress add it to the end of the cache and then make a new one
			if (tupleInProgress != nil)
				[cachedTuples addObject:tupleInProgress];
			tupleInProgress = [[OSCValue alloc] initArray];
			break;
		case ']':
			//NSLog(@"\t\tfinished a tuple, which was %@",tupleInProgress);
			//	we're finishing a tuple- if there's a tuple in progress it's complete, add it to the message
			if (tupleInProgress != nil)
				[newMsg addValue:tupleInProgress];
			tupleInProgress = nil;
			//	if there are cached tuples, move the last tuple out of the cache (it's "in progress" again)
			if ([cachedTuples count]>0)	{
				tupleInProgress = [cachedTuples lastObject];
				[cachedTuples removeLastObject];
			}
			//NSLog(@"\t\tmsg is now %@",newMsg);
			break;
		
		//	the following OSC types are not supported for display in this application yet...
		
		case 'b':	//	blob
			//	not supported yet- maybe base64 data encoding?
			break;
		case 't':	//	time tag
			//	not supported yet- maybe base64 data encoding?
			break;
		case 'm':	//	midi
			//	not supported yet, no idea
			break;
		//case 'T':	//	true
		//case 'F':	//	false
			//	not supported yet
			break;
		//case 'N':	//	nil
			//	not supported yet
			break;
		//case 'I':	//	infinity
			//	not supported yet
			break;
		}
		
	}
	
	//	bail if there isn't a message...
	if (newMsg == nil)	{
		NSLog(@"\t\terr: no msg in %s",__func__);
		return;
	}
	
	//	now dispatch the message we assembled
	//NSLog(@"\t\tjust need to dispatch %@ to the appropriate out port here %s",newMsg,__func__);
	[[ServerUIController global] sendMessageToRemoteServer:newMsg];
}


- (NSString *) outlineViewIdentifier	{
	return [self fullPath];
}
- (NSUInteger) indexOfControl:(RemoteNodeControl*)n	{
	if (n==nil)
		return NSNotFound;
	return [controls indexOfObjectIdenticalTo:n];
}


@synthesize parentNode;
@synthesize dict;
@synthesize controls;
@synthesize contents;


@end
