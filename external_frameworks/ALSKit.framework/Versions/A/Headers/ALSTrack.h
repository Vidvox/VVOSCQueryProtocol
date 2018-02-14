#import <Foundation/Foundation.h>
#import "ALSMixer.h"
#import "ALSDeviceChain.h"

@interface ALSTrack : NSObject	{

	NSString			*title;
	ALSMixer			*mixer;
	ALSDeviceChain		*deviceChain;
	NSArray				*clipSlotList;

}

+ (id) createWithXMLElement:(NSXMLElement *)xml;
- (id) initWithXMLElement:(NSXMLElement *)xml;

@property (readonly) NSString *title;
@property (readonly) ALSMixer *mixer;
@property (readonly) ALSDeviceChain *deviceChain;
@property (readonly) NSArray *clipSlotList;

@end
