#import <Foundation/Foundation.h>

@class RemoteNodeControl;

/*		minimal representation of an OSC node on a remote server.  has a weak ref to the parent node 
		so the hierarchy may be traversed, a 'contents' array with sub-nodes, and a copy of the raw 
		dict received from the remote server.  has convenience methods for returning the # of values 
		this node expects to aid in creation of the UI.		*/
@interface RemoteNode : NSObject	{
	__weak RemoteNode		*parentNode;	//	my parent node, or nil
	NSDictionary			*dict;	//	the dict that i was created from
	NSMutableArray<RemoteNodeControl*>	*controls;
	NSMutableArray<RemoteNode*>			*contents;	//	any sub-nodes within me
}

- (id) initWithParent:(RemoteNode *)p dict:(NSDictionary *)d;

- (NSString *) typeString;
- (int) controlCount;
- (int) contentsCount;
- (NSString *) name;
- (NSString *) fullPath;
- (NSString *) oscDescription;

- (void) sendMessage;
- (NSString *) outlineViewIdentifier;
- (NSUInteger) indexOfControl:(RemoteNodeControl*)n;

@property (readonly,weak) RemoteNode * parentNode;
@property (readonly,nonatomic) NSDictionary * dict;
@property (readonly) NSMutableArray<RemoteNodeControl*> * controls;
@property (readonly) NSMutableArray<RemoteNode*> * contents;

@end
