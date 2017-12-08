#import "RemoteNodeTableCellView.h"




@implementation RemoteNodeTableCellView

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
- (void) refreshWithRemoteNode:(RemoteNode *)n	{
	NSString		*tmpString = nil;
	
	tmpString = [n fullPath];
	if (tmpString == nil)
		tmpString = @"???";
	[fullPathLabel setStringValue:tmpString];
	
	tmpString = [n oscDescription];
	if (tmpString == nil)
		tmpString = @"";
	[descriptionLabel setStringValue:tmpString];
	
	tmpString = [n typeString];
	if (tmpString == nil)
		tmpString = @"";
	[typeTagStringLabel setStringValue:tmpString];
}


@end
