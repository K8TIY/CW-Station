#import <Cocoa/Cocoa.h>

extern NSString* BigLetterViewTextNotification;

@interface BigLetterView : NSView
{
	NSColor* bgColor;
	NSMutableArray* strings;
	NSMutableDictionary *attributes;
  BOOL canBecomeFirstResponder;
  NSUInteger modifiers;
}
@property (retain, readwrite) NSColor* bgColor;
@property (assign, readwrite) BOOL canBecomeFirstResponder;
-(NSArray*)strings;
-(void)setStrings:(NSArray*)s;
@end
