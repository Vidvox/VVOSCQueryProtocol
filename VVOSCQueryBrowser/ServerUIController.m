#import "ServerUIController.h"
#import <VVOSC/VVOSC.h>
#import "RemoteNodeTableCellView.h"
#import "RemoteNodeControlTableCellView.h"




@interface ServerUIController ()
- (void) reloadRemoteNodes;
@end




@implementation ServerUIController


static ServerUIController		*_global = nil;


+ (ServerUIController *) global	{
	return _global;
}


- (id) init	{
	self = [super init];
	if (self != nil)	{
		//	make the OSC manager
		oscm = [[OSCManager alloc] init];
		//	assign the singleton here (there should only ever be one instance of this class, which is the singleton by default)
		if (_global == nil)
			_global = self;
		
		//urlReplyDict = nil;
		//sortedURLReplyDictKeys = nil;
		urlReplyRemoteNodes = [[NSMutableArray alloc] init];
		
		expandedNodeAddresses = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void) awakeFromNib	{
	[self fullReloadData];
}


//@synthesize server;


- (IBAction) urlFieldUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{ [self urlFieldUsed:sender]; });
		return;
	}
	
	/*
	//	we're going to strip any queries out of the URL field and then sanitize the path
	NSURL			*url = [NSURL URLWithString:[urlField stringValue]];
	NSString		*pathString = [[url absoluteString] stringBySanitizingForOSCPath];
	if (pathString == nil) pathString = @"/";
	if (![[urlField stringValue] isEqualToString:pathString])
		[urlField setStringValue:pathString];
	
	//	get the string reply from the remote server
	//urlReplyString = (server==nil) ? nil : [server stringForOSCMethodAtAddress:pathString query:kVVOSCQ_ReqAttr_Contents];
	urlReplyString = (server==nil) ? nil : [server stringForOSCMethodAtAddress:pathString query:nil];
	
	//	convert the reply string to a JSON object (a dict)
	NSData			*urlReplyData = [urlReplyString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary	*urlReplyDict = (urlReplyString==nil) ? nil : [NSJSONSerialization JSONObjectWithData:urlReplyData options:0 error:nil];
	//NSLog(@"\t\turlReplyDict is %@",urlReplyDict);
	
	
	[urlReplyRemoteNodes removeAllObjects];
	RemoteNode		*tmpNode = [[RemoteNode alloc] initWithParent:nil dict:urlReplyDict];
	if (tmpNode != nil)
		[urlReplyRemoteNodes addObject:tmpNode];
	*/
	
	//	reload the table view, update the text view
	[self partialReloadData];
	
	/*
	//	make a pretty (indented) string for display in the JSON section
	NSData			*prettyData = nil;
	if (@available(macOS 10.13, *)) {
		prettyData = (urlReplyDict==nil) ? nil : [NSJSONSerialization dataWithJSONObject:urlReplyDict options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
		
	} else {
		prettyData = (urlReplyDict==nil) ? nil : [NSJSONSerialization dataWithJSONObject:urlReplyDict options:NSJSONWritingPrettyPrinted error:nil];
	}
	NSString		*prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
	if (prettyString == nil) prettyString = @"";
	[rawJSONTextView setString:prettyString];
	*/
}


- (void) newServerChosen:(VVOSCQueryRemoteServer*)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self newServerChosen:n];
		});
		return;
	}
	
	if (n == server && n != nil)
		return;
	
	//	resign as delegate from my existing server
	[server setDelegate:nil];
	
	//	update my server, sign up as its delegate
	server = n;
	[server setDelegate:self];
	
	//	do a full reload (reload the expand states too)
	[self fullReloadData];
	
	//	reset the URL field to the root node, pretend that it just fired off an action to populate the UI
	[urlField setStringValue:@"/"];
	[self urlFieldUsed:urlField];
}
- (void) sendMessageToRemoteServer:(OSCMessage *)n	{
	NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return;
	if (server == nil)
		return;
	
	//	if the remote OSC server uses TCP, bail, i'm not getting that working.
	if ([server oscServerTransport] == VVOSCQueryOSCTransportType_TCP)
		return;
	
	//	get the remote server's IP and port
	NSString		*ip = [server oscServerAddressString];
	if (ip == nil)
		ip = [server webServerAddressString];
	int				port = [server oscServerPort];
	//NSLog(@"\t\tremote server address is %@:%d",ip,port);
	//	find the OSC output that matches my server's IP and port (create one if it doesn't exist yet)
	OSCOutPort		*outPort = [oscm findOutputWithAddress:ip andPort:port];
	if (outPort == nil)
		outPort = [oscm createNewOutputToAddress:ip atPort:port];
	if (outPort != nil)	{
		//NSLog(@"\t\toutPort is %@",outPort);
		[outPort sendThisMessage:n];
	}
}


#pragma mark ---------------------------- VVOSCQueryRemoteServerDelegate


- (void) remoteServerWentOffline:(VVOSCQueryRemoteServer *)remoteServer	{
	if (![NSThread isMainThread])	{
		NSLog(@"\t\tERR: NOT MAIN THREAD, %s",__func__);
	}
	
	if (remoteServer != server)
		return;
	server = nil;
	[urlField setStringValue:@"/"];
	[self fullReloadData];
	[rawJSONTextView setString:@""];
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer websocketDeliveredJSONObject:(NSDictionary *)jsonObj	{
	NSLog(@"%s ... %@",__func__,jsonObj);
	NSLog(@"\t\tshould be checking for and handling PATH_CHANGED here, %s",__func__);
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)remoteServer receivedOSCPacket:(const void *)packet sized:(size_t)packetSize	{
	//NSLog(@"%s ... %p, %ld",__func__,packet,packetSize);
	
	
	
	
	
	/*
	//	find the OSC input we'll be using to receive packets on
	OSCInPort		*inPort = [[oscm inPortArray] objectAtIndex:0];
	if (inPort == nil)	{
		NSLog(@"\t\terr: inPort nil, bailing, %s",__func__);
		return;
	}
	//	find the OSC output corresponding to the remote server- we need its raw network address & port
	//NSLog(@"\t\tshould be looking for outputs with address %@:%ld",[remoteServer oscServerAddressString],[remoteServer oscServerPort]);
	//NSLog(@"\t\toutputs are %@",[oscm outPortArray]);
	OSCOutPort		*outPort = [oscm findOutputWithAddress:[remoteServer oscServerAddressString] andPort:[remoteServer oscServerPort]];
	//NSLog(@"\t\toutPort is %@",outPort);
	struct sockaddr_in		*addr = (outPort==nil) ? nil : [outPort addr];
	//if (addr == nil)	{
	//	NSLog(@"\t\terr: addr nil, bailing, %s",__func__);
	//	return;
	//}
	//	parse the packet, dispatching it automatically to the appropriate input with the appropriate routing information
	[OSCPacket
		parseRawBuffer:packet
		ofMaxLength:packetSize
		toInPort:inPort
		//fromAddr:0
		//port:0];
		fromAddr:addr->sin_addr.s_addr
		port:addr->sin_port];
	*/
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)rs pathChanged:(NSString *)n	{
	NSLog(@"%s ... %@",__func__,n);
	[self partialReloadData];
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)rs pathRenamedFrom:(NSString *)oldName to:(NSString *)newName	{
	NSLog(@"%s ... %@ -> %@",__func__,oldName,newName);
	[self partialReloadData];
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)rs pathRemoved:(NSString *)n	{
	NSLog(@"%s ... %@",__func__,n);
	[self partialReloadData];
}
- (void) remoteServer:(VVOSCQueryRemoteServer *)rs pathAdded:(NSString *)n	{
	NSLog(@"%s ... %@",__func__,n);
	[self partialReloadData];
}


#pragma mark ---------------------------- outline view data source/delegate


/*
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tv	{
	return (sortedURLReplyDictKeys==nil) ? 0 : [sortedURLReplyDictKeys count];
}
- (NSView *) tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row	{
	NSString		*tmpKey = (sortedURLReplyDictKeys==nil || row<0 || row>=[sortedURLReplyDictKeys count]) ? nil : [sortedURLReplyDictKeys objectAtIndex:row];
	NSDictionary	*tmpObj = (tmpKey==nil) ? nil : [urlReplyDict objectForKey:tmpKey];
	NSView		*returnMe = [tv makeViewWithIdentifier:@"MainCell" owner:self];
	[(RemoteNodeTableCellView*)returnMe refreshWithRemoteNode:tmpObj];
	return returnMe;
}
*/
- (NSInteger) outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	if (item == nil)	{
		return (urlReplyRemoteNodes==nil) ? 0 : [urlReplyRemoteNodes count];
	}
	else if ([item isKindOfClass:[RemoteNode class]])	{
		return [item controlCount] + [item contentsCount];
	}
	
	return 0;
}
- (BOOL) outlineView:(NSOutlineView *)ov isItemExpandable:(id)item	{
	if (item == nil)
		return YES;
	if ([item isKindOfClass:[RemoteNode class]])	{
		if ([item contentsCount]>0 || [item controlCount]>0)
			return YES;
		else
			return NO;
	}
	else
		return NO;
}
- (id) outlineView:(NSOutlineView *)ov child:(NSInteger)index ofItem:(id)item	{
	//NSLog(@"%s ... %d, %@",__func__,index,item);
	if (item == nil)	{
		return [urlReplyRemoteNodes objectAtIndex:index];
	}
	else if ([item isKindOfClass:[RemoteNode class]])	{
		NSArray		*nodeControlsArray = [item controls];
		int			nodeControlsArrayCount = (nodeControlsArray==nil) ? 0 : (int)[nodeControlsArray count];
		NSArray		*nodeContentsArray = [item contents];
		if (index < nodeControlsArrayCount)
			return [nodeControlsArray objectAtIndex:index];
		else	{
			int			actualIndex = (int)index - nodeControlsArrayCount;
			if (actualIndex<0 || actualIndex>=[nodeContentsArray count])
				return nil;
			return [nodeContentsArray objectAtIndex:actualIndex];
		}
	}
	return nil;
}
- (NSView *) outlineView:(NSOutlineView *)ov viewForTableColumn:(NSTableColumn *)tc item:(id)item	{
	
	//	outline/table views use the "identifier' to manage caching, so if we just use "RemoteNode" and "RemoteNodeControl" then we'll wind up re-using views inappropriately.  we have to change identifiers for the views as we make them.
	/*
	if ([item isKindOfClass:[RemoteNode class]])	{
		NSString			*itemIdentifier = [item outlineViewIdentifier];
		NSLog(@"\t\tidentifier is %@",itemIdentifier);
		RemoteNodeTableCellView		*returnMe = nil;
		returnMe = [ov makeViewWithIdentifier:itemIdentifier owner:nil];
		NSLog(@"\t\tfirst view is %@",returnMe);
		if (returnMe == nil)	{
			returnMe = [ov makeViewWithIdentifier:@"RemoteNode" owner:nil];
			NSLog(@"\t\tsecond view is %@",returnMe);
			[returnMe setIdentifier:itemIdentifier];
			NSLog(@"\t\tconfirming second view identifier: %@",[returnMe identifier]);
		}
	}
	else if ([item isKindOfClass:[RemoteNodeControl class]])	{
		NSString			*itemIdentifier = [item outlineViewIdentifier];
		NSLog(@"\t\tidentifier is %@",itemIdentifier);
		RemoteNodeControlTableCellView		*returnMe = nil;
		returnMe = [ov makeViewWithIdentifier:itemIdentifier owner:nil];
		NSLog(@"\t\tfirst view is %@",returnMe);
		if (returnMe == nil)	{
			returnMe = [ov makeViewWithIdentifier:@"RemoteNodeControl" owner:nil];
			NSLog(@"\t\tsecond view is %@",returnMe);
			[returnMe setIdentifier:itemIdentifier];
			NSLog(@"\t\tconfirming second view identifier: %@",[returnMe identifier]);
		}
	}
	*/
	
	
	if ([item isKindOfClass:[RemoteNode class]])	{
		RemoteNodeTableCellView		*returnMe = [ov makeViewWithIdentifier:@"RemoteNode" owner:nil];
		[returnMe refreshWithRemoteNode:item];
		return returnMe;
	}
	else if ([item isKindOfClass:[RemoteNodeControl class]])	{
		RemoteNodeControlTableCellView		*returnMe = [ov makeViewWithIdentifier:@"RemoteNodeControl" owner:nil];
		[returnMe refreshWithRemoteNodeControl:item outlineView:ov];
		return returnMe;
	}
	
	return nil;
}
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	if ([item isKindOfClass:[RemoteNode class]])	{
		return 41.;
	}
	else if ([item isKindOfClass:[RemoteNodeControl class]])	{
		return 32.;
	}
	return 10.;
}
- (void)outlineViewItemDidExpand:(NSNotification *)notification	{
	RemoteNode		*tmpNode = [[notification userInfo] objectForKey:@"NSObject"];
	if (tmpNode == nil)
		return;
	NSString		*tmpPath = [tmpNode fullPath];
	if (tmpPath == nil)
		return;
	@synchronized (self)	{
		[expandedNodeAddresses addObject:tmpPath];
	}
}
- (void)outlineViewItemDidCollapse:(NSNotification *)notification	{
	RemoteNode		*tmpNode = [[notification userInfo] objectForKey:@"NSObject"];
	if (tmpNode == nil)
		return;
	NSString		*tmpPath = [tmpNode fullPath];
	if (tmpPath == nil)
		return;
	@synchronized (self)	{
		[expandedNodeAddresses removeObject:tmpPath];
	}
}


- (void) reloadRemoteNodes	{
	NSLog(@"%s",__func__);
	//	we're going to strip any queries out of the URL field and then sanitize the path
	NSURL			*url = [NSURL URLWithString:[urlField stringValue]];
	NSString		*pathString = [[url absoluteString] stringBySanitizingForOSCPath];
	if (pathString == nil) pathString = @"/";
	if (![[urlField stringValue] isEqualToString:pathString])
		[urlField setStringValue:pathString];
	
	//	get the string reply from the remote server
	//urlReplyString = (server==nil) ? nil : [server stringForOSCMethodAtAddress:pathString query:kVVOSCQ_ReqAttr_Contents];
	urlReplyString = (server==nil) ? nil : [server stringForOSCMethodAtAddress:pathString query:nil];
	
	//	convert the reply string to a JSON object (a dict)
	NSData			*urlReplyData = [urlReplyString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary	*urlReplyDict = (urlReplyString==nil) ? nil : [NSJSONSerialization JSONObjectWithData:urlReplyData options:0 error:nil];
	//NSLog(@"\t\turlReplyDict is %@",urlReplyDict);
	
	[urlReplyRemoteNodes removeAllObjects];
	RemoteNode		*tmpNode = [[RemoteNode alloc] initWithParent:nil dict:urlReplyDict];
	if (tmpNode != nil)
		[urlReplyRemoteNodes addObject:tmpNode];
	
	//	make a pretty (indented) string for display in the JSON section
	NSData			*prettyData = nil;
	if (@available(macOS 10.13, *)) {
		prettyData = (urlReplyDict==nil) ? nil : [NSJSONSerialization dataWithJSONObject:urlReplyDict options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
		
	} else {
		prettyData = (urlReplyDict==nil) ? nil : [NSJSONSerialization dataWithJSONObject:urlReplyDict options:NSJSONWritingPrettyPrinted error:nil];
	}
	NSString		*prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
	if (prettyString == nil) prettyString = @"";
	[rawJSONTextView setString:prettyString];
}
- (void) partialReloadData	{
	NSLog(@"%s",__func__);
	[self reloadRemoteNodes];
	
	//	tell the outline view to reload its data
	[uiItemOutlineView reloadData];
	
	//	run through every row in the outline view, restoring the expand state
	NSArray		*lastExpNodes = nil;
	@synchronized (self)	{
		lastExpNodes = [expandedNodeAddresses copy];
	}
	
	int			theRow = 0;
	do	{
		id		anObj = [uiItemOutlineView itemAtRow:theRow];
		if (anObj != nil)	{
			//	if the item at this row can potentially be expanded
			if ([anObj isKindOfClass:[RemoteNode class]] && ([anObj contentsCount]>0 || [anObj controlCount]>0))	{
				//	was it expanded when we last checked?
				if ([lastExpNodes containsObject:[anObj fullPath]])
					[uiItemOutlineView expandItem:anObj];
			}
			//	else the item can't potentially be expanded
			else	{
				//return NO;
			}
		}
		++theRow;
	} while (theRow < [uiItemOutlineView numberOfRows]);
	
	
	
}
- (void) fullReloadData	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		[expandedNodeAddresses removeAllObjects];
	}
	[self reloadRemoteNodes];
	[uiItemOutlineView reloadData];
}


@end
