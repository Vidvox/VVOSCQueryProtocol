#import "LiveToOSCQHelper.h"

@interface LiveToOSCQHelper ()

//	handles parsing an entire ALS file from its base components
+ (NSDictionary *) _oscqDictForALSProject:(ALSProject *)p withBasePath:(NSString *)bp;

//	handlers for specific high level parts of an ALS file
+ (NSDictionary *) _oscqDictForALSScene:(ALSScene *)s withBasePath:(NSString *)bp;
+ (NSDictionary *) _oscqDictForALSTrack:(ALSTrack *)t withBasePath:(NSString *)bp;
+ (NSDictionary *) _oscqDictForALSClipSlot:(ALSClipSlot *)cs withBasePath:(NSString *)bp;
+ (NSDictionary *) _oscqDictForALSDevice:(ALSDevice *)d withBasePath:(NSString *)bp;

//	handlers for working with generic ALS parameters (used by mixers, devices, tranport)
+ (NSDictionary *) _oscqDictForALSParameterList:(NSArray *)pl withBasePath:(NSString *)bp ofType:(NSString *)dt;
+ (NSDictionary *) _oscqDictForALSParameter:(ALSParameter *)p withBasePath:(NSString *)bp ofType:(NSString *)dt;

//	this is a handy method that returns a mutable dictionary for a group node
+ (NSDictionary *) _oscqDictForGenericGroupNodeWithContents:(NSDictionary *)c andFullPath:(NSString *)fp;
@end

@implementation LiveToOSCQHelper

+ (NSDictionary *) OSCQueryJSONObjectForLiveProject:(NSString *)pathToProject	{
	ALSProject		*tmpProj = [[ALSProject alloc] initWithALSAtPath:pathToProject];
	if (tmpProj == nil)
		return nil;
	return [self _oscqDictForALSProject:tmpProj withBasePath:nil];
}
/*
+ (NSString *) oscqJSONStringForALSProject:(ALSProject *)p	{
	if (p == nil)
		return nil;
	NSError			*nsErr = nil;
	NSDictionary	*tmpDict = [LiveToOSCQHelper _oscqDictForALSProject:p withBasePath:nil];
	if ((tmpDict == nil)||([tmpDict count]<1))
		return nil;
	//NSData			*tmpData = [NSJSONSerialization dataWithJSONObject:tmpDict options:0 error:&nsErr];
	NSData					*tmpData = [NSJSONSerialization dataWithJSONObject:tmpDict options:NSJSONWritingPrettyPrinted error:&nsErr];
	if ((tmpData == nil || [tmpData length]<1))	{
		NSLog(@"\t\terr, %s: %@.  %@",__func__,nsErr,self);
	}
	NSString		*returnMe = (tmpData==nil) ? nil : [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	return returnMe;
}
+ (NSDictionary *) oscToMIDIMappingsForALSProject:(ALSProject *)p	{
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	NSDictionary			*oscqDict = [LiveToOSCQHelper _oscqDictForALSProject:p withBasePath:nil];
	if (oscqDict != nil)	{
		//	recursively go through the oscqDict and for anything that contains MIDI_CHANNEL add it to return me with FULL_PATH as its key
		__block __weak void		(^FindKeyMIDI)(NSDictionary *);
		FindKeyMIDI = ^(NSDictionary * baseNode)	{
			//NSLog(@"\t\tsearching %@",[baseNode objectForKey:@"FULL_PATH"]);
			NSNumber		*channel = [baseNode objectForKey:@"MIDI_CHANNEL"];
			if (channel != nil)	{
				NSString		*fp = [baseNode objectForKey:@"FULL_PATH"];
				if (fp != nil)	{
					[returnMe setObject:baseNode forKey:fp];
				}
			}
			else	{
				NSDictionary			*baseContents = [baseNode objectForKey:@"CONTENTS"];
				if (baseContents != nil)	{
					for (NSDictionary *subDict in [baseContents allValues])	{
						FindKeyMIDI(subDict);
					}
				}
			}
		};
		FindKeyMIDI(oscqDict);
	}
	return returnMe;
}
*/

+ (NSDictionary *) _oscqDictForALSProject:(ALSProject *)p withBasePath:(NSString *)bp	{
	if (p == nil)
		return nil;
	NSString				*rootPath = (bp == nil) ? @"/" : bp;
	NSMutableDictionary		*rootContents = [NSMutableDictionary dictionaryWithCapacity:0];
	
	//	create sub-dicts for transport, scenes, tracks, masterTrack, prehearTrack

	//	do the transport
	ALSTransport			*transport = [p transport];
	if (transport != nil)	{
		NSArray				*pl = [transport parameterList];
		if (pl != nil)	{
			NSString			*transportPath  = [NSString stringWithFormat:@"%@Transport/",rootPath];
			NSDictionary		*transportDict = [LiveToOSCQHelper _oscqDictForALSParameterList:pl withBasePath:transportPath ofType:@"T"];
			if (transportDict != nil)	{
				[rootContents setObject:transportDict forKey:transportPath];
			}
		}
	}
	
	//	do the scenes
	NSArray					*scenes = [p scenes];
	if (scenes != nil)	{
		NSMutableDictionary		*scenesContents = [NSMutableDictionary dictionaryWithCapacity:0];
		NSString				*scenesPath  = [NSString stringWithFormat:@"%@Scenes/",rootPath];
		for (ALSScene *scene in scenes)	{
			NSDictionary		*tmpDict = [LiveToOSCQHelper _oscqDictForALSScene:scene withBasePath:scenesPath];
			if (tmpDict != nil)	{
				NSString		*fp = [tmpDict objectForKey:@"FULL_PATH"];
				if (fp != nil)	{
					[scenesContents setObject:tmpDict forKey:fp];
				}
			}
		}
		if ([scenesContents count] > 0)	{
			NSDictionary			*scenesDict = [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:scenesContents andFullPath:scenesPath];
			[rootContents setObject:scenesDict forKey:scenesPath];
		}
	}
	
	//	do the tracks
	ALSTrack					*masterTrack = [p masterTrack];
	if (masterTrack != nil)	{
		NSString				*mtPath  = [NSString stringWithFormat:@"%@MasterTrack/",rootPath];
		NSDictionary			*mtDict = [LiveToOSCQHelper _oscqDictForALSTrack:masterTrack withBasePath:rootPath];
		if (mtDict != nil)	{
			[rootContents setObject:mtDict forKey:mtPath];
		}
	}
	
	ALSTrack					*prehearTrack = [p prehearTrack];
	if (prehearTrack != nil)	{
		NSString				*phPath  = [NSString stringWithFormat:@"%@PrehearTrack/",rootPath];
		NSDictionary			*phDict = [LiveToOSCQHelper _oscqDictForALSTrack:prehearTrack withBasePath:rootPath];
		if (phDict != nil)	{
			[rootContents setObject:phDict forKey:phPath];
		}
	}
	
	NSArray						*tracks = [p tracks];
	if (tracks != nil)	{
		NSMutableDictionary		*tracksContents = [NSMutableDictionary dictionaryWithCapacity:0];
		NSString				*tracksPath  = [NSString stringWithFormat:@"%@Tracks/",rootPath];
		for (ALSTrack *track in tracks)	{
			NSDictionary		*tmpDict = [LiveToOSCQHelper _oscqDictForALSTrack:track withBasePath:tracksPath];
			if (tmpDict != nil)	{
				NSString		*fp = [tmpDict objectForKey:@"FULL_PATH"];
				if (fp != nil)	{
					[tracksContents setObject:tmpDict forKey:fp];
				}
			}
		}
		NSDictionary			*tractsDict = [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:tracksContents andFullPath:tracksPath];
		[rootContents setObject:tractsDict forKey:tracksPath];
	}
	
	return [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:rootContents andFullPath:rootPath];
}
+ (NSDictionary *) _oscqDictForALSScene:(ALSScene *)s withBasePath:(NSString *)bp	{
	if (s == nil)
		return nil;
	//	check to make sure there is a key midi and its channel is not -1
	//		otherwise we ignore this scene for OSC+Q
	ALSKeyMidi				*km = [s keyMidi];
	if ((km == nil)||([km channel] == -1))	{
		return nil;
	}
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	NSString				*basePath = (bp == nil) ? @"/Scenes/" : bp;
	NSString				*sceneName = [s title];
	NSString				*sceneUserName = [s userTitle];
	NSString				*scenePath = [NSString stringWithFormat:@"%@%@",basePath,sceneName];
	NSString				*sceneDescription = [NSString stringWithFormat:@"Trigger scene '%@'",sceneUserName];
	[returnMe setValue:(([km isNote]) ? @"NOTE" : @"CC") forKey:@"MIDI_TYPE"];
	[returnMe setValue:[NSNumber numberWithInt:[km noteOrControllerNumber]] forKey:@"MIDI_VOICE"];
	[returnMe setValue:[NSNumber numberWithInt:[km channel]] forKey:@"MIDI_CHANNEL"];
	[returnMe setValue:scenePath forKey:@"FULL_PATH"];
	[returnMe setObject:sceneDescription forKey:@"DESCRIPTION"];
	[returnMe setObject:@"T" forKey:@"TYPE"];
	[returnMe setObject:[NSNumber numberWithInt:2] forKey:@"ACCESS"];
	return returnMe;
}
+ (NSDictionary *) _oscqDictForALSTrack:(ALSTrack *)t withBasePath:(NSString *)bp	{
	if (t == nil)
		return nil;
	NSMutableDictionary		*tContentsDict = [NSMutableDictionary dictionaryWithCapacity:0];
	NSString				*trackName = [t title];
	NSString				*basePath = (bp == nil) ? @"/Tracks/" : bp;
	NSString				*trackPath = [NSString stringWithFormat:@"%@%@/",basePath,trackName];
	//	for each track there is
	//		mixer (contains list of parameters)
	//		clip list (contains array of clipslots, each with a title / keymidi)
	//		device chain (contains array of devices, each with a list of parameters)
	ALSMixer				*tMixer = [t mixer];
	if (tMixer != nil)	{
		NSString			*mixBasePath = [NSString stringWithFormat:@"%@Mixer/",trackPath];
		NSArray				*mixParams = [tMixer parameterList];
		if (mixParams != nil)	{
			NSDictionary	*mixDict = [LiveToOSCQHelper _oscqDictForALSParameterList:mixParams withBasePath:mixBasePath ofType:@"f"];
			if (mixDict != nil)	{
				[tContentsDict setObject:mixDict forKey:mixBasePath];
			}
		}
	}
	NSArray					*csl = [t clipSlotList];
	if (csl != nil)	{
		NSMutableDictionary	*csContentsDict = [NSMutableDictionary dictionaryWithCapacity:0];
		NSString			*csBasePath = [NSString stringWithFormat:@"%@ClipSlotList/",trackPath];
		for (ALSClipSlot *cs in csl)	{
			NSDictionary	*tmpDict = [LiveToOSCQHelper _oscqDictForALSClipSlot:cs withBasePath:trackPath];
			if (tmpDict != nil)	{
				NSString		*fp = [tmpDict objectForKey:@"FULL_PATH"];
				if (fp != nil)	{
					[csContentsDict setObject:tmpDict forKey:fp];
				}
			}
		}
		if ([csContentsDict count] > 0)	{
			NSDictionary	*csDict = [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:csContentsDict andFullPath:csBasePath];
			[tContentsDict setObject:csDict forKey:csBasePath];
		}
	}
	ALSDeviceChain				*tdc = [t deviceChain];
	if (tdc != nil)	{
		NSArray					*tDevices = [tdc devices];
		NSMutableDictionary		*tdContentsDict = [NSMutableDictionary dictionaryWithCapacity:0];
		NSString				*devBasePath = [NSString stringWithFormat:@"%@Devices/",trackPath];
		if (tDevices != nil)	{
			for (ALSDevice *dev in tDevices)	{
				NSDictionary	*tmpDict = [LiveToOSCQHelper _oscqDictForALSDevice:dev withBasePath:devBasePath];
				if (tmpDict != nil)	{
					NSString		*fp = [tmpDict objectForKey:@"FULL_PATH"];
					if (fp != nil)	{
						[tdContentsDict setObject:tmpDict forKey:fp];
					}
				}
			}
		}
		if ([tdContentsDict count] > 0)	{
			NSDictionary	*tdDict = [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:tdContentsDict andFullPath:devBasePath];
			[tContentsDict setObject:tdDict forKey:devBasePath];
		}
	}
	if ([tContentsDict count] == 0)
		return nil;
	return [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:tContentsDict andFullPath:trackPath];
}
+ (NSDictionary *) _oscqDictForALSClipSlot:(ALSClipSlot *)cs withBasePath:(NSString *)bp	{
	if (cs == nil)
		return nil;
	//	check to make sure there is a key midi and its channel is not -1
	//		otherwise we ignore this scene for OSC+Q
	ALSKeyMidi				*km = [cs keyMidi];
	if ((km == nil)||([km channel] == -1))	{
		return nil;
	}
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	NSString				*parentName = (bp == nil) ? @"Unknown Track" : [bp lastPathComponent];
	NSString				*basePath = (bp == nil) ? @"/ClipSlotList/" : bp;
	NSString				*csName = [cs title];
	NSString				*csUserTitle = [cs userTitle];
	NSString				*csPath = [NSString stringWithFormat:@"%@ClipSlotList/%@",basePath,csName];
	NSString				*csDescription = [NSString stringWithFormat:@"Trigger '%@' on %@",csUserTitle,parentName];
	[returnMe setValue:(([km isNote]) ? @"NOTE" : @"CC") forKey:@"MIDI_TYPE"];
	[returnMe setValue:[NSNumber numberWithInt:[km noteOrControllerNumber]] forKey:@"MIDI_VOICE"];
	[returnMe setValue:[NSNumber numberWithInt:[km channel]] forKey:@"MIDI_CHANNEL"];
	[returnMe setValue:csPath forKey:@"FULL_PATH"];
	[returnMe setObject:csDescription forKey:@"DESCRIPTION"];
	[returnMe setObject:@"T" forKey:@"TYPE"];
	[returnMe setObject:[NSNumber numberWithInt:2] forKey:@"ACCESS"];
	return returnMe;
}
+ (NSDictionary *) _oscqDictForALSDevice:(ALSDevice *)d withBasePath:(NSString *)bp	{
	if (d == nil)
		return nil;
	NSString				*basePath = (bp == nil) ? @"/Devices/" : bp;
	NSString				*devName = [d userName];
	if (devName == nil)
		devName = [d deviceName];
	NSString				*devPath = [NSString stringWithFormat:@"%@%@/",basePath,devName];
	NSArray					*pl = [d parameterList];
	return [LiveToOSCQHelper _oscqDictForALSParameterList:pl withBasePath:devPath ofType:@"f"];
}
+ (NSDictionary *) _oscqDictForALSParameterList:(NSArray *)pl withBasePath:(NSString *)bp ofType:(NSString *)dt	{
	if (pl == nil)
		return nil;
	NSMutableDictionary		*plContentsDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (ALSParameter *p in pl)	{
		NSDictionary		*pDict = [LiveToOSCQHelper _oscqDictForALSParameter:p withBasePath:bp ofType:dt];
		if (pDict != nil)	{
			NSString		*fp = [pDict objectForKey:@"FULL_PATH"];
			if (fp != nil)	{
				[plContentsDict setObject:pDict forKey:fp];
			}
		}
	}
	if ([plContentsDict count] == 0)
		return nil;
	return [LiveToOSCQHelper _oscqDictForGenericGroupNodeWithContents:plContentsDict andFullPath:bp];
}
+ (NSDictionary *) _oscqDictForALSParameter:(ALSParameter *)p withBasePath:(NSString *)bp ofType:(NSString *)dt	{
	if ((p == nil)||(bp == nil))
		return nil;
	ALSKeyMidi				*km = [p keyMidi];
	if ((km == nil)||([km channel] == -1))	{
		//NSLog(@"\t\tno midi for %@",[s title]);
		return nil;
	}
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	NSString				*basePath = (bp == nil) ? @"/Parameters/" : bp;
	NSString				*paramName = [p title];
	NSString				*paramPath = [NSString stringWithFormat:@"%@%@",basePath,paramName];
	NSString				*dataType = (dt == nil) ? @"f" : dt;
	NSString				*paramAction = ([dataType isEqualToString:@"T"]) ? @"Trigger" : @"Adjust";
	NSString				*paramDescription = [NSString stringWithFormat:@"%@ %@",paramAction,paramName];

	[returnMe setValue:(([km isNote]) ? @"NOTE" : @"CC") forKey:@"MIDI_TYPE"];
	[returnMe setValue:[NSNumber numberWithInt:[km noteOrControllerNumber]] forKey:@"MIDI_VOICE"];
	[returnMe setValue:[NSNumber numberWithInt:[km channel]] forKey:@"MIDI_CHANNEL"];
	[returnMe setValue:paramPath forKey:@"FULL_PATH"];
	[returnMe setObject:paramDescription forKey:@"DESCRIPTION"];
	[returnMe setObject:dataType forKey:@"TYPE"];
	[returnMe setObject:[NSNumber numberWithInt:2] forKey:@"ACCESS"];
	if ([dataType isEqualToString:@"f"])	{
		NSDictionary	*rangeDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.0],@"MIN",[NSNumber numberWithFloat:1.0],@"MAX",nil];
		[returnMe setObject:[NSArray arrayWithObject:rangeDict] forKey:@"RANGE"];
	}
	else if ([dataType isEqualToString:@"i"])	{
		NSDictionary	*rangeDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"MIN",[NSNumber numberWithInt:127],@"MAX",nil];
		[returnMe setObject:[NSArray arrayWithObject:rangeDict] forKey:@"RANGE"];
	}
	return returnMe;
}
+ (NSDictionary *) _oscqDictForGenericGroupNodeWithContents:(NSDictionary *)c andFullPath:(NSString *)fp	{
	if ((c == nil)||(fp == nil))
		return nil;
	NSMutableDictionary		*returnMe = [NSMutableDictionary dictionaryWithCapacity:0];
	[returnMe setObject:fp forKey:@"FULL_PATH"];
	[returnMe setObject:[NSNumber numberWithInt:0] forKey:@"ACCESS"];
	[returnMe setObject:c forKey:@"CONTENTS"];
	return returnMe;
}

@end
