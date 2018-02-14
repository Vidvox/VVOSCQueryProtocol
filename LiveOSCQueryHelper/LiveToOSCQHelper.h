#import <Foundation/Foundation.h>
#import <ALSKit/ALSKit.h>

@interface LiveToOSCQHelper : NSObject

+ (NSDictionary *) OSCQueryJSONObjectForLiveProject:(NSString *)pathToProject;

//	this returns a JSON string that contains OSC Query protocol formatted info for a given Ableton Live Set
//	(use this to publish an OSC+Q namespace)
//+ (NSString *) oscqJSONStringForALSProject:(ALSProject *)p;
//	this returns a dictionary where each key is an OSC address and for each key provides a dict with the MIDI mapping
//	(easier to work with than a nested dictionary, you can use this to map incoming OSC paths to their corresponding MIDI outputs)
//+ (NSDictionary *) oscToMIDIMappingsForALSProject:(ALSProject *)p;

@end
