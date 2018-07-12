#import "VVOSCQueryRemoteServer.h"
#import "NSStringAdditions.h"
#import "VVOSCQueryServerDetector.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "CURLDL.h"
#include "WSPPClient.hpp"
#import "ZWRObject.h"




@interface VVOSCQueryRemoteServer ()	{
	std::shared_ptr<WSPPClient>		wsClient;
}
- (void) _finishInit;
@property (retain,setter=setOSCServerAddressString:) NSString * oscServerAddressString;
@property (assign,setter=setOSCServerPort:) int oscServerPort;
@property (assign,setter=setOSCServerTransport:) VVOSCQueryOSCTransportType oscServerTransport;
@property (retain,setter=setOSCName:) NSString * oscName;
@property (retain,setter=setWSServerAddressString:) NSString * wsServerAddressString;
@property (assign,setter=setWSServerPort:) int wsServerPort;
- (NSData *) _dataForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString;
@end




@implementation VVOSCQueryRemoteServer


+ (NSArray<VVOSCQueryRemoteServer*> *) remoteServers	{
	NSArray		*returnMe = nil;
	@synchronized ([VVOSCQueryRemoteServer class])	{
		if (_allRemoteServers!=nil && [_allRemoteServers count]>0)
			returnMe = [NSArray arrayWithArray:_allRemoteServers];
	}
	return returnMe;
}
+ (NSArray *) hostIPv4Addresses	{
	struct ifaddrs		*interfaces = nil;
	int					err = 0;
	//	get the current interfaces
	err = getifaddrs(&interfaces);
	if (err)	{
		NSLog(@"\t\terr %d getting ifaddrs in %s",err,__func__);
		return nil;
	}
	//	define a character range with alpha-numeric chars so i can exclude IPv6 addresses!
	NSCharacterSet		*charSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefABCDEF:%"];
	NSMutableArray		*returnMe = nil;
	
	//	run through the interfaces
	struct ifaddrs		*tmpAddr = interfaces;
	while (tmpAddr != nil)	{
		if (tmpAddr->ifa_addr->sa_family == AF_INET)	{
			//	get the string for the interface
			NSString		*tmpString = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)tmpAddr->ifa_addr)->sin_addr)];
			if (tmpString != nil)	{
				//	make sure the interface string doesn't have any alpha-numeric/IPv6 chars in it!
				NSRange				charSetRange = [tmpString rangeOfCharacterFromSet:charSet];
				if ((charSetRange.length==0) && (charSetRange.location==NSNotFound))	{
					if (![tmpString isEqualToString:@"127.0.0.1"])	{
						if (returnMe == nil)
							returnMe = [NSMutableArray arrayWithCapacity:0];
						[returnMe addObject:tmpString];
					}
				}
			}
		}
		tmpAddr = tmpAddr->ifa_next;
	}
	
	if (interfaces != nil)	{
		freeifaddrs(interfaces);
		interfaces = nil;
	}
	return returnMe;
}
+ (void) initialize	{
	//NSLog(@"%s",__func__);
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
	//	initialize the server detector, which will start looking for bonjour services that list OSCQuery servers
	[VVOSCQueryServerDetector class];
}




- (instancetype) initWithWebServerAddressString:(NSString *)inWebServerAddressString
port:(int)inWebServerPort
bonjourName:(NSString *)inBonjourName	{
	//NSLog(@"%s ... %@, %d, %@",__func__,inWebServerAddressString,inWebServerPort,inBonjourName);
	self = [super init];
	if (self != nil)	{
		webServerAddressString = inWebServerAddressString;
		webServerPort = inWebServerPort;
		oscServerAddressString = nil;
		oscServerPort = inWebServerPort;
		oscServerTransport = VVOSCQueryOSCTransportType_Unknown;
		wsServerAddressString = nil;
		wsServerPort = -1;
		bonjourName = inBonjourName;
		//delegate = nil;
		delegateRefs = [[NSMutableArray alloc] init];
		wsClient = make_shared<WSPPClient>();
		
		__weak id		bss = self;
		wsClient->set_websocket_callback([&,bss](const std::string & inRawWSString)	{
			//cout << __PRETTY_FUNCTION__ << " ws callback" << endl;
			@autoreleasepool	{
				NSString	*rawString = [NSString stringWithUTF8String:inRawWSString.c_str()];
				//NSLog(@"\t\trawString is %@",rawString);
				NSData		*rawStringData = (rawString==nil) ? nil : [rawString dataUsingEncoding:NSUTF8StringEncoding];
				//	if i can't parse the string into data, skip a reply
				if (rawStringData == nil)	{
					//return WSPPQueryReply(false);
					return;
				}
				id			parsedJSONObject = [NSJSONSerialization JSONObjectWithData:rawStringData options:0 error:nil];
				//NSLog(@"\t\tparsedJSONObject is %@",parsedJSONObject);
				//	if the parsed object is the wrong kind of class, just return an empty object
				if (parsedJSONObject!=nil && ![parsedJSONObject isKindOfClass:[NSDictionary class]])
					parsedJSONObject = nil;
				//	if i couldn't parse the string into a JSON object (an actual object, not an array) by now, skip a reply
				if (parsedJSONObject == nil)	{
					//return WSPPQueryReply(false);
					return;
				}
				
				//	pass the parsed json object to my delegate, which may have a reply of some sort
				if (parsedJSONObject != nil)	{
					//NSLog(@"\t\tbss is %p",bss);
					
					dispatch_async(dispatch_get_main_queue(), ^{
						for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
							id		tmpDelegate = [tmpDelegateHolder object];
							if (tmpDelegate != nil)
								[tmpDelegate remoteServer:bss websocketDeliveredJSONObject:parsedJSONObject];
						}
					});
					
				}
				//	if i don't have a delegate, or my delegate doesn't have a reply, skip a reply
				//if (returnMe == nil)	{
					//return WSPPQueryReply(false);
				//	return;
				//}
				//	...if i'm here then my delegate gave me a reply string- wrap it up in a query reply, and return it
				//return WSPPQueryReply(std::string([returnMe UTF8String]));
			}
		});
		wsClient->set_osc_callback([&,bss](const void * inBuffer, const size_t & inBufferSize)	{
			//cout << __PRETTY_FUNCTION__ << " osc callback" << endl;
			@autoreleasepool	{
				for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
					id		tmpDelegate = [tmpDelegateHolder object];
					if (tmpDelegate != nil)
						[tmpDelegate remoteServer:bss receivedOSCPacket:inBuffer sized:inBufferSize];
				}
			}
		});
		wsClient->set_close_callback([&,bss](void)	{
			@autoreleasepool	{
				dispatch_async(dispatch_get_main_queue(), ^{
					//	notify my delegate that this server went offline
					for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
						id		tmpDelegate = [tmpDelegateHolder object];
						if (tmpDelegate != nil)
							[tmpDelegate remoteServerWentOffline:bss];
					}
				});
			}
		});
		wsClient->set_path_changed_callback([&,bss](const std::string & inPathString)	{
			@autoreleasepool	{
				NSString	*tmpString = [[NSString alloc] initWithCString:inPathString.c_str() encoding:NSUTF8StringEncoding];
				dispatch_async(dispatch_get_main_queue(), ^{
					for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
						id		tmpDelegate = [tmpDelegateHolder object];
						if (tmpDelegate != nil)
							[tmpDelegate remoteServer:bss pathChanged:tmpString];
					}
				});
				tmpString = nil;
			}
		});
		wsClient->set_path_renamed_callback([&,bss](const std::string & oldPathString, const std::string & newPathString)	{
			@autoreleasepool	{
				NSString		*oldPath = [[NSString alloc] initWithCString:oldPathString.c_str() encoding:NSUTF8StringEncoding];
				NSString		*newPath = [[NSString alloc] initWithCString:newPathString.c_str() encoding:NSUTF8StringEncoding];
				dispatch_async(dispatch_get_main_queue(), ^{
					for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
						id		tmpDelegate = [tmpDelegateHolder object];
						if (tmpDelegate != nil)
							[tmpDelegate remoteServer:bss pathRenamedFrom:oldPath to:newPath];
					}
				});
				oldPath = nil;
				newPath = nil;
			}
		});
		wsClient->set_path_removed_callback([&,bss](const std::string & inPathString)	{
			@autoreleasepool	{
				NSString	*tmpString = [NSString stringWithUTF8String:inPathString.c_str()];
				dispatch_async(dispatch_get_main_queue(), ^{
					for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
						id		tmpDelegate = [tmpDelegateHolder object];
						if (tmpDelegate != nil)
							[tmpDelegate remoteServer:bss pathRemoved:tmpString];
					}
				});
				tmpString = nil;
			}
		});
		wsClient->set_path_added_callback([&,bss](const std::string & inPathString)	{
			@autoreleasepool	{
				NSString	*tmpString = [NSString stringWithUTF8String:inPathString.c_str()];
				dispatch_async(dispatch_get_main_queue(), ^{
					for (id tmpDelegateHolder in [(VVOSCQueryRemoteServer*)bss delegateRefs])	{
						id		tmpDelegate = [tmpDelegateHolder object];
						if (tmpDelegate != nil)
							[tmpDelegate remoteServer:bss pathAdded:tmpString];
					}
				});
				tmpString = nil;
			}
		});
	}
	if (inWebServerAddressString == nil ||
	inBonjourName == nil)	{
		self = nil;
	}
	else	{
		[self _finishInit];
	}
	return self;
}
- (void) _finishInit	{
	
	//	do a hostInfo query on the remote server- we're going to want to finish populating my instance variables with values from the remote server
	NSDictionary	*hostInfoObject = [self hostInfo];
	if (hostInfoObject!=nil && [hostInfoObject isKindOfClass:[NSDictionary class]])	{
		//	now pick some values out and use them to finish populating the VVOSCQueryRemoteServer instance
		NSString		*tmpString = nil;
		NSNumber		*tmpNum = nil;
		//	host name
		tmpString = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_Name];
		if (tmpString != nil)
			[self setOSCName:tmpString];
		
		//	osc info
		tmpString = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCIP];
		if (tmpString != nil)
			[self setOSCServerAddressString:tmpString];
		else
			[self setOSCServerAddressString:webServerAddressString];
		
		tmpNum = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCPort];
		if (tmpNum != nil)	{
			if ([tmpNum isKindOfClass:[NSNumber class]])
				[self setOSCServerPort:[tmpNum intValue]];
			else if ([tmpNum isKindOfClass:[NSString class]])
				[self setOSCServerPort:[(NSString *)tmpNum intValue]];
			else
				[self setOSCServerPort:webServerPort];
		}
		else
			[self setOSCServerPort:webServerPort];
		
		tmpString = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_OSCTransport];
		if (tmpString != nil)	{
			if ([tmpString isEqualToString:kVVOSCQueryOSCTransportUDP])	{
				[self setOSCServerTransport:VVOSCQueryOSCTransportType_UDP];
			}
			else if ([tmpString isEqualToString:kVVOSCQueryOSCTransportTCP])	{
				[self setOSCServerTransport:VVOSCQueryOSCTransportType_TCP];
			}
			else
				[self setOSCServerTransport:VVOSCQueryOSCTransportType_UDP];
		}
		else
			[self setOSCServerTransport:VVOSCQueryOSCTransportType_UDP];
		
		//	websockets info
		tmpString = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_WSIP];
		if (tmpString != nil)
			[self setWSServerAddressString:tmpString];
		tmpNum = [hostInfoObject objectForKey:kVVOSCQ_ReqAttr_HostInfo_WSPort];
		if (tmpNum != nil)	{
			if ([tmpNum isKindOfClass:[NSNumber class]])
				[self setWSServerPort:[tmpNum intValue]];
			else if ([tmpNum isKindOfClass:[NSString class]])
				[self setWSServerPort:[(NSString *)tmpNum intValue]];
		}
	}
	
	//	try to establish a websocket connection with the wsClient
	NSString		*wsIP = nil;
	int				wsPort = -1;
	wsIP = (wsServerAddressString!=nil) ? [self wsServerAddressString] : [self webServerAddressString];
	wsPort = (wsServerPort!=-1) ? [self wsServerPort] : [self webServerPort];
	NSString		*wsURI = (wsIP==nil || wsPort<0) ? nil : [NSString stringWithFormat:@"ws://%@:%d",wsIP,wsPort];
	//NSLog(@"\t\tneed to establish ws connection to %@...",wsURI);
	if (wsClient != nullptr && wsURI != nil)	{
		wsClient->connect(std::string([wsURI UTF8String]));
	}
	
}
- (void) dealloc	{
	//NSLog(@"%s ... %p",__func__,self);
	webServerAddressString = nil;
	oscServerAddressString = nil;
	bonjourName = nil;
	delegateRefs = nil;
	if (wsClient != nullptr)	{
		wsClient->disconnect();
		int			tmpCount = 0;
		while (wsClient->isConnected() && tmpCount<5)	{
			[NSThread sleepForTimeInterval:1./10.];
			++tmpCount;
		}
		/*
		wsClient->stop();
		while (wsClient->isRunning())	{
			[NSThread sleepForTimeInterval:1./10.];
		}
		*/
		wsClient = nullptr;
	}
}
- (NSString *) description	{
	NSString		*returnMe = nil;
	//if (oscName != nil)
	//	returnMe = [NSString stringWithFormat:@"<VVOSCQueryRemoteServer %@>",oscName];
	//else if (bonjourName != nil)
	//	returnMe = [NSString stringWithFormat:@"<VVOSCQueryRemoteServer %@>",bonjourName];
	returnMe = [NSString stringWithFormat:@"<VVOSCQueryRemoteServer %@:%d, \"%@\">",webServerAddressString,webServerPort,bonjourName];
	return returnMe;
}

@synthesize webServerAddressString;
@synthesize webServerPort;
@synthesize oscServerAddressString;
@synthesize oscServerPort;
@synthesize oscServerTransport;
@synthesize oscName;
@synthesize wsServerAddressString;
@synthesize wsServerPort;
@synthesize bonjourName;


- (void) addDelegate:(id<VVOSCQueryRemoteServerDelegate>)n	{
	if (n==nil)
		return;
	ZWRObject		*tmpObj = [[ZWRObject alloc] initWithObject:n];
	@synchronized (self)	{
		if (tmpObj != nil)
			[delegateRefs addObject:tmpObj];
	}
}
- (void) removeDelegate:(id<VVOSCQueryRemoteServerDelegate>)n	{
	if (n==nil)
		return;
	@synchronized (self)	{
		int			tmpIndex = 0;
		for (ZWRObject *tmpHolder in delegateRefs)	{
			id			tmpObj = [tmpHolder object];
			if (tmpObj!=nil && tmpObj==n)	{
				[delegateRefs removeObjectAtIndex:tmpIndex];
				break;
			}
			++tmpIndex;
		}
	}
}
- (NSArray *) delegateRefs	{
	NSArray		*returnMe = nil;
	@synchronized (self)	{
		returnMe = [delegateRefs copy];
	}
	return returnMe;
}


- (NSDictionary *) hostInfo;	{
	//NSLog(@"%s",__func__);
	NSDictionary	*returnMe = nil;
	
	NSString		*hostInfoQueryAddress = [NSString stringWithFormat:@"http://%@:%d?HOST_INFO",webServerAddressString,webServerPort];
	//NSLog(@"\t\thostInfoQueryAddress is %@",hostInfoQueryAddress);
	CURLDL			*downloader = [[CURLDL alloc] initWithAddress:hostInfoQueryAddress];
	[downloader appendStringToHeader:@"Connection: close"];
	[downloader setConnectTimeout:2.];
	[downloader setDNSCacheTimeout:2.];
	[downloader perform];
	if ([downloader err] != 0)
		NSLog(@"\t\terr: %ld, %s",[downloader err],__func__);
	else	{
		NSError			*nsErr = nil;
		NSData			*responseData = [downloader responseData];
		if (responseData != nil)
			returnMe = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&nsErr];
	}
	//	if it's not a dictionary something went wrong, nil it out
	if (returnMe!=nil && ![returnMe isKindOfClass:[NSDictionary class]])
		returnMe = nil;
	return returnMe;
}
- (NSDictionary *) rootNode	{
	return [self jsonObjectForOSCMethodAtAddress:@"/" query:nil];
	/*
	if (webServerAddressString==nil)
		return nil;
	NSString		*queryAddress = [NSString stringWithFormat:@"http://%@:%d/",webServerAddressString,webServerPort];
	CURLDL			*downloader = [[CURLDL alloc] initWithAddress:queryAddress];
	[downloader setDNSCacheTimeout:2.];
	[downloader setConnectTimeout:2.];
	[downloader perform];
	if ([downloader err] != 0)	{
		NSLog(@"\t\terr, couldnt download: %d, %s",[downloader err],__func__);
		return nil;
	}
	NSError			*nsErr = nil;
	NSDictionary	*returnMe = [NSJSONSerialization JSONObjectWithData:[downloader responseData] options:0 error:&nsErr];
	return returnMe;
	*/
}
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath	{
	return [self jsonObjectForOSCMethodAtAddress:inPath query:nil];
}
- (NSDictionary *) jsonObjectForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString	{
	NSData			*responseData = [self _dataForOSCMethodAtAddress:inPath query:inQueryString];
	if (responseData == nil)
		return nil;
	NSError			*nsErr = nil;
	NSDictionary	*returnMe = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&nsErr];
	return returnMe;
}
- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath	{
	return [self stringForOSCMethodAtAddress:inPath query:nil];
}
- (NSString *) stringForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString	{
	NSData			*responseData = [self _dataForOSCMethodAtAddress:inPath query:inQueryString];
	if (responseData == nil)
		return nil;
	NSString		*returnMe = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	return returnMe;
}
- (NSData *) _dataForOSCMethodAtAddress:(NSString *)inPath query:(NSString *)inQueryString	{
	if (inPath == nil)
		return nil;
	NSString		*sanitizedOSCAddress = [inPath stringBySanitizingForOSCPath];
	if (sanitizedOSCAddress == nil)
		sanitizedOSCAddress = @"/";
	NSString		*queryAddress = nil;
	if (inQueryString == nil)
		queryAddress = [NSString stringWithFormat:@"http://%@:%d%@",webServerAddressString,webServerPort,sanitizedOSCAddress];
	else
		queryAddress = [NSString stringWithFormat:@"http://%@:%d%@?%@",webServerAddressString,webServerPort,sanitizedOSCAddress,inQueryString];
	queryAddress = [queryAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	//NSLog(@"\t\tqueryAddress is %@",queryAddress);
	CURLDL			*downloader = [[CURLDL alloc] initWithAddress:queryAddress];
	[downloader setDNSCacheTimeout:2.];
	[downloader setConnectTimeout:2.];
	[downloader perform];
	if ([downloader err] != 0)	{
		NSLog(@"\t\terr, couldnt download: %ld, %s",[downloader err],__func__);
		return nil;
	}
	NSData			*responseData = [downloader responseData];
	return responseData;
}


- (void) websocketSendJSONObject:(id)n	{
	//NSLog(@"%s ... %@",__func__,n);
	NSData		*tmpData = [NSJSONSerialization dataWithJSONObject:n options:0 error:nil];
	NSString	*tmpString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	//NSLog(@"\t\twill be sending %@",tmpString);
	wsClient->send(std::string([tmpString UTF8String]));
}
- (void) startListeningTo:(NSString *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n==nil)
		return;
	NSString		*tmpString = [NSString stringWithFormat:@"{ \"COMMAND\": \"LISTEN\", \"DATA\": \"%@\" }",n];
	wsClient->send(std::string([tmpString UTF8String]));
}
- (void) stopListeningTo:(NSString *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n==nil)
		return;
	NSString		*tmpString = [NSString stringWithFormat:@"{ \"COMMAND\": \"IGNORE\", \"DATA\": \"%@\" }",n];
	wsClient->send(std::string([tmpString UTF8String]));
}


- (BOOL) matchesWebIPAddress:(NSString*)inIPAddressString port:(unsigned short)inPort	{
	if (inIPAddressString == nil)
		return NO;
	if (webServerAddressString == nil)
		return NO;
	if (inPort == webServerPort && [inIPAddressString isEqualToString:webServerAddressString])
		return YES;
	return NO;
}


@end
