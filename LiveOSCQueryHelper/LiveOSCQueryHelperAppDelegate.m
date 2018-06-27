#import "LiveOSCQueryHelperAppDelegate.h"
#import "QueryServerNodeDelegate.h"
#import "OSCNodeAdditions.h"
#import "LiveToOSCQHelper.h"




@interface LiveOSCQueryHelperAppDelegate ()	{
	NSTimer		*fileChangeCoalesceTimer;
}
@property (weak) IBOutlet NSWindow *window;
@property (strong) id activity;
- (void) _loadLastFile;
- (void) _loadFile:(NSString *)fullPath;
- (void) _loadAbletonProjectFile:(NSString *)fullPath;
- (void) _updateUIItems;
@end




//	this class addition returns an attributed string that renders the receiver- which is presumed to contain valid HTML code- in NSTextFields.  this is what makes the link "clickable".
@implementation NSString (NSStringAdditions)
- (NSAttributedString *) renderedHTMLWithFont:(NSFont *)font	{
	if (!font) font = [NSFont systemFontOfSize:0.0];  // Default font
	NSString *html = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%dpx;\">%@</span>", [font fontName], (int)[font pointSize], self];
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
	return string;
}
@end




@implementation LiveOSCQueryHelperAppDelegate


+ (void) initialize	{
	//	make sure the kqueue stuff is up and running
	[VVKQueueCenter class];
}
- (id) init	{
	self = [super init];
	if (self != nil)	{
		//	disable app nap
		self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"Live OSCQuery Helper"];
		
		//	register the OSC address space
		OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
		//	by default, the address space registers for app terminate notifications so it can tear itself down.  we want to prevent this so we don't send "node deleted" messages to clients on app quit.
		[[NSNotificationCenter defaultCenter] removeObserver:as name:NSApplicationWillTerminateNotification object:nil];
		
		delegates = [[NSMutableArray alloc] init];
		loadedFilePath = nil;
		fileChangeCoalesceTimer = nil;
		
		//	make an VVOSCQueryServer- we'll start it later, when the app finishes launching
		server = [[VVOSCQueryServer alloc] init];
		[server setName:@"Live OSCQuery Helper"];
		[server setBonjourName:@"Live OSCQuery Helper"];
		[server setDelegate:self];
		
		//	this notification is posted by our OSC manager subclass when the host info changes as a result of user interaction
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(targetAppHostInfoChangedNotification:)
			name:TargetAppHostInfoChangedNotification
			object:nil];
	}
	return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//	load the last file- this will populate the OSC address space with the contents of the file...
	[self _loadLastFile];
	
	//	start the VVOSCQueryServer!
	[server start];
	
	//	update my UI
	[self _updateUIItems];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	//	stop the VVOSCQueryServer!
	[server stop];
	//	clear the delegates
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	for (QueryServerNodeDelegate *tmpDelegate in delegates)	{
		[as removeDelegate:tmpDelegate forPath:[tmpDelegate address]];
	}
	[delegates removeAllObjects];
}
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)inPath	{
	//NSLog(@"%s ... %@",__func__,inPath);
	NSFileManager		*fm = [NSFileManager defaultManager];
	BOOL				isDirectory = NO;
	NSError				*nsErr = nil;
	if ([fm fileExistsAtPath:inPath isDirectory:&isDirectory])	{
		if (!isDirectory)	{
			[self _loadFile:inPath];
			return YES;
		}
		else	{
			NSArray			*filenames = [fm contentsOfDirectoryAtPath:inPath error:&nsErr];
			for (NSString *filename in filenames)	{
				if ([[filename pathExtension] caseInsensitiveCompare:@"als"]==NSOrderedSame)	{
					NSString		*fullPath = [NSString stringWithFormat:@"%@/%@",inPath,filename];
					[self _loadFile:fullPath];
					return YES;
				}
			}
		}
	}
	
	return NO;
}


#pragma mark -------------------------- UI


- (IBAction) openDocument:(id)sender	{
	//NSLog(@"%s",__func__);
	NSUserDefaults	*def = [NSUserDefaults standardUserDefaults];
	NSString		*importDir = [def objectForKey:@"lastOpenDocumentFolder"];
	if (importDir == nil)
		importDir = [@"~/Desktop" stringByExpandingTildeInPath];
	NSString		*importFile = [def objectForKey:@"lastOpenDocumentFile"];
	//NSOpenPanel		*op = [[NSOpenPanel openPanel] retain];
	NSOpenPanel		*op = [NSOpenPanel openPanel];
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseDirectories:NO];
	[op setResolvesAliases:YES];
	[op setMessage:@"Select Ableton Live project file to open"];
	[op setTitle:@"Open file"];
	[op setAllowedFileTypes:@[ @"als" ]];
	//[op setDirectoryURL:[NSURL fileURLWithPath:importDir]];
	if (importFile != nil)
		[op setDirectoryURL:[NSURL fileURLWithPath:importFile]];
	else
		[op setDirectoryURL:[NSURL fileURLWithPath:importDir]];
	
	[op
		beginSheetModalForWindow:[self window]
		completionHandler:^(NSInteger result)	{
			if (result == NSFileHandlingPanelOKButton)	{
				//	get the inspected object
				NSArray			*fileURLs = [op URLs];
				NSURL			*urlPtr = (fileURLs==nil) ? nil : [fileURLs objectAtIndex:0];
				NSString		*urlPath = (urlPtr==nil) ? nil : [urlPtr path];
				if (urlPath != nil)	{
					[self _loadFile:urlPath];
				}
				//	update the defaults so i know where the law directory i browsed was
				NSString		*directoryString = (urlPath==nil) ? nil : [urlPath stringByDeletingLastPathComponent];
				if (directoryString != nil)
					[[NSUserDefaults standardUserDefaults] setObject:directoryString forKey:@"lastOpenDocumentFolder"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}];
}

- (IBAction) showHelp:(id)sender	{
	//NSLog(@"%s",__func__);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self showHelp:sender];
		});
		return;
	}
	
	[[self window] beginSheet:helpWindow completionHandler:^(NSModalResponse returnCode)	{
	}];
}
- (IBAction) closeHelp:(id)sender	{
	//NSLog(@"%s",__func__);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self closeHelp:sender];
		});
		return;
	}
	
	[[self window] endSheet:helpWindow returnCode:NSModalResponseStop];
}


#pragma mark -------------------------- backend


- (void) _loadLastFile	{
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSString			*tmpString = [def objectForKey:@"lastOpenDocumentFile"];
	if (tmpString == nil)
		return;
	[self _loadFile:tmpString];
}
- (void) _loadFile:(NSString *)fullPath	{
	//NSLog(@"%s ... %@",__func__,fullPath);
	NSString		*ext = (fullPath==nil) ? nil : [fullPath pathExtension];
	if ([ext caseInsensitiveCompare:@"als"]==NSOrderedSame)	{
		[self _loadAbletonProjectFile:fullPath];
	}
}
- (void) _loadAbletonProjectFile:(NSString *)fullPath	{
	//NSLog(@"%s ... %@",__func__,fullPath);
	if (fullPath == nil)
		return;
	//	unserialize the file at the path into a series of JSON objects
	//NSError			*nsErr = nil;
	NSDictionary	*rawFileObj = [LiveToOSCQHelper OSCQueryJSONObjectForLiveProject:fullPath];
	if (rawFileObj==nil || ![rawFileObj isKindOfClass:[NSDictionary class]])	{
		NSLog(@"\t\terr: raw object is nil or of wrong type for path %@",fullPath);
		return;
	}
	NSMutableDictionary		*fileObject = (rawFileObj==nil) ? nil : [rawFileObj mutableCopy];
	//NSLog(@"\t\tfileObject is %@",fileObject);
	
	//	if this is a different file, stop the server
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	BOOL				reloadingTheFile = YES;
	BOOL				wasRunning = [server isRunning];
	if (loadedFilePath==nil || (loadedFilePath!=nil && ![loadedFilePath isEqualToString:fullPath]))
		reloadingTheFile = NO;
	if (!reloadingTheFile && wasRunning)
		[server stop];
	
	//	rename the server!
	NSString			*fileName = [[fullPath lastPathComponent] stringByDeletingPathExtension];
	[server setName:fileName];
	NSString			*bjName = [NSString stringWithFormat:@"%@ OSCQuery Helper",fileName];
	int					nameLength = (int)[bjName length];
	if (nameLength > 63)	{
		bjName = [NSString stringWithFormat:@"%@...%@",[bjName substringWithRange:NSMakeRange(0,30)],[bjName substringWithRange:NSMakeRange(nameLength-30,30)]];
	}
	[server setBonjourName:bjName];
	
	//	if i'm not reloading a file then i may want to stop observing the file
	if (!reloadingTheFile)	{
		//	if i've already got a file loaded i need to stop observing it
		if (loadedFilePath!=nil)	{
			[VVKQueueCenter removeObserver:self forPath:loadedFilePath];
		}
	}
	//	update my local var storing the file path
	loadedFilePath = fullPath;
	//	if i'm not reloading the file, add myself as an observer so i'll know if the file changes
	if (!reloadingTheFile)	{
		[VVKQueueCenter addObserver:self forPath:loadedFilePath];
	}
	//	make sure that the file object doesn't have a host info dict
	[fileObject removeObjectForKey:kVVOSCQ_ReqAttr_HostInfo];
	//	update my user defaults so i know what file i last loaded
	[def setObject:fullPath forKey:@"lastOpenDocumentFile"];
	[def synchronize];
	
	
	//	...now i need to run through the objects from the file, and create OSCNodes from them in an address space
	
	
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	//	destroy all the delegates immediately- we don't want them sending any messages while we're clearing the address space
	for (QueryServerNodeDelegate *tmpDelegate in delegates)	{
		[as removeDelegate:tmpDelegate forPath:[tmpDelegate address]];
	}
	[delegates removeAllObjects];
	
	//	clear out the OSC address space
	NSArray		*baseNodes = [[as nodeContents] lockCreateArrayCopy];
	for (OSCNode *baseNode in baseNodes)	{
		[baseNode removeFromAddressSpace];
	}
	
	//	now run through 'fileObject' recursively using this block, creating OSC nodes for all the objects
	__block __weak void		(^ParseJSONObj)(NSDictionary *);
	ParseJSONObj = ^(NSDictionary * baseObj)	{
		NSString		*objFullPath = [baseObj objectForKey:kVVOSCQ_ReqAttr_Path];
		//NSLog(@"ParseJSONObj() called on %@",objFullPath);
		if (objFullPath == nil)	{
			NSLog(@"\t\terr: bailing, node missing full path, %s",__func__);
			return;
		}
					
		//	parse the base object, looking for entries that describe the type of MIDI message to send
		NSString		*tmpString = [baseObj objectForKey:@"MIDI_TYPE"];
		VVMIDIMsgType	objMIDIMsgType = VVMIDIMsgUnknown;
		if (tmpString != nil)	{
			if ([tmpString caseInsensitiveCompare:@"NOTE"] == NSOrderedSame)	{
				objMIDIMsgType = VVMIDINoteOnVal;
			}
			else if ([tmpString caseInsensitiveCompare:@"AFTERTOUCH"] == NSOrderedSame)	{
				objMIDIMsgType = VVMIDIAfterTouchVal;
			}
			else if ([tmpString caseInsensitiveCompare:@"CC"] == NSOrderedSame)	{
				objMIDIMsgType = VVMIDIControlChangeVal;
			}
			else if ([tmpString caseInsensitiveCompare:@"PGM"] == NSOrderedSame)	{
				objMIDIMsgType = VVMIDIProgramChangeVal;
			}
			else if ([tmpString caseInsensitiveCompare:@"PITCH"] == NSOrderedSame)	{
				objMIDIMsgType = VVMIDIPitchWheelVal;
			}
		}
		
		BOOL			setUpAsMIDINode = YES;
		//	if the message type is unrecognized or there's no channel, bail
		NSNumber		*objMIDIChannelNum = [baseObj objectForKey:@"MIDI_CHANNEL"];
		if (objMIDIMsgType==VVMIDIMsgUnknown || objMIDIChannelNum==nil)	{
			setUpAsMIDINode = NO;
			//NSLog(@"\t\terr: bailing, node missing msg type or channel num, %s",__func__);
			//return;
		}
		//	if there's no midi voice and i'm not pitch bend, bail (everything but pitch bend has a voice, pitch bend is 14-bit)
		NSNumber		*objMIDIVoiceNum = [baseObj objectForKey:@"MIDI_VOICE"];
		if (objMIDIVoiceNum==nil && (objMIDIMsgType!=VVMIDIPitchWheelVal && objMIDIMsgType!=VVMIDIProgramChangeVal))	{
			setUpAsMIDINode = NO;
			//NSLog(@"\t\terr: bailing, node missing voice num, %s",__func__);
			//return;
		}
		
		//	parse the base object, looking for entries that describe the kind of OSC node to publish
		NSString		*objTypeTagString = [baseObj objectForKey:kVVOSCQ_ReqAttr_Type];
		NSDictionary	*objContents = [baseObj objectForKey:kVVOSCQ_ReqAttr_Contents];
		NSString		*objDesc = [baseObj objectForKey:kVVOSCQ_ReqAttr_Desc];
		NSArray			*objTags = [baseObj objectForKey:kVVOSCQ_OptAttr_Tags];
		NSArray			*objExtType = [baseObj objectForKey:kVVOSCQ_OptAttr_Ext_Type];	//	one for each type from the type tag string
		//NSNumber		*objAccess = [baseObj objectForKey:kVVOSCQ_OptAttr_Access];
		NSArray			*objRange = [baseObj objectForKey:kVVOSCQ_OptAttr_Range];	//	one for each type from the type tag string
		NSArray			*objUnits = [baseObj objectForKey:kVVOSCQ_OptAttr_Unit];	//	one for each type from the type tag string
		NSNumber		*objCritical = [baseObj objectForKey:kVVOSCQ_OptAttr_Critical];
		NSArray			*objOverloads = [baseObj objectForKey:kVVOSCQ_OptAttr_Overloads];
		
		if (setUpAsMIDINode)	{
			OSCNode			*newNode = [[OSCAddressSpace mainAddressSpace] findNodeForAddress:objFullPath createIfMissing:YES];
			if (objTypeTagString != nil)	{
				[newNode setTypeTagString:objTypeTagString];
				[newNode setNodeType:OSCNodeTypeNumber];
			}
			else
				[newNode setNodeType:OSCNodeDirectory];
			if (objDesc != nil && [objDesc isKindOfClass:[NSString class]])
				[newNode setOSCDescription:objDesc];
			if (objTags != nil && [objTags isKindOfClass:[NSArray class]])
				[newNode setTags:objTags];
			if (objExtType != nil && [objExtType isKindOfClass:[NSArray class]])
				[newNode setExtendedType:objExtType];
			//if (objAccess != nil && [objAccess isKindOfClass:[NSNumber class]])	{
				//[newNode setAccess:[objAccess intValue]];	//	don't do this, access is always write-only in this application (we can't read the remote app's OSC address space)
				[newNode setAccess:2];
			//}
			if (objRange != nil && [objRange isKindOfClass:[NSArray class]])
				[newNode setRange:objRange];
			if (objUnits != nil && [objUnits isKindOfClass:[NSArray class]])
				[newNode setUnits:objUnits];
			if (objCritical != nil && [objCritical isKindOfClass:[NSNumber class]])
				[newNode setCritical:[objCritical boolValue]];
			if (objOverloads != nil && [objOverloads isKindOfClass:[NSArray class]])
				[newNode setOverloads:objOverloads];
		
			//	make a delegate for the node, add it to the array
			QueryServerNodeDelegate		*tmpDelegate = [[QueryServerNodeDelegate alloc] initWithMIDIManager:midim forAddress:[newNode fullName]];
			[tmpDelegate setMIDIMsgType:objMIDIMsgType];
			[tmpDelegate setMIDIChannel:[objMIDIChannelNum intValue]];
			[tmpDelegate setMIDIVoice:[objMIDIVoiceNum intValue]];
			if (objRange != nil)	{
				NSDictionary		*tmpRange = [objRange objectAtIndex:0];
				NSNumber			*tmpMin = [tmpRange objectForKey:kVVOSCQ_OptAttr_Range_Min];
				if (tmpMin != nil)	{
					[tmpDelegate setHasMin:YES];
					[tmpDelegate setMinVal:[tmpMin doubleValue]];
				}
				NSNumber			*tmpMax = [tmpRange objectForKey:kVVOSCQ_OptAttr_Range_Max];
				if (tmpMax != nil)	{
					[tmpDelegate setHasMax:YES];
					[tmpDelegate setMaxVal:[tmpMax doubleValue]];
				}
			}
			[newNode addDelegate:tmpDelegate];
			[delegates addObject:tmpDelegate];
		}
		
		//	run through the contents, calling this block recursively on each object
		[objContents enumerateKeysAndObjectsUsingBlock:^(NSString * tmpName, NSDictionary * tmpContentsObj, BOOL *stop)	{
			if ([tmpContentsObj isKindOfClass:[NSDictionary class]])	{
				ParseJSONObj(tmpContentsObj);
			}
		}];
	};
	ParseJSONObj(fileObject);
	
	//	restart the server if appropriate
	if (!reloadingTheFile && wasRunning)
		[server start];
	
	//	tell the OSC query server to send a PATH_CHANGED message for the root node
	if (reloadingTheFile)
		[server sendPathChangedToClients:@"/"];
	
	[self _updateUIItems];
}
- (void) _updateUIItems	{
	//	make sure this method is called on the main thread
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self _updateUIItems];
		});
		return;
	}
	
	if (loadedFilePath != nil)	{
		[fileStatusField setStringValue:[loadedFilePath lastPathComponent]];
	}
	else	{
		[fileStatusField setStringValue:@"No file selected!"];
	}
	
	//	update the server status field
	if ([server isRunning])	{
		NSString		*fullAddressString = [NSString stringWithFormat:@"http://localhost:%d",[server webServerPort]];
		NSString		*htmlString = [NSString stringWithFormat:@"<A HREF=\"%@\">%@</A>",fullAddressString,fullAddressString];
		NSAttributedString	*htmlAttrStr = [htmlString renderedHTMLWithFont:nil];
		[serverStatusField setAttributedStringValue:htmlAttrStr];
	}
	else	{
		[serverStatusField setStringValue:@"Not running!"];
	}
}
- (void) targetAppHostInfoChangedNotification:(NSNotification *)note	{
	//	make sure this method is called on the main thread
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self targetAppHostInfoChangedNotification:note];
		});
		return;
	}
	
	//	if the target app's host info changed then we need to stop and then start the server again
	[server stop];
	//	wait a bit before restarting it...
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[server start];
		//	wait a bit more before updating the UI...
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self _updateUIItems];
		});
	});
}


#pragma mark -------------------------- VVKQueueCenterDelegate


- (void) file:(NSString *)p changed:(u_int)fflag	{
	//NSLog(@"%s ... %@",__func__,p);
	@synchronized (self)	{
		if (loadedFilePath!=nil && p!=nil && [loadedFilePath isEqualToString:p])	{
			//	reset the coalesce timer- the upshot is that there's a 0.5 sec delay between changes to a file and when the app reloads that file
			if (fileChangeCoalesceTimer != nil)	{
				[fileChangeCoalesceTimer invalidate];
				fileChangeCoalesceTimer = nil;
			}
			fileChangeCoalesceTimer = [NSTimer
				scheduledTimerWithTimeInterval:1./2.
				target:self
				selector:@selector(fileChangeCoalesceTimerCallback:)
				userInfo:nil
				repeats:NO];
		}
	}
}
- (void) fileChangeCoalesceTimerCallback:(NSTimer *)t	{
	//NSLog(@"%s",__func__);
	[self _loadFile:loadedFilePath];
}


#pragma mark -------------------------- VVOSCQueryServerDelegate


- (VVOSCQueryReply *) hostInfoQueryFromServer:(VVOSCQueryServer *)s	{
	NSMutableDictionary		*hostInfo = [[NSMutableDictionary alloc] init];
	
	//	supply a server name if there isn't already one
	NSString			*myName = [s name];
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_Name]==nil && myName!=nil)
		[hostInfo setObject:myName forKey:kVVOSCQ_ReqAttr_HostInfo_Name];
	//	supply a transport mode if there isn't already one
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport] == nil)
		[hostInfo setObject:kVVOSCQueryOSCTransportUDP forKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport];
	//	supply an extensions array if there isn't already one
	NSDictionary		*extDict = @{
		kVVOSCQ_OptAttr_Tags : @YES,
		//kVVOSCQ_ReqAttr_Type : @YES,
		kVVOSCQ_OptAttr_Access : @YES,
		kVVOSCQ_OptAttr_Value : @YES,
		kVVOSCQ_OptAttr_Range : @YES,
		kVVOSCQ_OptAttr_Clipmode : @NO,
		kVVOSCQ_OptAttr_Unit : @NO,
		kVVOSCQ_OptAttr_Critical : @NO,
		kVVOSCQ_OptAttr_Overloads : @NO,
		kVVOSCQ_OptAttr_HTML : @YES,
		kVVOSCQ_WSAttr_Cmd_Listen : @NO,
		kVVOSCQ_WSAttr_Cmd_Ignore : @NO,
		kVVOSCQ_WSAttr_Cmd_PathChanged : @YES,
		kVVOSCQ_WSAttr_Cmd_PathRenamed : @NO,
		kVVOSCQ_WSAttr_Cmd_PathRemoved : @NO,
		kVVOSCQ_WSAttr_Cmd_PathAdded : @NO,
	};
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_Exts] == nil)
		[hostInfo setObject:extDict forKey:kVVOSCQ_ReqAttr_HostInfo_Exts];
	
	//	get the host info details from the osc manager
	NSDictionary		*connectionHostInfo = [oscm oscQueryHostInfo];
	if (connectionHostInfo != nil)
		[hostInfo addEntriesFromDictionary:connectionHostInfo];
	
	return [[VVOSCQueryReply alloc] initWithJSONObject:hostInfo];
}
//	this is the VVOSCQueryServerDelegate protocol method- requests received by the OSC query server are passed to this method
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s wantsReplyForQuery:(VVOSCQuery *)q	{
	//NSLog(@"%s ... %@",__func__,q);
	if (q==nil)
		return nil;
	
	NSString		*path = [q path];
	//	retrieve the OSCNode corresponding to the query's path.  this part is specific to my OSC library.
	OSCNode			*queriedNode = (path==nil) ? nil : [[OSCAddressSpace mainAddressSpace] findNodeForAddress:path createIfMissing:NO];
	//	generate a reply to the OSCQuery.  this is a class addition that is part of this test server project, and is specific to my OSC library.
	VVOSCQueryReply	*returnMe = (queriedNode==nil) ? nil : [queriedNode getReplyForOSCQuery:q];
	//	if something went wrong and i couldn't generate a valid reply, return a 404 error
	if (returnMe == nil)
		returnMe = [[VVOSCQueryReply alloc] initWithErrorCode:404];
	return returnMe;
}
- (void) server:(VVOSCQueryServer *)s websocketDeliveredJSONObject:(NSDictionary *)jsonObj	{
	//NSLog(@"%s ... %@",__func__,jsonObj);
}
- (void) server:(VVOSCQueryServer *)s receivedOSCPacket:(const void*)packet sized:(size_t)packetSize	{
	//NSLog(@"%s",__func__);
	//	parse the raw packet
	[OSCPacket
		parseRawBuffer:(unsigned char *)packet
		ofMaxLength:(int)packetSize
		toInPort:[oscm inPort]
		fromAddr:0
		port:0];
}
- (BOOL) server:(VVOSCQueryServer *)s wantsToListenTo:(NSString *)address	{
	//NSLog(@"%s ... %@, %@",__func__,s,address);
	//	intentionally blank- we can't stream values because we don't have direct access to the remote app's address space (or data model corresponding to an address space)
	return NO;
}
- (void) server:(VVOSCQueryServer *)s wantsToIgnore:(NSString *)address	{
	//NSLog(@"%s ... %@, %@",__func__,s,address);
	//	intentionally blank, listening is disabled
}


@end
