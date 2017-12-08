#import <Foundation/Foundation.h>
#import <VVOSC/VVOSC.h>

@class RemoteNode;


/*
switch ([n characterAtIndex:i])	{
case 'i':
	return OSCValInt;
case 'f':
	return OSCValFloat;
case 's':
case 'S':
	return OSCValString;
case 'b':
	return OSCValBlob;
case 'h':
	return OSCVal64Int;
case 't':
	return OSCValTimeTag;
case 'd':
	return OSCValDouble;
case 'c':
	return OSCValChar;
case 'r':
	return OSCValColor;
case 'm':
	return OSCValMIDI;
case 'T':
case 'F':
	return OSCValBool;
case 'N':
	return OSCValNil;
case 'I':
	return OSCValInfinity;
//case '[':			//	indicates the start of an array
//case ']':			//	indicates the end of an array
//case 'E':			//	SMPTE timecode. AD-HOC DATA TYPE! ONLY SUPPORTED BY THIS FRAMEWORK!
}
*/


/*		minimal representation of a single OSC value in an OSC type tag string for an OSC node.  
	basically, OSC nodes in the query protocol have a "type" attribute, with the type tag string- we 
	parse this string, and create one RemoteNodeControl instance for each type.  we do this because it 
	will make it easier to display a UI item for each type in the type tag string.			*/
@interface RemoteNodeControl : NSObject	{
	__weak RemoteNode		*parentNode;	//	the RemoteNode that "owns" me
	//int						index;	//	the index of this value within the parent node's type tag string
	NSString				*typeString;	//	should only be one character long
	OSCValue				*value;	//	an OSCValue with the value of the OSC node, or nil if no value was listed
	OSCValue				*min;	//	an OSCValue with the min value of the OSC node, or nil if there's no min
	OSCValue				*max;
	NSMutableArray<OSCValue*>		*vals;	//	used if the OSC node lists explicit values rather than a min/max range
}

- (id) initWithParent:(RemoteNode *)n typeString:(NSString *)t;

- (OSCValue *) createCurrentOSCValue;
- (NSString *) outlineViewIdentifier;

@property (weak) RemoteNode * parentNode;
//@property (assign) int index;
@property (strong) NSString * typeString;
@property (strong) OSCValue * value;
@property (strong) OSCValue * min;
@property (strong) OSCValue * max;
@property (strong) NSMutableArray * vals;

@end
