#import "OSCQueryProtocolServerAppDelegate.h"
#import "OSCNodeAdditions.h"




@interface OSCQueryProtocolServerAppDelegate ()
@property (weak) IBOutlet NSWindow *window;
- (void) _updateUIItems;
- (void) populateOSCAddressSpace;
- (void) populateTestDirectory;
- (void) populateVecsDirectory;
- (void) populateTuplesDirectory;
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




@implementation OSCQueryProtocolServerAppDelegate

- (id) init	{
	self = [super init];
	if (self != nil)	{
		rxOSCMsgs = [[NSMutableArray alloc] init];
		
		//	make an VVOSCQueryServer- we'll start it later, when the app finishes launching
		server = [[VVOSCQueryServer alloc] init];
		[server setName:@"server name"];
		[server setBonjourName:@"server bonjour name"];
		[server setDelegate:self];
		
		
		/*		everything below here is specific to the OSC framework i've chosen to use		*/
		
		
		//	make an OSC manager, set myself up as its delegate so i receive any OSC traffic that i can display here
		oscm = [[OSCManager alloc] init];
		[oscm setDelegate:self];
		//	make a new OSC input- this is what will receive OSC data
		oscIn = [oscm createNewInput];
		[oscIn setPortLabel:@"query server test app OSC input"];
		
		//	populate the OSC address space with a series of OSC nodes!
		[self populateOSCAddressSpace];
		
	}
	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
	//	start the VVOSCQueryServer!
	[server start];
	
	//	populate the text field in the UI with the address of the web server!
	[self _updateUIItems];
	/*
	NSString		*serverAddress = [NSString stringWithFormat:@"http://localhost:%d",[server webServerPort]];
	[statusField setStringValue:serverAddress];
	[portField setStringValue:[NSString stringWithFormat:@"%d",[server webServerPort]]];
	*/
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
	//	stop the VVOSCQueryServer!
	[server stop];
}


- (IBAction) sendPathChangedClicked:(id)sender	{
	//NSLog(@"%s",__func__);
	[server sendJSONObjectToClients:@{ kVVOSCQ_WSAttr_Cmd_PathChanged : @"/thingamajig" }];
}
- (IBAction) portFieldUsed:(id)sender	{
	NSLog(@"%s",__func__);
	NSString		*tmpString = [portField stringValue];
	if (tmpString!=nil && [tmpString length]>0)	{
		NSInteger		tmpInt = [tmpString integerValue];
		if (tmpInt != 0)	{
			BOOL			wasRunning = [server isRunning];
			[server stop];
			if (wasRunning)
				[server startWithPort:(int)tmpInt];
			[self _updateUIItems];
		}
	}
}


- (IBAction) stopClicked:(id)sender	{
	NSLog(@"%s",__func__);
	[server stop];
	[self _updateUIItems];
}
- (IBAction) startClicked:(id)sender	{
	NSLog(@"%s",__func__);
	NSString		*tmpString = [portField stringValue];
	NSInteger		tmpInt = [tmpString integerValue];
	if (tmpInt == 0)
		tmpInt = 2345;
	[server startWithPort:(int)tmpInt];
	[self _updateUIItems];
}


- (void) _updateUIItems	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self _updateUIItems];
		});
		return;
	}
	if ([server isRunning])	{
		NSString		*fullAddressString = [NSString stringWithFormat:@"http://localhost:%d",[server webServerPort]];
		NSString		*htmlString = [NSString stringWithFormat:@"<A HREF=\"%@\">%@</A>",fullAddressString,fullAddressString];
		NSAttributedString	*htmlAttrStr = [htmlString renderedHTMLWithFont:nil];
		NSLog(@"\t\tsetting val to %@",htmlAttrStr);
		[statusField setAttributedStringValue:htmlAttrStr];
	}
	else	{
		NSLog(@"\t\tsetting val to %@",@"Not running!");
		[statusField setStringValue:@"Not running!"];
	}
	
	//if (![server isRunning])
	//	fullAddressString = @"Not running!";
	//[statusField setStringValue:fullAddressString];
	if ([server webServerPort] != 0)	{
		NSString		*portString = [NSString stringWithFormat:@"%d",[server webServerPort]];
		[portField setStringValue:portString];
	}
}


#pragma mark -------------------------- VVOSCQueryServerDelegate


//	this is the VVOSCQueryServerDelegate protocol method- requests received by the OSC query server are passed to this method
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s wantsReplyForQuery:(VVOSCQuery *)q	{
	NSLog(@"%s ... %@",__func__,q);
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
- (VVOSCQueryReply *) server:(VVOSCQueryServer *)s websocketDeliveredJSONObject:(NSDictionary *)jsonObj	{
	NSLog(@"%s ... %@",__func__,jsonObj);
	return nil;
}
- (VVOSCQueryReply *) hostInfoQueryFromServer:(VVOSCQueryServer *)s	{
	NSMutableDictionary		*hostInfo = [[NSMutableDictionary alloc] init];
	if ([s name] != nil)
		[hostInfo setObject:[s name] forKey:kVVOSCQ_ReqAttr_HostInfo_Name];
	//	the OSC server is hosted at the same IP as the websocket server, so i can skip the IP address- but i need to supply the OSC port in the host info dict
	if (oscIn != nil)
		[hostInfo setObject:[NSNumber numberWithInteger:[oscIn port]] forKey:kVVOSCQ_ReqAttr_HostInfo_OSCPort];
	[hostInfo setObject:kVVOSCQueryOSCTransportUDP forKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport];
	
	//	...i don't need to supply values for kVVOSCQ_ReqAttr_HostInfo_WSIP or kVVOSCQ_ReqAttr_HostInfo_WSPort because i know that the websocket server is hosted at the same IP and port as the HTTP server
	
	//	assemble the extensions dict, add it to the host info dict
	NSDictionary		*extDict = @{
		kVVOSCQ_OptAttr_Tags : @YES,
		kVVOSCQ_OptAttr_Type : @YES,
		kVVOSCQ_OptAttr_Access : @YES,
		kVVOSCQ_OptAttr_Value : @YES,
		kVVOSCQ_OptAttr_Range : @YES,
		kVVOSCQ_OptAttr_Clipmode : @NO,
		kVVOSCQ_OptAttr_Unit : @YES,
		kVVOSCQ_OptAttr_Critical : @YES,
	};
	[hostInfo setObject:extDict forKey:kVVOSCQ_ReqAttr_HostInfo_Exts];
	
	return [[VVOSCQueryReply alloc] initWithJSONObject:hostInfo];;
}


#pragma mark -------------------------- OSCDelegateProtocol


//	this is the OSCDelegateProtocol method- OSC messages sent to the OSC input are passed to this method
- (void) receivedOSCMessage:(OSCMessage *)m	{
	//NSLog(@"%s ... %@",__func__,m);
	if (m==nil)
		return;
	//	just pass the message to the OSC address space
	[_mainVVOSCAddressSpace dispatchMessage:m];
	
	
	NSMutableString		*tmpStr = [[NSMutableString alloc] init];
	@synchronized (self)	{
		[rxOSCMsgs addObject:m];
		while ([rxOSCMsgs count]>50)
			[rxOSCMsgs removeObjectAtIndex:0];
		
		for (OSCMessage *msg in [rxOSCMsgs reverseObjectEnumerator])
			[tmpStr appendFormat:@"%@\n",[msg description]];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[rxOSCMessageView setString:tmpStr];
	});
}


#pragma mark -------------------------- OSC address space setup


- (void) populateOSCAddressSpace	{
	[self populateTestDirectory];
	[self populateVecsDirectory];
	[self populateTuplesDirectory];
}
- (void) populateTestDirectory	{
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
		OSCNode				*tmpNode = nil;
		//	first make the "test" directory node (this will be created automatically if necessary, only fetching it as a discrete step here so we can set its description)
		tmpNode = [as findNodeForAddress:@"/test" createIfMissing:YES];
		[tmpNode setNodeType:OSCNodeDirectory];
		[tmpNode setOSCDescription:@"test directory"];
		
		//	now make a bunch of other OSC nodes
		tmpNode = [as findNodeForAddress:@"/test/my_int" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test integer node"];
		[tmpNode setTypeTagString:@"i"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0, kVVOSCQ_OptAttr_Range_Max:@100 } ]];
		[tmpNode setTags:@[ @"integer input" ]];
		[tmpNode setClipmode:@[ @"none" ]];
		[tmpNode setUnits:@[ @"dollars" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_float" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test float node"];
		[tmpNode setTypeTagString:@"f"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0., kVVOSCQ_OptAttr_Range_Max:@100. } ]];
		[tmpNode setTags:@[ @"float input" ]];
		[tmpNode setClipmode:@[ @"none" ]];
		[tmpNode setUnits:@[ @"percent" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_string" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeString];
		[tmpNode setOSCDescription:@"test string node"];
		[tmpNode setTypeTagString:@"s"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"string input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/timetag" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test timetag node"];
		[tmpNode setTypeTagString:@"t"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"timetag input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_longlong" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test 64-bit int node"];
		[tmpNode setTypeTagString:@"h"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0, kVVOSCQ_OptAttr_Range_Max:@100 } ]];
		[tmpNode setTags:@[ @"64-bit integer input" ]];
		[tmpNode setClipmode:@[ @"none" ]];
		[tmpNode setUnits:@[ @"big numbers" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_double" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test double node"];
		[tmpNode setTypeTagString:@"d"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0., kVVOSCQ_OptAttr_Range_Max:@100. } ]];
		[tmpNode setTags:@[ @"double input" ]];
		[tmpNode setClipmode:@[ @"none" ]];
		[tmpNode setUnits:@[ @"precise unit" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_char" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeString];
		[tmpNode setOSCDescription:@"test character node"];
		[tmpNode setTypeTagString:@"c"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"character input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_color" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeColor];
		[tmpNode setOSCDescription:@"test color node"];
		[tmpNode setTypeTagString:@"r"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"color input" ]];
		[tmpNode setUnits:@[ @"RGBA" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_midi" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test MIDI node"];
		[tmpNode setTypeTagString:@"m"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"midi input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_true" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test true node"];
		[tmpNode setTypeTagString:@"T"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"true input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_false" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test false node"];
		[tmpNode setTypeTagString:@"F"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"false input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_null" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test null node"];
		[tmpNode setTypeTagString:@"N"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"null input" ]];
		
		tmpNode = [as findNodeForAddress:@"/test/my_infinity" createIfMissing:YES];
		//[tmpNode setNodeType:OSCNodeTypeNumber];
		[tmpNode setOSCDescription:@"test infinity node"];
		[tmpNode setTypeTagString:@"I"];
		[tmpNode setAccess:OSCNodeAccess_RW];
		[tmpNode setTags:@[ @"infinity input" ]];
		
}
- (void) populateVecsDirectory	{
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	OSCNode				*tmpNode = nil;
	//	first make the "test" directory node (this will be created automatically if necessary, only fetching it as a discrete step here so we can set its description)
	tmpNode = [as findNodeForAddress:@"/vecs" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeDirectory];
	[tmpNode setOSCDescription:@"vecs directory"];
	
	//	now make a bunch of other OSC nodes
	tmpNode = [as findNodeForAddress:@"/vecs/first" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test integer vec node"];
	[tmpNode setTypeTagString:@"iiii"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[
		@{
			kVVOSCQ_OptAttr_Range_Min:@0,
			kVVOSCQ_OptAttr_Range_Max:@10
			},
		@{
			kVVOSCQ_OptAttr_Range_Min:@10,
			kVVOSCQ_OptAttr_Range_Max:@20
			},
		@{
			//kVVOSCQ_OptAttr_Range_Min:@20,
			//kVVOSCQ_OptAttr_Range_Max:@30
			kVVOSCQ_OptAttr_Range_Vals: @[
				@22,
				@24,
				@26,
				@28,
				@29
				]
			},
		@{
			kVVOSCQ_OptAttr_Range_Min:@30,
			kVVOSCQ_OptAttr_Range_Max:@40
			}
		]];
	[tmpNode setTags:@[ @"integer vec input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"dollars" ]];
	
	
	/*
	tmpNode = [as findNodeForAddress:@"/test/my_int" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test integer node"];
	[tmpNode setTypeTagString:@"i"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0, kVVOSCQ_OptAttr_Range_Max:@100 } ]];
	[tmpNode setTags:@[ @"integer input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"dollars" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_float" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test float node"];
	[tmpNode setTypeTagString:@"f"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0., kVVOSCQ_OptAttr_Range_Max:@100. } ]];
	[tmpNode setTags:@[ @"float input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"percent" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_string" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeString];
	[tmpNode setOSCDescription:@"test string node"];
	[tmpNode setTypeTagString:@"s"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"string input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/timetag" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test timetag node"];
	[tmpNode setTypeTagString:@"t"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"timetag input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_longlong" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test 64-bit int node"];
	[tmpNode setTypeTagString:@"h"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0, kVVOSCQ_OptAttr_Range_Max:@100 } ]];
	[tmpNode setTags:@[ @"64-bit integer input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"big numbers" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_double" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test double node"];
	[tmpNode setTypeTagString:@"d"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[ @{ kVVOSCQ_OptAttr_Range_Min:@0., kVVOSCQ_OptAttr_Range_Max:@100. } ]];
	[tmpNode setTags:@[ @"double input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"precise unit" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_char" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeString];
	[tmpNode setOSCDescription:@"test character node"];
	[tmpNode setTypeTagString:@"c"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"character input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_color" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeColor];
	[tmpNode setOSCDescription:@"test color node"];
	[tmpNode setTypeTagString:@"r"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"color input" ]];
	[tmpNode setUnits:@[ @"RGBA" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_midi" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test MIDI node"];
	[tmpNode setTypeTagString:@"m"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"midi input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_true" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test true node"];
	[tmpNode setTypeTagString:@"T"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"true input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_false" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test false node"];
	[tmpNode setTypeTagString:@"F"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"false input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_null" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test null node"];
	[tmpNode setTypeTagString:@"N"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"null input" ]];
	
	tmpNode = [as findNodeForAddress:@"/test/my_infinity" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test infinity node"];
	[tmpNode setTypeTagString:@"I"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setTags:@[ @"infinity input" ]];
	*/
}
- (void) populateTuplesDirectory	{
	OSCAddressSpace		*as = [OSCAddressSpace mainAddressSpace];
	OSCNode				*tmpNode = nil;
	//	first make the "test" directory node (this will be created automatically if necessary, only fetching it as a discrete step here so we can set its description)
	tmpNode = [as findNodeForAddress:@"/tuples" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeDirectory];
	[tmpNode setOSCDescription:@"vecs directory"];
	
	//	now make a bunch of other OSC nodes
	tmpNode = [as findNodeForAddress:@"/tuples/first" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test integer tuple node"];
	[tmpNode setTypeTagString:@"i[ii]i"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[
		@{
			kVVOSCQ_OptAttr_Range_Min:@0,
			kVVOSCQ_OptAttr_Range_Max:@10
		},
		@[
			@{
				kVVOSCQ_OptAttr_Range_Min:@10,
				kVVOSCQ_OptAttr_Range_Max:@20
			},
			@{
				kVVOSCQ_OptAttr_Range_Vals: @[
					@22,
					@24,
					@26,
					@28,
					@29
				]
			}
		],
		@{
			kVVOSCQ_OptAttr_Range_Min:@30,
			kVVOSCQ_OptAttr_Range_Max:@40
		}
		]];
	[tmpNode setTags:@[ @"SUPER MEGA AWESOME input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	[tmpNode setUnits:@[ @"stinky gym socks" ]];
	
	
	
	tmpNode = [as findNodeForAddress:@"/tuples/second" createIfMissing:YES];
	[tmpNode setNodeType:OSCNodeTypeNumber];
	[tmpNode setOSCDescription:@"test integer tuple node"];
	[tmpNode setTypeTagString:@"i[sf]dc"];
	[tmpNode setAccess:OSCNodeAccess_RW];
	[tmpNode setRange:@[
		@{
			kVVOSCQ_OptAttr_Range_Min:@0,
			kVVOSCQ_OptAttr_Range_Max:@10
		},
		@[
			@{
				kVVOSCQ_OptAttr_Range_Vals: @[
					@"one",
					@"two",
					@"hey you"
				]
			},
			@{
				kVVOSCQ_OptAttr_Range_Vals: @[
					@22.,
					@24.,
					@26.,
					@28.,
					@29.
				]
			}
		],
		@{
			kVVOSCQ_OptAttr_Range_Min:@0.,
			kVVOSCQ_OptAttr_Range_Max:@1.
		},
		@{
			kVVOSCQ_OptAttr_Range_Vals: @[
				@"a",
				@"b",
				@"c",
				@"d",
				@"z"
			]
		},
		]];
	[tmpNode setTags:@[ @"integer symbol float double char tuple input" ]];
	[tmpNode setClipmode:@[ @"none" ]];
	
}


@end
