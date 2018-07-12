#import <Foundation/Foundation.h>


/**
This is a relatively simple data structure class that represents a single OSC query received by the server.  You will never have to create an instance of this class yourself- instances are created by the VVOSCQueryServer, and passed to its delegates in various methods from the VVOSCQueryServerDelegate protocol.
*/
@interface VVOSCQuery : NSObject	{
	NSString		*path;
	NSDictionary	*params;
	BOOL			recursive;
}
- (instancetype) initWithPath:(NSString *)p params:(NSDictionary *)q recursive:(BOOL)r;

/// The OSC address path that's being queried
@property (readonly) NSString * path;
/// nil by default/most of the time.  the OSCQuery spec includes a way of querying specific attributes- this dictionary is how those queries are conveyed to you, the person implementing the OSCQuery spec on top of an existing address space.
@property (readonly) NSDictionary * params;
/// Defaults to NO, but most queries will likely be recursive.  if NO, then the contents (the sub-nodes) of the OSC node corresponding to 'path' can be omitted from any replies for this request.  this will probably be 'NO' most commonly when the query is for a specific attribute of an OSC endpoint.
@property (readonly) BOOL recursive;

@end
