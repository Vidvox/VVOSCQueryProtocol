#import <Foundation/Foundation.h>
#import "ALSTrack.h"
#import "ALSTransport.h"


/*

	This object takes a .als file and creates a representation of its tracks and scenes

*/


@interface ALSProject : NSObject	{
	
	NSString		*filePath;
	NSArray			*scenes;
	NSArray			*tracks;
	ALSTrack		*masterTrack;
	ALSTrack		*prehearTrack;
	ALSTransport	*transport;
	
}

+ (id) createWithALSAtPath:(NSString *)p;
- (id) initWithALSAtPath:(NSString *)p;

@property (readonly) NSString *filePath;
@property (readonly) NSArray *tracks;
@property (readonly) NSArray *scenes;
@property (readonly) ALSTrack *masterTrack;
@property (readonly) ALSTrack *prehearTrack;
@property (readonly) ALSTransport *transport;


@end
