#import "OSCValueView.h"
#import <VVOSC/VVOSC.h>




@interface OSCValueView ()
- (void) generalInit;
- (void) updateUIItems;	//	shows/hides UI items based on the hint
@property (assign) OSCValueType type;
@property (strong) OSCValue * value;
@property (assign) OSCValueViewHint hint;
@end




@implementation OSCValueView


- (instancetype) initWithFrame:(NSRect)r	{
	self = [super initWithFrame:r];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder*)c	{
	self = [super initWithCoder:c];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
@synthesize type;
@synthesize value;
@synthesize hint;
@synthesize actionBlock;


- (void) generalInit	{
	type = OSCValInt;
	value = nil;
	hint = OSCValueViewHint_None;
	actionBlock = nil;
}

/*
- (void) drawRect:(NSRect)r	{
	[super drawRect:r];
	[[NSColor redColor] set];
	NSRectFill(r);
}
*/

/*
- (void) setType:(OSCValueType)t value:(OSCValue *)v	{
	NSLog(@"%s ... %@, %@",__func__,[OSCValue typeTagStringForType:t],v);
	[self setType:t];
	[self setValue:v];
	[self updateUIItems];
}
*/
- (void) setType:(OSCValueType)t value:(OSCValue *)v hint:(OSCValueViewHint)h valsArray:(NSArray<OSCValue*>*)vals	{
	//NSLog(@"%s ... %@, %@",__func__,[OSCValue typeTagStringForType:t],vals);
	//	set the type, value, and hint
	[self setType:t];
	//	if the type of the passed value matches the type i was passed then use it- else if there's a mismatch, nil out my value
	if (v!=nil && [v type]==t)
		[self setValue:v];
	else	{
		//[self setValue:nil];
		[self setValue:[v createValByConvertingToType:t]];
	}
	[self setHint:h];
	//	if there's an array of values, locate and populate the pop-up button
	if (vals != nil && [vals count]>0)	{
		NSMenu		*tmpMenu = [popUpButton menu];
		[tmpMenu setAutoenablesItems:NO];
		[tmpMenu removeAllItems];
		for (OSCValue *tmpValue in vals)	{
			//	only process the values that match the type i was assigned
			if ([tmpValue type] == t)	{
				NSMenuItem		*tmpItem = [[NSMenuItem alloc]
					initWithTitle:[tmpValue description]
					action:nil
					keyEquivalent:@""];
				[tmpItem setRepresentedObject:tmpValue];
				[tmpMenu addItem:tmpItem];
			}
		}
	}
	//	update the UI item visibility
	[self updateUIItems];
}


- (void) updateUIItems	{
	//NSLog(@"%s",__func__);
	//	if i'm supposed to be displaying a pop-up button, do that immediately, select the appropriate item, and then return
	if ([self hasHint:OSCValueViewHint_PUB])	{
		[textField setHidden:YES];
		[colorWell setHidden:YES];
		[popUpButton setHidden:NO];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		
		if (value != nil)	{
			NSInteger		selIndex = [popUpButton indexOfItemWithRepresentedObject:value];
			if (selIndex != -1)
				[popUpButton selectItemAtIndex:selIndex];
		}
		return;
	}
	
	//	...if i'm here, i know i'm not displaying a pop-up button.
	
	switch (type)	{
	//	these will display either a text field or a slider
	case OSCValFloat:
	case OSCValDouble:
		//[textField setHidden:YES];
		[colorWell setHidden:YES];
		//[popUpButton setHidden:YES];
		//[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		
		//	if we've got a slider hint, display the slider
		if ([self hasHint:OSCValueViewHint_Slider])	{
			[textField setHidden:YES];
			[popUpButton setHidden:YES];
			[slider setHidden:NO];
			//	don't process the slider here, it's processed in the refresh method of the table cell view for RemoteNodeControls (RemoteNodeControlTableCellView) because it needs to set a min/max in addition to the value, and the min/max aren't accessible from this point in the code.
			//if (value != nil)	{
			//	if (type == OSCValFloat)
			//		[slider setFloatValue:[value calculateFloatValue]];
			//	else
			//		[slider setDoubleValue:[value calculateDoubleValue]];
			//}
		}
		//	else display the text field
		else	{
			[textField setHidden:NO];
			[popUpButton setHidden:YES];
			[slider setHidden:YES];
			if (value != nil)	{
				if (type == OSCValFloat)
					[textField setStringValue:[NSString stringWithFormat:@"%f",[value calculateFloatValue]]];
				else
					[textField setStringValue:[NSString stringWithFormat:@"%f",[value calculateDoubleValue]]];
			}
			else
				[textField setStringValue:@""];
		}
		
		break;
	
	//	these will display either a text field or a pop-up button
	case OSCValInt:
	case OSCVal64Int:
		if ([self hasHint:OSCValueViewHint_ClickButton])	{
			[textField setHidden:YES];
			[colorWell setHidden:YES];
			[popUpButton setHidden:YES];
			[slider setHidden:YES];
			[button setHidden:NO];
			[toggle setHidden:YES];
			[labelField setHidden:YES];
		}
		else if ([self hasHint:OSCValueViewHint_ToggleButton])	{
			[textField setHidden:YES];
			[colorWell setHidden:YES];
			[popUpButton setHidden:YES];
			[slider setHidden:YES];
			[button setHidden:YES];
			[toggle setHidden:NO];
			[labelField setHidden:YES];
			
			[toggle setIntValue:([[self value] calculateIntValue]>=1) ? NSOnState : NSOffState];
		}
		else	{
			[textField setHidden:NO];
			[colorWell setHidden:YES];
			[popUpButton setHidden:YES];
			[slider setHidden:YES];
			[button setHidden:YES];
			[toggle setHidden:YES];
			[labelField setHidden:YES];
			if ([self value] != nil)	{
				if (type==OSCValInt)
					[textField setStringValue:[NSString stringWithFormat:@"%d",[[self value] intValue]]];
				else if (type == OSCVal64Int)
					[textField setStringValue:[NSString stringWithFormat:@"%lld",[[self value] longLongValue]]];
			}
			else
				[textField setStringValue:@""];
		}
		break;
	//	this will display a text field
	case OSCValString:
		[textField setHidden:NO];
		[colorWell setHidden:YES];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		if ([self value] != nil)	{
			[textField setStringValue:[[self value] stringValue]];
		}
		else
			[textField setStringValue:@""];
		break;
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
	case OSCValChar:
		[textField setHidden:NO];
		[colorWell setHidden:YES];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		if (value != nil)	{
			if (type == OSCValTimeTag)
				[textField setStringValue:[[value dateValue] description]];
			else if (type == OSCValChar)
				[textField setStringValue:[NSString stringWithFormat:@"%c",[value charValue]]];
		}
		else
			[textField setStringValue:@""];
		break;
	//	these will display a color UI item
	case OSCValColor:
		[textField setHidden:YES];
		[colorWell setHidden:NO];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		if (value != nil)	{
			[colorWell setColor:[value colorValue]];
		}
		break;
	//	these will display momentary buttons
	case OSCValBool:
	case OSCValInfinity:
	case OSCValNil:
		[textField setHidden:YES];
		[colorWell setHidden:YES];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:NO];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		break;
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		[textField setHidden:YES];
		[colorWell setHidden:YES];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:NO];
		break;
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		[textField setHidden:YES];
		[colorWell setHidden:YES];
		[popUpButton setHidden:YES];
		[slider setHidden:YES];
		[button setHidden:YES];
		[toggle setHidden:YES];
		[labelField setHidden:YES];
		break;
	}
}


- (BOOL) hasHint:(OSCValueViewHint)n	{
	return ((n & [self hint]) == 0) ? NO : YES;
}


- (IBAction) textFieldUsed:(id)sender	{
	//	first update my value
	switch (type)	{
	//	these will display either a text field or a slider if the view is wide enough
	case OSCValFloat:
		value = [OSCValue createWithFloat:[[textField stringValue] floatValue]];
		break;
	case OSCValDouble:
		value = [OSCValue createWithDouble:[[textField stringValue] doubleValue]];
		break;
	
	//	these will display either a text field or a pop-up button
	case OSCValString:
		value = [OSCValue createWithString:[textField stringValue]];
		break;
	case OSCValInt:
		value = [OSCValue createWithInt:[[textField stringValue] intValue]];
		break;
	case OSCVal64Int:
		value = [OSCValue createWithLongLong:[[textField stringValue] longLongValue]];
		break;
	
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
		break;
	case OSCValChar:
		value = [OSCValue createWithChar:[[textField stringValue] characterAtIndex:0]];
		break;
	
	//	these will display a color UI item
	case OSCValColor:
		break;
	
	//	these will display a button
	case OSCValBool:
	case OSCValInfinity:
	case OSCValNil:
		break;
	
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		break;
	
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		break;
	}
	
	//	now execute the action block
	if (actionBlock != nil && value != nil)
		actionBlock(value);
}
- (IBAction) colorWellUsed:(id)sender	{
	//	first update my value
	switch (type)	{
	//	these will display either a text field or a slider if the view is wide enough
	case OSCValFloat:
		break;
	case OSCValDouble:
		break;
	
	//	these will display either a text field or a pop-up button
	case OSCValString:
		break;
	case OSCValInt:
		break;
	case OSCVal64Int:
		break;
	
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
		break;
	case OSCValChar:
		break;
	
	//	these will display a color UI item
	case OSCValColor:
		value = [OSCValue createWithColor:[colorWell color]];
		break;
	
	//	these will display a button
	case OSCValBool:
	case OSCValInfinity:
	case OSCValNil:
		break;
	
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		break;
	
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		break;
	}
	
	//	now execute the action block
	if (actionBlock != nil && value != nil)
		actionBlock(value);
}
- (IBAction) popUpButtonUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	//	pop-up button menu items should have an OSCValue at their 'representedObject'
	NSMenuItem			*selItem = [popUpButton selectedItem];
	OSCValue			*selVal = (selItem==nil) ? nil : [selItem representedObject];
	//NSLog(@"\t\tselItem is %@, selVal is %@",selItem,selVal);
	if (selVal == nil)	{
		NSLog(@"\t\terr: val nil for PUB menu item %@ in %s",selItem,__func__);
		return;
	}
	value = selVal;
	
	//	now execute the action block
	if (actionBlock != nil && value != nil)
		actionBlock(value);
}
- (IBAction) sliderUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	//NSLog(@"\t\ttype is %d/%@",type,[OSCValue typeTagStringForType:type]);
	
	//	first update my value
	switch (type)	{
	//	these will display either a text field or a slider if the view is wide enough
	case OSCValFloat:
		value = [OSCValue createWithFloat:[slider floatValue]];
		break;
	case OSCValDouble:
		value = [OSCValue createWithDouble:[slider doubleValue]];
		break;
	//	these will display either a text field or a pop-up button
	case OSCValString:
		break;
	case OSCValInt:
		break;
	case OSCVal64Int:
		break;
	
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
		break;
	case OSCValChar:
		break;
	
	//	these will display a color UI item
	case OSCValColor:
		break;
	
	//	these will display a button
	case OSCValBool:
	case OSCValInfinity:
	case OSCValNil:
		break;
	
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		break;
	
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		break;
	}
	
	//	now execute the action block
	if (actionBlock != nil && value != nil)
		actionBlock(value);
}
- (IBAction) buttonUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	//NSLog(@"\t\ttype is %d/%@",type,[OSCValue typeTagStringForType:type]);
	
	//	first update my value
	switch (type)	{
	//	these will display either a text field or a slider if the view is wide enough
	case OSCValFloat:
		value = [OSCValue createWithFloat:1.];
		break;
	case OSCValDouble:
		value = [OSCValue createWithDouble:1.];
		break;
	//	these will display either a text field or a pop-up button
	case OSCValString:
		break;
	case OSCValInt:
		value = [OSCValue createWithInt:1];
		break;
	case OSCVal64Int:
		value = [OSCValue createWithLongLong:1];
		break;
	
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
		break;
	case OSCValChar:
		break;
	
	//	these will display a color UI item
	case OSCValColor:
		break;
	
	//	these will display a button
	case OSCValBool:
		if (value == nil)
			value = [OSCValue createWithBool:YES];
		break;
	case OSCValInfinity:
		value = [OSCValue createWithInfinity];
		break;
	case OSCValNil:
		value = [OSCValue createWithNil];
		break;
	
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		break;
	
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		break;
	}
	
	//	now execute the action block
	if (actionBlock != nil)
		actionBlock(value);
}
- (IBAction) toggleUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	//NSLog(@"\t\ttype is %d/%@",type,[OSCValue typeTagStringForType:type]);
	
	BOOL		boolVal = ([toggle intValue]==NSOnState) ? YES : NO;
	
	//	first update my value
	switch (type)	{
	//	these will display either a text field or a slider if the view is wide enough
	case OSCValFloat:
		break;
	case OSCValDouble:
		break;
	//	these will display either a text field or a pop-up button
	case OSCValString:
		break;
	case OSCValInt:
		value = [OSCValue createWithInt:(boolVal)?1:0];
		break;
	case OSCVal64Int:
		value = [OSCValue createWithLongLong:(boolVal)?1:0];
		break;
	
	//	these will display a text field (and only ever a text field)
	case OSCValTimeTag:
		break;
	case OSCValChar:
		break;
	
	//	these will display a color UI item
	case OSCValColor:
		break;
	
	//	these will display a button
	case OSCValBool:
	case OSCValInfinity:
	case OSCValNil:
		//	we're not calculating or setting any values here- these are momentary, they don't pass any values (the control will create one automatically of the appropriate type)
		break;
	
	//	these will only display a label informing the user that there's no UI item
	case OSCValMIDI:
	case OSCValArray:
	case OSCValBlob:
	case OSCValSMPTE:
		break;
	
	//	this will hide everything.  we use this in the backend.  yes, i know this is probably not a great idea.
	case OSCValUnknown:
	default:
		break;
	}
	
	//	now execute the action block
	if (actionBlock != nil)
		actionBlock(value);
}


- (NSTextField *) textField	{
	return textField;
}
- (NSColorWell *) colorWell	{
	return colorWell;
}
- (NSPopUpButton *) popUpButton	{
	return popUpButton;
}
- (NSSlider *) slider	{
	return slider;
}
- (NSButton *) button	{
	return button;
}
- (NSButton *) toggle	{
	return toggle;
}
- (NSTextField *) labelField	{
	return labelField;
}


@end
