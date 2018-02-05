#import <Foundation/Foundation.h>
#import "VVOSCQueryConstants.h"


/*	instances of this class represent replies to individual queries made to the server.  basically 
	a simple data structure class.
	
	the VVOSCQueryServerDelegate protocol requires you to create instances of this class in reply to 
	VVOSCQuery instances.  since the OSC query spec responds to pretty much everything using JSON blobs, 
	this is a very simple class- either it has a JSON object to send, or it doesn't, in which case 
	its error code will be returned as an HTML response code.
	
	this class has a class method that greatly simplifies the process of creating JSON objects 
	with the necessary data.  "JSON objects" are really just dictionaries/arrays/numbers/strings/etc.		*/


@interface VVOSCQueryReply : NSObject	{
	NSDictionary		*jsonObject;	//	the OSC query protocol uses JSON blobs to reply to queries
	int					errCode;	//	if jsonObject is nil, this errCode will be sent as an HTTP response
}

//	this class method can be used to create the json object you require to create an instance of this class.
+ (NSDictionary *) jsonObjectWithPath:(NSString *)inFullPath	//	full path to this node in the OSC address space
	contents:(NSArray<NSDictionary*>*)inContents	//	subnodes (may be a hierarchy)
	description:(NSString *)inDescription	//	human-readable string describing this node
	tags:(NSArray<NSString*> *)inTags	//	array of human-readable strings describing this node, intended to facilitate search or filtering
	extendedType:(NSArray<NSString*> *)inExtType
	type:(NSString *)inTypeTagString	//	the OSC type tag string for this node
	access:(VVOSCQueryNodeAccess)inAccess	//	mask that defines whether the values for this node may be read or written
	value:(NSArray *)inValueArray
	range:(NSArray *)inRangeArray
	clipmode:(NSArray *)inClipmodeArray	//	nil by default.  if non-nil, must be an array consisting only of instances of the kVVOSCQueryNodeClipMode* constants above.
	units:(NSArray *)inUnitsArray
	critical:(BOOL)inCritical;	//	NO by default.  if YES, try to use a TCP connection to send data to this node.

- (instancetype) initWithJSONObject:(NSDictionary *)jo;
- (instancetype) initWithErrorCode:(int)ec;

@property (readonly,nonatomic) NSDictionary * jsonObject;
@property (readonly,nonatomic) int errCode;

@end
