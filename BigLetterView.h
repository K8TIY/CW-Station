#import <Cocoa/Cocoa.h>

extern NSString* BigLetterViewTextNotification;

@interface BigLetterView : NSView
{
  NSColor* bgColor;
  NSMutableString* string;
  NSMutableDictionary* attributes;
  unsigned modifiers;
  BOOL canBecomeFirstResponder;
  BOOL formatProsign;
}
-(NSString*)string;
-(void)setString:(NSString*)s;
-(void)setBGColor:(NSColor*)col;
-(void)setFormatProsign:(BOOL)flag;
-(void)setCanBecomeFirstResponder:(BOOL)flag;
@end
