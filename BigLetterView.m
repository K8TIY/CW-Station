#import "BigLetterView.h"
#import "Morse.h"

NSString* BigLetterViewTextNotification = @"BigLetterViewTextNotification";

@interface BigLetterView (Private)
-(void)prepareAttributes;
-(void)drawStringCenteredIn:(NSRect)r;
@end

@implementation BigLetterView
-(id)initWithFrame:(NSRect)rect
{
  if (![super initWithFrame:rect]) return nil;
  [self prepareAttributes];
  bgColor = [[NSColor grayColor] retain];
  string = [[NSMutableString alloc] init];
  canBecomeFirstResponder = YES;
  return self;
}

-(void)drawRect:(NSRect)rect
{
  NSRect bounds = [self bounds];
  [bgColor set];
  [NSBezierPath fillRect:bounds];
  [self drawStringCenteredIn:bounds];
}

-(void)dealloc
{
  [bgColor release];
  [string release];
  [attributes release];
  [super dealloc];
}

-(void)setBgColor:(NSColor*)c
{
  [c retain];
  [bgColor release];
  bgColor = c;
  [self setNeedsDisplay:YES];
}

-(NSColor*)bgColor
{
  return bgColor;
}

-(void)setString:(NSString*)s
{
  if (nil == s) s = @"";
  [string setString:s];
  [self setNeedsDisplay:YES];
}

-(NSString*)string { return string; }
-(BOOL)isOpaque { return YES; }
-(BOOL)acceptsFirstResponder { return canBecomeFirstResponder; }
-(BOOL)becomeFirstResponder { return canBecomeFirstResponder; }
-(void)setCanBecomeFirstResponder:(BOOL)flag { canBecomeFirstResponder = flag; }
-(void)setBGColor:(NSColor*)col
{
  col = [col retain];
  if (bgColor) [bgColor release];
  bgColor = col;
  [self setNeedsDisplay:YES];
}
-(void)setFormatProsign:(BOOL)flag { formatProsign = flag; }

-(void)keyDown:(NSEvent*)event
{
  modifiers = [event modifierFlags];
  [self interpretKeyEvents:[NSArray arrayWithObject:event]];
  // Handle backspace
  if ([event keyCode] == 51)
  {
    if ([string length])
    {
      [string setString:[string substringToIndex:[string length]-1]];
      [self setNeedsDisplay:YES];
    }
  }
  //NSLog(@"%@", event);
}

-(void)insertText:(NSString*)input
{
  if (canBecomeFirstResponder)
  {
    //NSLog(@"Typed %@", input);
    //input = [input uppercaseString];
    [string appendString:input];
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:BigLetterViewTextNotification object:string];
    //NSLog(@"%@", strings);
  }
}

-(void)prepareAttributes
{
  attributes = [[NSMutableDictionary alloc] init];
  [attributes setObject:[NSFont fontWithName:@"Monaco" size:48] forKey:NSFontAttributeName];
  [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
}

-(void)drawStringCenteredIn:(NSRect)r
{
  if ([string length])
  {
    NSString* toDraw = string;
    if (formatProsign) toDraw = [Morse formatString:string];
    //NSLog(@"%@ from %@", string, strings);
    //float descent = [[attributes objectForKey:NSFontAttributeName] descender];
    NSSize strSize = [toDraw sizeWithAttributes:attributes];
    //NSLog(@"str height %f, rect height %f", strSize.height, r.size.height);
    NSPoint strOrigin;
    strOrigin.x = r.origin.x + (r.size.width - strSize.width)/2;
    strOrigin.y = r.origin.y + (r.size.height - strSize.height)/2;
    [toDraw drawAtPoint:strOrigin withAttributes:attributes];
  }
}

@end

