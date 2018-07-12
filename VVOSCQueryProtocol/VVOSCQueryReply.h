#import <Foundation/Foundation.h>
#import "VVOSCQueryConstants.h"


/**
This is a relatively simple data structure class that represents a reply to an individual query made to the server.  The VVOSCQueryServerDelegate protocol requires you to create instances of this class in reply to VVOSCQuery instances.  Since the OSCQuery spec responds to pretty much everything using JSON objects, this is a very simple class- either it has a JSON object to send in reply, or it doesn't (in which case its error code will be returned as an HTML response code).

This class has a class method that greatly simplifies the process of creating fully-formed JSON objects with the necessary data for common queries.
*/

@interface VVOSCQueryReply : NSObject	{
	NSDictionary		*jsonObject;	//	the OSCQuery spec uses JSON blobs to reply to queries
	int					errCode;	//	if jsonObject is nil, this errCode will be sent as an HTTP response
}

///	This class method can be used to create the JSON object you require to create an instance of this class.
/**
This class method is a simple and convenient way to create a fully-formed JSON object that describes an OSC node in an OSC address space in accordance with the OSCQuery spec.  The documentation for this method references the spec repeatedly, which can be found here: https://github.com/Vidvox/OSCQueryProposal
@param inFullPath The full path to this node in the OSC address space (FULL_PATH from the spec).
@param inContents The contents (sub-nodes) of the OSC node we're describing.  This can be a fully-formed hierarchy (this method may be called recursively to "build up" a JSON object to return).  This is the value associated with CONTENTS from the spec.
@param inDescription A human-readable string describing this node (DESCRIPTION from the spec)
@param inTags An array of human-readable strings describing this node, intended to facilitate search or filtering (TAGS from the spec)
@param inExtType A human-readable string that describes what the OSC node's value means/what the value does (for more information, see EXTENDED_TYPE in the spec)
@param inTypeTagString The OSC type tag string for this node (eg. "f", "i", "ssfi", "s[iii]f", etc). (TYPE from the spec)
@param inAccess Access mask that defines whether the values for this node may be read or written (ACCESS from the spec).  Pass VVOSCQueryNodeAccess_RW if you're not sure what to use.
@param inValueArray nil, or an array that describes the value of the node- the type and value of its contents depends on the OSC node's type tag string.  Please consult the spec, which fully describes how to properly make use of the VALUE attribute.
@param inRangeArray nil, or an array that describes the range of values accepted by the node- the type and value of its contents depends on the OSC node's type tag string.  Please consult the spec, which fully describes how to properly make use of the RANGE attribute.
@param inClipmodeArray nil, or an array consisting only of instances of the kVVOSCQueryNodeClipMode* constants (kVVOSCQueryNodeClipModeNone, kVVOSCQueryNodeClipModeLow, etc)
@param inUnitsArray nil, or an array that describes the units of the node- the type and structure of its contents depends on the OSC node's type tag string.  Please consult the spec, which fully describes how to properly make use of the UNITS attribute.
@param inCritical NO by default.  If YES, try to use a TCP connection to send data to this node, as messages to it are considered critical.
@param inOverloadsArray  nil, or an array that describes the overloads (alternate type tag strings) that this node responds to.  The type and structure of this array's contents depend on the overload's type tag string- please consult the spec, which fully describes how to properly make use of the OVERLOADS attribute.
*/
#if __has_feature(objc_arc)
+ (NSDictionary *) jsonObjectWithPath:(NSString *)inFullPath
	contents:(NSDictionary*)inContents
	description:(NSString *)inDescription
	tags:(NSArray<NSString*> *)inTags
	extendedType:(NSArray<NSString*> *)inExtType
	type:(NSString *)inTypeTagString
	access:(VVOSCQueryNodeAccess)inAccess
	value:(NSArray *)inValueArray
	range:(NSArray *)inRangeArray
	clipmode:(NSArray *)inClipmodeArray
	units:(NSArray *)inUnitsArray
	critical:(BOOL)inCritical
	overloads:(NSArray*)inOverloadsArray;
#else
+ (NSDictionary *) jsonObjectWithPath:(NSString *)inFullPath
	contents:(NSDictionary*)inContents
	description:(NSString *)inDescription
	tags:(NSArray *)inTags
	extendedType:(NSArray *)inExtType
	type:(NSString *)inTypeTagString
	access:(VVOSCQueryNodeAccess)inAccess
	value:(NSArray *)inValueArray
	range:(NSArray *)inRangeArray
	clipmode:(NSArray *)inClipmodeArray
	units:(NSArray *)inUnitsArray
	critical:(BOOL)inCritical
	overloads:(NSArray*)inOverloadsArray;
#endif

/// Returns an instance of VVOSCQueryReply that will return a JSON object.  If you're constructing a reply in response to a standard query, this is the method you should use.
- (instancetype) initWithJSONObject:(NSDictionary *)jo;
/// Returns an instance of VVOSCQueryReply that will return an HTML error code (the passed value will be returned).
- (instancetype) initWithErrorCode:(int)ec;

/// Returns nil, or the JSON object that the receiver was constructed with.
@property (readonly,nonatomic) NSDictionary * jsonObject;
///	Returns 0, or the error code that the receiver was constructed with.
@property (readonly,nonatomic) int errCode;

@end
