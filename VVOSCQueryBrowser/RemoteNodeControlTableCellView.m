#import "RemoteNodeControlTableCellView.h"
#import "RemoteNodeControl.h"
#import "RemoteNode.h"




@implementation RemoteNodeControlTableCellView


/*
- (id) initWithFrame:(NSRect)r	{
	NSLog(@"%s ... %@",__func__,self);
	return [super initWithFrame:r];
}
- (id) initWithCoder:(NSCoder *)c	{
	NSLog(@"%s ... %@",__func__,self);
	return [super initWithCoder:c];
}
- (id) init	{
	NSLog(@"%s ... %@",__func__,self);
	return [super init];
}
- (void) dealloc	{
	NSLog(@"%s ... %@",__func__,self);
}
*/
- (void) refreshWithRemoteNodeControl:(RemoteNodeControl *)n outlineView:(NSOutlineView *)ov	{
	//NSLog(@"%s",__func__);
	//NSLog(@"\t\tself is %@",self);
	//NSLog(@"\t\tcontrol is %@",n);
	
	//	if we weren't passed a control, hide everything and return immediately
	if (n==nil)	{
		[valueView setType:OSCValUnknown value:nil hint:OSCValueViewHint_None valsArray:nil];
		[minView setType:OSCValUnknown value:nil hint:OSCValueViewHint_None valsArray:nil];
		[maxView setType:OSCValUnknown value:nil hint:OSCValueViewHint_None valsArray:nil];
		return;
	}
	
	//	we want a zeroing weak ref to the control here, so our action block captures the zeroing weak ref
	__weak NSOutlineView			*outlineView = ov;
	__weak RemoteNodeControl		*weakControlRef = n;
	//	update the action block for the value UI item
	[valueView setActionBlock:^(OSCValue *newOSCValue)	{
		//NSLog(@"action block executing!");
		//NSLog(@"\t\tself was %p, value view was %p",self,valueView);
		//NSLog(@"\t\tcontrol was %@, parent should be %@",n,[n parentNode]);
		//	update the control's value
		if (newOSCValue != nil)	{
			[weakControlRef setValue:newOSCValue];
			//[n setValue:newOSCValue];
		}
		
		//	tell the node's parent to send its message
		[[weakControlRef parentNode] sendMessage];
		//[[n parentNode] sendMessage];
		
		//	tell the outline view to reload this row
		if (newOSCValue != nil)	{
			[outlineView reloadItem:n reloadChildren:NO];
			//[ov reloadItem:n reloadChildren:NO];
		}
	}];
	
	OSCValueType		type = [OSCValue typeForTypeTagString:[n typeString]];
	OSCValue			*tmpVal = [n value];
	OSCValue			*tmpMin = [n min];
	OSCValue			*tmpMax = [n max];
	NSArray<OSCValue*>	*tmpVals = [n vals];
	//NSLog(@"\t\t%@, %@-%@-%@. %@",[n typeString],tmpVal,tmpMin,tmpMax,tmpVals);
	
	//	figure out the hints i'm going to pass to the value view...
	OSCValueViewHint	tmpHint = OSCValueViewHint_None;
	//	if there's an array of explicit vals, we're going to be using a PUB
	if (tmpVals!=nil && [tmpVals count]>0)	{
		//NSLog(@"\t\tPUB hint");
		tmpHint |= OSCValueViewHint_PUB;
	}
	//	else there isn't an array of explicit vals...
	else	{
		//	if there's a min and a max, provide a slider hint
		if (tmpMin!=nil && tmpMax!=nil)	{
			//	if the min and max are different
			if ([tmpMin compare:tmpMax] != NSOrderedSame)	{
				//	if the min is 0 and the max is 1 and the type is int show a toggle
				if ([tmpMin calculateIntValue]==0 && [tmpMax calculateIntValue]==1 && type==OSCValInt)	{
					//NSLog(@"\t\ttoggle hint");
					tmpHint |= OSCValueViewHint_ToggleButton;
				}
				else	{
					//NSLog(@"\t\tslider hint");
					tmpHint |= OSCValueViewHint_Slider;
				}
			}
			//	else the min and max are the same, show a click button
			else	{
				//NSLog(@"\t\tclick button hint");
				tmpHint |= OSCValueViewHint_ClickButton;
			}
		}
	}
	
	//	update the value view with the type, value, value view hint, and array of explicit vals...
	[valueView setType:type value:tmpVal hint:tmpHint valsArray:tmpVals];
	
	//	if there isn't an explicit array of values that must be adhered to...
	if (tmpVals == nil)	{
		//	show/hide the min view
		if (tmpMin == nil)
			[minView setHidden:YES];
		else	{
			[minView setHidden:NO];
			[minView setType:type value:tmpMin hint:OSCValueViewHint_None valsArray:nil];
		}
		
		//	show/hide the max view
		if (tmpMax == nil)
			[maxView setHidden:YES];
		else	{
			[maxView setHidden:NO];
			[maxView setType:type value:tmpMax hint:OSCValueViewHint_None valsArray:nil];
		}
		
		//	if a slider is visible, we have to set its min/max vals
		NSSlider		*tmpSlider = [valueView slider];
		if (![tmpSlider isHidden] && tmpMin!=nil && tmpMax!=nil)	{
			if (tmpMin!=nil && tmpMax!=nil)	{
				//NSLog(@"\t\tmismatch in slider min/max, resetting them");
				//	we have to do this twice because we don't know what the prior min/max were...
				[tmpSlider setMinValue:[tmpMin calculateDoubleValue]];
				[tmpSlider setMaxValue:[tmpMax calculateDoubleValue]];
				[tmpSlider setMinValue:[tmpMin calculateDoubleValue]];
				[tmpSlider setMaxValue:[tmpMax calculateDoubleValue]];
			}
			else	{
				[tmpSlider setMinValue:0.0];
				[tmpSlider setMaxValue:1.0];
				[tmpSlider setMinValue:0.0];
				[tmpSlider setMaxValue:1.0];
			}
			
			if (tmpVal != nil)	{
				//	we're going to use floats to do the comparison even though the vals are doubles
				float		tmpValA = (float)[tmpSlider doubleValue];
				float		tmpValB = (float)[tmpVal calculateDoubleValue];
				if (tmpValA != tmpValB)
				{
					//NSLog(@"\t\tfound val, setting slider val to %@",tmpVal);
					//NSLog(@"\t\ttmpValA is %f, tmpValB is %f",tmpValA,tmpValB);
					[tmpSlider setFloatValue:tmpValB];
				}
			}
			else	{
				//NSLog(@"\t\tno val, setting slider val to min, %@",tmpMin);
				if ([tmpSlider doubleValue] != [tmpMin calculateDoubleValue])
					[tmpSlider setDoubleValue:[tmpMin calculateDoubleValue]];
			}
		}
		
		//	if a text field is visible in the min or max views, make sure it's not editable
		if (![[minView textField] isHidden])
			[[minView textField] setEditable:NO];
		if (![[maxView textField] isHidden])
			[[maxView textField] setEditable:NO];
	}
	//	else there's an explicit array of values that must be adhered to...
	else	{
		//	hide the min and max views
		[minView setHidden:YES];
		[maxView setHidden:YES];
	}
	//[valueView setType:type value:type];
}


@end
