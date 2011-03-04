/*
Copyright © 2010-2011 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import "BigLetterView.h"
#import "Morse.h"

NSString* BigLetterViewTextNotification = @"BigLetterViewTextNotification";

@interface BigLetterView (Private)
-(void)prepareAttributes;
-(void)drawStringCenteredIn:(NSRect)r;
@end

@implementation BigLetterView
@synthesize canBecomeFirstResponder;
-(id)initWithFrame:(NSRect)rect
{
	if(![super initWithFrame:rect]) return nil;
	[self prepareAttributes];
	bgColor = [[NSColor grayColor] retain];
	strings = [[NSMutableArray alloc] init];
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
	[strings release];
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

-(void)setStrings:(NSArray*)s
{
  if (nil == s) [strings removeAllObjects];
  else [strings setArray:s];
	[self setNeedsDisplay:YES];
}

-(NSArray*)strings { return strings; }
-(BOOL)isOpaque { return YES; }
-(BOOL)acceptsFirstResponder { return canBecomeFirstResponder; }
-(BOOL)becomeFirstResponder { return YES; }

-(void)keyDown:(NSEvent*)event
{
  modifiers = [event modifierFlags];
	[self interpretKeyEvents:[NSArray arrayWithObject:event]];
  // Handle backspace
  if ([event keyCode] == 51)
  {
    NSString* str = [strings lastObject];
    if (str)
    {
      NSString* newString = nil;
      if ([str length] > 1) newString = [str substringToIndex:[str length]-1];
      [strings removeLastObject];
      if (newString) [strings addObject:newString];
      //NSLog(@"%@", strings);
    }
    [self setNeedsDisplay:YES];
  }
  //NSLog(@"%@", event);
}

-(void)insertText:(NSString*)input
{
	if (canBecomeFirstResponder)
  {
    //NSLog(@"Typed %@", input);
    input = [input uppercaseString];
    if (modifiers & (NSShiftKeyMask | NSAlphaShiftKeyMask) && [strings count])
    {
      input = [NSString stringWithFormat:@"%@%@", [strings objectAtIndex:[strings count]-1], input];
      [strings removeLastObject];
    }
    [strings addObject:input];
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:BigLetterViewTextNotification object:strings];
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
  NSString* string = [Morse formatStrings:strings];
  if ([string length])
  {
    //NSLog(@"%@ from %@", string, strings);
    //CGFloat descent = [[attributes objectForKey:NSFontAttributeName] descender];
    NSSize strSize = [string sizeWithAttributes:attributes];
    //NSLog(@"str height %f, rect height %f", strSize.height, r.size.height);
    NSPoint strOrigin;
    strOrigin.x = r.origin.x + (r.size.width - strSize.width)/2;
    strOrigin.y = r.origin.y + (r.size.height - strSize.height)/2;
    [string drawAtPoint:strOrigin withAttributes:attributes];
  }
}

@end

