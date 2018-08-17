#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>




//	these class additions simplify the process of using the OSC query protocol framework with VVOSC
@interface OSCNode (VVOSCQueryNodeAdditions)

+ (void) setFlattenSimpleOSCQArrays:(BOOL)n;
+ (BOOL) flattenSimpleOSCQArrays;
//	runs through contents of passed array (recursively if there are sub-arrays).  checks the objects in each array to see if they are equal- if they aren't, it returns nil.  if they are equal, it returns a single instance of the object.
+ (id) flattenEquivalentArrayContentsToSingleVal:(NSArray *)n;

- (VVOSCQueryReply *) getReplyForOSCQuery:(VVOSCQuery *)q;
- (NSMutableDictionary *) createJSONObjectForOSCQuery;
- (NSMutableDictionary *) createJSONObjectForOSCQueryRecursively:(BOOL)isRecursive;

@end
