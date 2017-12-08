#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <VVOSC/VVOSC.h>




typedef NS_ENUM(NSInteger, OSCValueViewHint)	{
	OSCValueViewHint_None = 0,
	OSCValueViewHint_Slider = 0x01,
	OSCValueViewHint_PUB = 0x02
};




@interface OSCValueView : NSView	{
	OSCValueType			type;
	OSCValue				*value;
	OSCValueViewHint		hint;
	//void (^)(OSCValue *newValue)	actionBlock;
	void					(^actionBlock)(OSCValue *newOSCValue);
	
	IBOutlet NSTextField		*textField;
	IBOutlet NSColorWell		*colorWell;
	IBOutlet NSPopUpButton		*popUpButton;
	IBOutlet NSSlider			*slider;
	IBOutlet NSButton			*button;
	IBOutlet NSTextField		*labelField;
}

//- (void) setType:(OSCValueType)t value:(OSCValue *)v;
- (void) setType:(OSCValueType)t value:(OSCValue *)v hint:(OSCValueViewHint)h valsArray:(NSArray<OSCValue*>*)vals;

@property (readonly) OSCValue * value;
@property (readonly) OSCValueViewHint hint;
//@property (strong) (void ^(OSCValue *newValue) actionBlock;
@property (strong) void (^actionBlock)(OSCValue *newOSCValue);

- (BOOL) hasHint:(OSCValueViewHint)n;

- (IBAction) textFieldUsed:(id)sender;
- (IBAction) colorWellUsed:(id)sender;
- (IBAction) popUpButtonUsed:(id)sender;
- (IBAction) sliderUsed:(id)sender;
- (IBAction) buttonUsed:(id)sender;

- (NSTextField *) textField;
- (NSColorWell *) colorWell;
- (NSPopUpButton *) popUpButton;
- (NSSlider *) slider;
- (NSButton *) button;
- (NSTextField *) labelField;

@end
