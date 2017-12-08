#import "VVOSCQueryServer.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <VVOSCQueryProtocol/VVOSCQuery.h>
#import <VVOSCQueryProtocol/VVOSCQueryReply.h>

#include "WSPPServer.hpp"




@interface VVOSCQueryServer ()	{
	WSPPServer			webServer;
	NSNetService		*bonjourService;
}
@end




@implementation VVOSCQueryServer


+ (void) initialize	{
	//	initialize the constants class, which will finish defining any constants if necessary
	[VVOSCQueryConstants class];
}


- (instancetype) init	{
	self = [super init];
	if (self != nil)	{
		name = nil;
		bonjourName = nil;
		delegate = nil;
		
		//	populate the web server's HTTP handler
		__weak id			bss = self;
		webServer.set_http_callback([=](const std::string & inURI)	{
			@autoreleasepool	{
				//	we need to parse the URL, breaking it up into a path and an NSDictionary of the query parameters and their values
				NSURL				*url = [NSURL URLWithString:[NSString stringWithUTF8String:inURI.c_str()]];
				NSURLComponents		*urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
				NSArray				*queryItems = [urlComponents queryItems];
				NSMutableDictionary	*urlParams = [[NSMutableDictionary alloc] init];
				BOOL				hasHostInfoQuery = NO;
				for (NSURLQueryItem *queryItem in queryItems)	{
					NSString	*tmpKey = [queryItem name];
					if (tmpKey!=nil && [tmpKey isEqualToString:kVVOSCQ_ReqAttr_HostInfo])
						hasHostInfoQuery = YES;
					id			tmpVal = [queryItem value];
					if (tmpVal == nil)
						tmpVal = [NSNull null];
					[urlParams setObject:tmpVal forKey:tmpKey];
				}
				NSArray				*urlParamKeys = [urlParams allKeys];
				//	if the URL was querying a specific key, the query isn't looking for a recursive reply...
				BOOL			isRecursive = YES;
				if (urlParamKeys!=nil && [urlParamKeys firstObjectCommonWithArray:kVVOSCQ_NonRecursiveAttrs]!=nil)
					isRecursive = NO;
			
				//	make an VVOSCQuery that describes this HTTP request
				VVOSCQuery		*query = [[VVOSCQuery alloc]
					initWithPath:[url path]
					params:(urlParams==nil || [urlParams count]<1) ? nil : urlParams
					recursive:isRecursive];
			
				//	ask the delegate to make us a reply for the query
				VVOSCQueryReply		*reply = nil;
				if (query != nil)	{
					id<VVOSCQueryServerDelegate>	localDelegate = [(VVOSCQueryServer*)bss delegate];
					if (localDelegate != nil)	{
						if (hasHostInfoQuery)
							reply = [localDelegate hostInfoQueryFromServer:bss];
						else
							reply = [localDelegate server:bss wantsReplyForQuery:query];
					}
				}
			
				//	we need to return a WSPPQueryReply instance, so create that now from the VVOSCQueryReply
				if (reply == nil)
					return WSPPQueryReply(404);	//	not found (client error)
				else	{
					NSDictionary		*replyJSONObject = [reply jsonObject];
					if (replyJSONObject == nil)	{
						//NSLog(@"\t\tno JSON object, response is going to be errCode %d",[reply errCode]);
						return WSPPQueryReply([reply errCode]);
					}
					else	{
						//NSLog(@"\t\tfound a JSON object, making a response with %@",replyJSONObject);
						NSData		*tmpData = [NSJSONSerialization dataWithJSONObject:replyJSONObject options:0 error:nil];
						return WSPPQueryReply(string([[[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding] UTF8String]));
					}
				}
			}
		});
		webServer.set_websocket_callback([=](const std::string & inRawWSString)	{
			cout << __PRETTY_FUNCTION__ << endl;
			@autoreleasepool	{
				//	we need to parse the raw string as a JSON object so we can figure out what to do with it
				NSString		*rawString = [NSString stringWithUTF8String:inRawWSString.c_str()];
				if (rawString==nil || [rawString length]<2)
					return WSPPQueryReply(400);	//	bad request (client error)
				
				NSData			*rawStringData = [rawString dataUsingEncoding:NSUTF8StringEncoding];
				if (rawStringData==nil)
					return WSPPQueryReply(400);	//	bad request (client error)
				
				id				jsonObject = nil;
				NSError			*nsErr = nil;
				@try	{
					jsonObject = [NSJSONSerialization JSONObjectWithData:rawStringData options:0 error:&nsErr];
				}
				@catch (NSException *exc)	{
					jsonObject = nil;
				}
				//	if we couldn't create a JSON object, return an err 400 (client error)
				if (jsonObject==nil)
					return WSPPQueryReply(400);	//	bad request (client error)
				
				//	if i have a delegate, ask my delegate to assemble a reply for the json object
				VVOSCQueryReply	*reply = nil;
				id<VVOSCQueryServerDelegate>	localDelegate = [(VVOSCQueryServer*)bss delegate];
				if (localDelegate != nil)
					reply = [localDelegate server:bss websocketDeliveredJSONObject:jsonObject];
				//	if my delegate doesn't have a reply (or i don't have a delegate), skip the reply
				if (reply == nil)
					return WSPPQueryReply(false);
				
				//	assemble a WSPPQueryReply for the JSON object
				id				replyJSONObject = [reply jsonObject];
				if (replyJSONObject == nil)
					return WSPPQueryReply([reply errCode]);
				else	{
					NSData			*replyData = [NSJSONSerialization dataWithJSONObject:replyJSONObject options:0 error:nil];
					NSString		*tmpString = (replyData==nil) ? nil : [[NSString alloc] initWithData:replyData encoding:NSUTF8StringEncoding];
					if (tmpString == nil)
						return WSPPQueryReply(false);
					return WSPPQueryReply(std::string([tmpString UTF8String]));
				}
			}
		});
		
		bonjourService = nil;
	}
	return self;
}
- (void) dealloc	{
	[self stop];
	bonjourService = nil;
	delegate = nil;
	bonjourName = nil;
	name = nil;
}

/*
- (void) threadedStart	{
	NSLog(@"%s",__func__);
	//	start the server
	webServer.start();
	NSLog(@"\t\t%s - FINISHED",__func__);
}
*/
- (void) start	{
	NSLog(@"%s",__func__);
	if (webServer.isRunning())
		return;
	webServer.start();
	/*
	[NSThread
		detachNewThreadSelector:@selector(threadedStart)
		toTarget:self
		withObject:nil];
	*/
	//	sleep until the server starts running...
	int			tmpCount = 0;
	while (!webServer.isRunning() && tmpCount<500)	{
		[NSThread sleepForTimeInterval:0.01];
		++tmpCount;
	}
	int			webServerPort = [self webServerPort];
	
	//	get my bonjour name- create a unique name if i haven't been given a bonjour name
	NSString		*tmpName = [self bonjourName];
	if (tmpName == nil)	{
		CFStringRef		computerName = SCDynamicStoreCopyComputerName(NULL, NULL);
		tmpName = [NSString stringWithFormat:@"%@ %d",computerName,webServerPort];
		if (computerName != nil)
			CFRelease(computerName);
	}
	//	start the bonjour server
	bonjourService = [[NSNetService alloc]
		initWithDomain:@"local."
		type:@"_oscjson._tcp."
		name:tmpName
		port:webServerPort];
	[bonjourService publish];
	
	NSLog(@"\t\tweb server running on port %d, try connecting to http://localhost:%d",webServer.getPort(),webServer.getPort());
}
- (void) startWithPort:(int)n	{
	NSLog(@"%s",__func__);
	if (webServer.isRunning())
		return;
	webServer.start(n);
	/*
	[NSThread
		detachNewThreadSelector:@selector(threadedStart)
		toTarget:self
		withObject:nil];
	*/
	//	sleep until the server starts running...
	int			tmpCount = 0;
	while (!webServer.isRunning() && tmpCount<500)	{
		[NSThread sleepForTimeInterval:0.01];
		++tmpCount;
	}
	int			webServerPort = [self webServerPort];
	
	//	get my bonjour name- create a unique name if i haven't been given a bonjour name
	NSString		*tmpName = [self bonjourName];
	if (tmpName == nil)	{
		CFStringRef		computerName = SCDynamicStoreCopyComputerName(NULL, NULL);
		tmpName = [NSString stringWithFormat:@"%@ %d",computerName,webServerPort];
		if (computerName != nil)
			CFRelease(computerName);
	}
	//	start the bonjour server
	bonjourService = [[NSNetService alloc]
		initWithDomain:@"local."
		type:@"_oscjson._tcp."
		name:tmpName
		port:webServerPort];
	[bonjourService publish];
	
	NSLog(@"\t\tweb server running on port %d, try connecting to http://localhost:%d",webServer.getPort(),webServer.getPort());
}
- (void) stop	{
	NSLog(@"%s",__func__);
	
	if (bonjourService != nil)	{
		[bonjourService stop];
		bonjourService = nil;
	}
	
	if (webServer.isRunning())	{
		webServer.stop();
		//	sleep until the server stops
		int			tmpCount = 0;
		while (webServer.isRunning() && tmpCount<500)	{
			[NSThread sleepForTimeInterval:0.01];
			++tmpCount;
		}
	}
}
- (BOOL) isRunning	{
	return webServer.isRunning();
}


- (int) webServerPort	{
	return webServer.getPort();
}
@synthesize name;
@synthesize bonjourName;
@synthesize delegate;

/*
- (void) sendPathChangedNotificationToClients:(NSString *)changedPath	{
	if (changedPath == nil)
		return;
	//webServer.sendPathChangedNotification(std::string([changedPath UTF8String]));
	NSDictionary		*tmpJSONObj = @{ kVVOSCQ_WSAttr_Cmd_PathChanged : changedPath };
	[self sendJSONObjectToClients:tmpJSONObj];
	
	NSData				*tmpJSONData = [NSJSONSerialization dataWithJSONObject:tmpJSONObj];
	std::string			tmpString([tmpJSONData bytes]);
	webServer.sendStringToClients(tmpString);
}
*/
- (void) sendJSONObjectToClients:(NSDictionary *)anObj	{
	if (anObj == nil || ![anObj isKindOfClass:[NSDictionary class]])
		return;
	NSData			*tmpData = [NSJSONSerialization dataWithJSONObject:anObj options:0 error:nil];
	NSString		*tmpNSString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	//std::string			tmpString((char*)[tmpData bytes]);
	std::string			tmpString([tmpNSString UTF8String]);
	webServer.sendStringToClients(tmpString);
	/*
	NSString		*stringToSend = (tmpData==nil) ? nil : [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	if (stringToSend == nil)
		return;
	webServer.sendStringToClients(std::string([stringToSend UTF8String]));
	*/
}

/*
- (void)webServerDidStart:(GCDWebServer*)server;
- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server;
- (void)webServerDidUpdateNATPortMapping:(GCDWebServer*)server;
- (void)webServerDidConnect:(GCDWebServer*)server;
- (void)webServerDidDisconnect:(GCDWebServer*)server;
- (void)webServerDidStop:(GCDWebServer*)server;
*/


@end
