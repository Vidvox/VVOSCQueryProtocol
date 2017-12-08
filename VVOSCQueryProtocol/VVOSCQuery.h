#import <Foundation/Foundation.h>


/*	instances of this class represent individual queries made to the server.  mainly used by 
	the VVOSCQueryServerDelegate protocol.  basically a simple data structure class.			*/


@interface VVOSCQuery : NSObject	{
	NSString		*path;	//	the OSC address path that's being queried
	NSDictionary	*params;	//	nil by default/most of the time.  the OSC query spec includes a way of querying specific attributes- this dictionary is how those queries are conveyed to you, the person implementing this query protocol on top of an existing address space
	BOOL			recursive;	//	defaults to NO, but most queries will likely be recursive.  if NO, then the contents (the sub-nodes) of the OSC node corresponding to 'path' can be omitted from any replies for this request.  this will probably be 'NO' most commonly when the query is for a specific attribute of an OSC endpoint.
}

- (instancetype) initWithPath:(NSString *)p params:(NSDictionary *)q recursive:(BOOL)r;

@property (readonly) NSString * path;
@property (readonly) NSDictionary * params;
@property (readonly) BOOL recursive;

@end
