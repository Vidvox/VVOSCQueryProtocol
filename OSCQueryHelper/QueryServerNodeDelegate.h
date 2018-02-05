#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>
#import "VVOSCQueryServer.h"


/*		this class exists to bridge an OSC library (VVOSC.framework) with an OSC query library
	(VVOSCQueryProtocol.framework).  instances of this class are created by software that wants to
	connect the query server with an OSC address space- these instances are registered as delegates
	of OSCNodes in the OSC address space.  when the nodes receive messages, these instances pass
	those messages to the query server that created them.		*/


@interface QueryServerNodeDelegate : NSObject <OSCNodeDelegateProtocol>	{
	__weak VVOSCQueryServer		*queryServer;
	NSString				*address;
}

- (id) initWithQueryServer:(VVOSCQueryServer *)n forAddress:(NSString *)a;

@property (weak) VVOSCQueryServer *queryServer;
@property (strong) NSString * address;

@end

