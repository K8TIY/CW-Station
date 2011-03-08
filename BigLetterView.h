#import <Cocoa/Cocoa.h>

extern NSString* BigLetterViewTextNotification;

@interface BigLetterView : NSView
{
	NSColor* bgColor;
	NSMutableString* string;
	NSMutableDictionary *attributes;
  BOOL canBecomeFirstResponder;
  NSUInteger modifiers;
}
@property (retain, readwrite) NSColor* bgColor;
@property (assign, readwrite) BOOL canBecomeFirstResponder;
-(NSString*)string;
-(void)setString:(NSString*)s;
@end
