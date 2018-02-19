#import "OSCQueryHelperAppDelegate.h"
#import "OSCNodeAdditions.h"
#import "QueryServerNodeDelegate.h"




@interface OSCQueryHelperAppDelegate ()	{
	NSTimer		*fileChangeCoalesceTimer;
}
@property (weak) IBOutlet NSWindow *window;
- (void) _loadLastFile;
- (void) _loadFile:(NSString *)fullPath;
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




@implementation OSCQueryHelperAppDelegate

+ (void) initialize	{
	//	make sure the kqueue stuff is up and running
	[VVKQueueCenter class];
}
- (id) init	{
	self = [super init];
	if (self != nil)	{
		//	register the OSC address space
		OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
		//	by default, the address space register for app terminate notifications so it can tear itself down.  we want to prevent this so we don't send "node deleted" messages to clients on app quit.
		[[NSNotificationCenter defaultCenter] removeObserver:as name:NSApplicationWillTerminateNotification object:nil];
		
		//serverNodeDelegates = [[NSMutableArray alloc] init];
		
		delegates = [[NSMutableArray alloc] init];
		loadedFilePath = nil;
		fileHostInfoDict = nil;
		fileChangeCoalesceTimer = nil;
		
		//	make an VVOSCQueryServer- we'll start it later, when the app finishes launching
		server = [[VVOSCQueryServer alloc] init];
		[server setName:@"OSCQuery Helper"];
		[server setBonjourName:@"OSCQuery Helper"];
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
	//	check to see if there's a "SampleDocument.json" in ~/Documents/OSCQuery Helper
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSString			*tmpDirPath = [@"~/Documents/OSCQuery Helper" stringByExpandingTildeInPath];
	NSString			*tmpFilePath = [NSString stringWithFormat:@"%@/SampleDocument.json",tmpDirPath];
	//	if the dir doesn't exist, make it
	if (![fm fileExistsAtPath:tmpDirPath])	{
		NSError			*nsErr = nil;
		if (![fm createDirectoryAtPath:tmpDirPath withIntermediateDirectories:YES attributes:nil error:&nsErr])	{
			NSLog(@"\t\tERR: couldnt create dir in %s.  %@",__func__,nsErr);
		}
	}
	if (![fm fileExistsAtPath:tmpFilePath])	{
		NSString		*tmpSrcPath = [[NSBundle mainBundle] pathForResource:@"SampleDocument" ofType:@"json"];
		if (tmpSrcPath != nil)	{
			NSError			*nsErr = nil;
			if (![fm copyItemAtPath:tmpSrcPath toPath:tmpFilePath error:&nsErr])	{
				NSLog(@"\t\tERR: couldnt copy item in %s.  %@",__func__,nsErr);
			}
		}
	}
	
	//	populate the OSC address space with a series of OSC nodes!
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


#pragma mark -------------------------- UI


- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename	{
	[self _loadFile:filename];
	return YES;
}
- (IBAction) openDocument:(id)sender	{
	NSLog(@"%s",__func__);
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
	[op setMessage:@"Select JSON file to open (see Help for more)"];
	[op setTitle:@"Open file"];
	[op setAllowedFileTypes:@[ @"json", @"txt" ]];
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
				//if (urlPath != nil)
				//	[[NSUserDefaults standardUserDefaults] setObject:urlPath forKey:@"lastOpenDocumentFile"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}];
}

- (IBAction) showHelp:(id)sender	{
	NSLog(@"%s",__func__);
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
	NSLog(@"%s",__func__);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self closeHelp:sender];
		});
		return;
	}
	
	[[self window] endSheet:helpWindow returnCode:NSModalResponseStop];
}
- (IBAction) showSampleDocInFinderClicked:(id)sender	{
	NSString		*tmpPath = [@"~/Documents/OSCQuery Helper/SampleDocument.json" stringByExpandingTildeInPath];
	NSURL			*tmpURL = [NSURL fileURLWithPath:tmpPath];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[tmpURL]];
}


#pragma mark -------------------------- backend


- (void) _loadLastFile	{
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSString			*tmpString = [def objectForKey:@"lastOpenDocumentFile"];
	//	if there's no default, try to find the sample document we include and use that
	if (tmpString == nil)	{
		NSFileManager		*fm = [NSFileManager defaultManager];
		NSString			*samplePath = [@"~/Documents/OSCQuery Helper/SampleDocument.json" stringByExpandingTildeInPath];
		if ([[NSFileManager defaultManager] fileExistsAtPath:samplePath])
			tmpString = samplePath;
		else
			return;
	}
	[self _loadFile:tmpString];
}
- (void) _loadFile:(NSString *)fullPath	{
	//NSLog(@"%s ... %@",__func__,fullPath);
	NSString		*ext = (fullPath==nil) ? nil : [fullPath pathExtension];
	if ([ext caseInsensitiveCompare:@"json"]==NSOrderedSame || [ext caseInsensitiveCompare:@"txt"]==NSOrderedSame)	{
		[self _loadJSONFile:fullPath];
	}
}
- (void) _loadJSONFile:(NSString *)fullPath	{
	//NSLog(@"%s ... %@",__func__,fullPath);
	if (fullPath == nil)
		return;
	//	unserialize the file at the path into a series of JSON objects
	NSError			*nsErr = nil;
	NSData			*fileData = [NSData dataWithContentsOfFile:fullPath];
	NSDictionary	*rawFileObj = (fileData==nil) ? nil : [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&nsErr];
	if (rawFileObj==nil || ![rawFileObj isKindOfClass:[NSDictionary class]])	{
		NSLog(@"\t\terr: file object is nil or of wrong type for path %@",fullPath);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])	{
				VVRunAlertPanel(@"File cannot be loaded",
					@"The file you had loaded is missing!",
					@"OK!",
					nil,
					nil);
			}
			else	{
				VVRunAlertPanel(@"File cannot be loaded",
					@"This file can't be loaded, its contents may be malformed.  Please run it through a JSON linter.",
					@"OK!",
					nil,
					nil);
			}
			});
		return;
	}
	NSMutableDictionary		*fileObject = (rawFileObj==nil) ? nil : [rawFileObj mutableCopy];
	//NSLog(@"\t\tfileObject is %@",fileObject);
	
	//	if this is a different file, stop the server
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	//NSString			*lastFilePath = [def objectForKey:@"lastOpenDocumentFile"];
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
	int					nameLength = [bjName length];
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
	//	if i'm not reloading the file, add myself as an observer
	if (!reloadingTheFile)	{
		[VVKQueueCenter addObserver:self forPath:loadedFilePath];
	}
	//	update my local copy of the host info dict parsed from the file
	fileHostInfoDict = [fileObject objectForKey:kVVOSCQ_ReqAttr_HostInfo];
	[fileObject removeObjectForKey:kVVOSCQ_ReqAttr_HostInfo];
	//	update my user defaults so i know what file i last loaded
	[def setObject:fullPath forKey:@"lastOpenDocumentFile"];
	[def synchronize];
	//	if i pulled a host_info out of the dict, check it for an IP and port- if they exist, push them into the UI
	if (fileHostInfoDict != nil)	{
		NSString		*tmpIP = [fileHostInfoDict objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCIP];
		NSNumber		*tmpPort = [fileHostInfoDict objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCPort];
		if (tmpIP!=nil || tmpPort!=nil)	{
			OSCOutPort		*outPort = [oscm outPort];
			if (tmpIP == nil)
				tmpIP = [outPort addressString];
			if (tmpPort == nil)
				tmpPort = [NSNumber numberWithInteger:[outPort port]];
			[oscm setIPString:tmpIP portInt:[tmpPort intValue]];
		}
	}
	
	
	//	...now i need to run through the objects from the file, and create OSCNodes from them in an address space
	
	
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	//	destroy all the delegates immediately- we don't want them sending any messages back to the server while we're clearing the address space
	for (QueryServerNodeDelegate *tmpDelegate in delegates)	{
		[as removeDelegate:tmpDelegate forPath:[tmpDelegate address]];
	}
	[delegates removeAllObjects];
	
	//	clear out the OSC address space
	NSArray		*baseNodes = [[as nodeContents] lockCreateArrayCopy];
	for (OSCNode *baseNode in baseNodes)	{
		[baseNode removeFromAddressSpace];
	}
	
	//	now run through 'fileObject' recursively, creating OSC nodes for all the objects
	__block __weak void		(^ParseJSONObj)(NSDictionary *, NSString *);
	ParseJSONObj = ^(NSDictionary * baseObj, NSString * baseObjPath)	{
		
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
		
		OSCNode			*newNode = [[OSCAddressSpace mainAddressSpace] findNodeForAddress:baseObjPath createIfMissing:YES];
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
		
		//	make a delegate for the node, add it to the array
		QueryServerNodeDelegate		*tmpDelegate = [[QueryServerNodeDelegate alloc] initWithQueryServer:server forAddress:[newNode fullName]];
		[newNode addDelegate:tmpDelegate];
		[delegates addObject:tmpDelegate];
		
		//	run through the contents, calling this block recursively on each object
		[objContents enumerateKeysAndObjectsUsingBlock:^(NSString * tmpName, NSDictionary * tmpContentsObj, BOOL *stop)	{
			if ([tmpContentsObj isKindOfClass:[NSDictionary class]])	{
				NSString		*tmpPath = [NSString stringWithFormat:@"%@/%@",baseObjPath,tmpName];
				ParseJSONObj(tmpContentsObj, tmpPath);
			}
		}];
	};
	ParseJSONObj(fileObject, @"");
	
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
	
	//	update the file status field
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


#pragma mark -------------------------- OSCAddressSpaceDelegateProtocol


- (void) nodeRenamed:(OSCNode *)n from:(NSString *)oldName	{
	NSLog(@"%s ... %@, %@",__func__,n,oldName);
	if (oldName != nil)
		[server sendPathRenamedToClients:oldName to:[n fullName]];
}
/*
- (void) receivedOSCMessage:(OSCMessage *)m	{
	NSLog(@"%s ... %@",__func__,m);
}
*/


#pragma mark -------------------------- VVOSCQueryServerDelegate


- (VVOSCQueryReply *) hostInfoQueryFromServer:(VVOSCQueryServer *)s	{
	NSMutableDictionary		*hostInfo = (fileHostInfoDict==nil) ? [[NSMutableDictionary alloc] init] : [fileHostInfoDict mutableCopy];
	
	//	supply a server name if there isn't already one
	NSString			*myName = [s name];
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_Name]==nil && myName!=nil)
		[hostInfo setObject:myName forKey:kVVOSCQ_ReqAttr_HostInfo_Name];
	//	supply a transport mode if there isn't already one
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport] == nil)
		[hostInfo setObject:kVVOSCQueryOSCTransportUDP forKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport];
	//	supply an extensions array if there isn't already one
	NSDictionary		*myExtDict = @{
		kVVOSCQ_OptAttr_Tags : @YES,
		//kVVOSCQ_ReqAttr_Type : @YES,
		kVVOSCQ_OptAttr_Access : @YES,
		kVVOSCQ_OptAttr_Value : @YES,
		kVVOSCQ_OptAttr_Range : @YES,
		kVVOSCQ_OptAttr_Clipmode : @NO,
		kVVOSCQ_OptAttr_Unit : @YES,
		kVVOSCQ_OptAttr_Critical : @YES,
	};
	if ([hostInfo objectForKey:kVVOSCQ_ReqAttr_HostInfo_Exts] == nil)
		[hostInfo setObject:myExtDict forKey:kVVOSCQ_ReqAttr_HostInfo_Exts];
	
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
	//	make a fake port (it exists solely to provide a value to parsing methods)
	FakeOSCInPort		*fakePort = [[FakeOSCInPort alloc] init];
	//	parse the raw packet
	[OSCPacket
		parseRawBuffer:(unsigned char *)packet
		ofMaxLength:(int)packetSize
		toInPort:(OSCInPort *)fakePort
		fromAddr:0
		port:0];
	//	get the messages from the fake port, dispatch them to the remote app
	OSCOutPort		*outPort = [[oscm outPortArray] lockObjectAtIndex:0];
	NSArray			*msgs = [fakePort dumpArray];
	for (id msg in msgs)	{
		if ([msg isKindOfClass:[OSCMessage class]])
			[outPort sendThisMessage:msg];
		else if ([msg isKindOfClass:[OSCBundle class]])
			[outPort sendThisBundle:msg];
	}
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
