#import <Cocoa/Cocoa.h>

extern NSString* BigLetterViewTextNotification;

@interface BigLetterView : NSView
{
  NSColor* bgColor;
  NSMutableString* string;
  NSMutableDictionary* attributes;
  NSUInteger modifiers;
  BOOL canBecomeFirstResponder;
  BOOL prosignFormat;
}
@property (retain, readwrite) NSColor* bgColor;
@property (assign, readwrite) BOOL canBecomeFirstResponder;
@property (assign, readwrite) BOOL prosignFormat;
-(NSString*)string;
-(void)setString:(NSString*)s;
@end
