#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>
#import <VVOSCQueryProtocol/VVOSCQueryProtocol.h>




//	these class additions simplify the process of using the OSC query protocol framework with VVOSC
@interface OSCNode (VVOSCQueryNodeAdditions)

+ (void) setFlattenSimpleOSCQArrays:(BOOL)n;
+ (BOOL) flattenSimpleOSCQArrays;

- (VVOSCQueryReply *) getReplyForOSCQuery:(VVOSCQuery *)q;
- (NSMutableDictionary *) createJSONObjectForOSCQuery;
- (NSMutableDictionary *) createJSONObjectForOSCQueryRecursively:(BOOL)isRecursive;

@end
