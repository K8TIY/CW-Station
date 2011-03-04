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
#include "Morse.h"

@implementation NSArray (StringComparison)
-(BOOL)isEqual:(NSArray*)other
{
  if (self == other) return YES;
  if ([self count] != [other count]) return NO;
  NSUInteger i;
  for (i = 0; i < [self count]; i++)
  {
    if (![[self objectAtIndex:i] isEqual:[other objectAtIndex:i]]) return NO;
  }
  return YES;
}
@end

uint8_t  MorseDitUnits = 1;
uint8_t  MorseDahUnits = 3;
uint8_t  MorseInterwordUnits = 7;

@implementation Morse
+(CGFloat)millisecondsPerUnitAtWPM:(CGFloat)wpm
{
  return 1200.0L / wpm;
}

+(CGFloat)WPMPerUnitMilliseconds:(CGFloat)time
{
  return 1200.0L / time;
}

+(MorseSpacing)spacingForWPM:(CGFloat)wpm CWPM:(CGFloat)cwpm
{
  CGFloat tc = 0.0L;
  CGFloat tw = 0.0L;
  if (cwpm != wpm)
  {
    CGFloat ta = ((60.0L * cwpm)-(37.2L * wpm)) / (cwpm * wpm);
    tc = 1000.0L * (3.0L * ta) / 19.0L;
    tw = 1000.0L * (7.0L * ta) / 19.0L;
  }
  else
  {
    CGFloat unit = [Morse millisecondsPerUnitAtWPM:wpm];
    tc = unit * MorseDahUnits;
    tw = unit * MorseInterwordUnits;
  }
  MorseSpacing spacing;
  spacing.intercharacterMilliseconds = tc;
  spacing.interwordMilliseconds = tw;
  return spacing;
}

+(NSDictionary*)dictionary
{
  static NSDictionary* d = nil;
  if (!d)
  {
    NSString* where = [[NSBundle mainBundle] pathForResource:@"Morse" ofType:@"plist"];
    d = [[NSDictionary alloc] initWithContentsOfFile:where];
    //NSLog(@"%@: %@", where, d);
  }
  return d;
}

+(NSDictionary*)reverseDictionary
{
  static NSMutableDictionary* rd = nil;
  if (!rd)
  {
    NSDictionary* d = [Morse dictionary];
    rd = [[NSMutableDictionary alloc] init];
    NSDictionary* sub = [d objectForKey:@"Code"];
    for (NSString* key in [sub allKeys])
    {
      [rd setObject:key forKey:[sub objectForKey:key]];
    }
    //NSLog(@"%@", rd);
  }
  return rd;
}

/*+(void)plist
{
  NSString* where = [[NSBundle mainBundle] pathForResource:@"Morse" ofType:@"strings"];
  NSDictionary* d = [[NSDictionary alloc] initWithContentsOfFile:where];
  NSMutableArray* keys = [[NSMutableArray alloc] initWithArray:[d allKeys]];
  [keys sortUsingSelector:@selector(compare:)];
  for (NSString* key in keys)
  {
    NSString* val = [d objectForKey:key];
    printf("    <key>%s</key>", [key UTF8String]);
    uint16_t hi = 0;
    uint16_t len = [val length];
    uint16_t i;
    for (i = 0; i < len; i++)
    {
      unichar chr = [val characterAtIndex:i];
      if (chr == '-') hi |= (1<<i);
    }
    uint16_t n = len | (hi << 3);
    printf("<integer>%d</integer>\n", n);
  }
  [keys release];
  [d release];
}*/

// Interelement space is indicated in prosigns as 0x0000
// Intercharacter space is 0x0008
// Interword space is 0x0009
uint16_t MorseNoCharacter = 0x0000;
uint16_t MorseInterelementSpace = 0x0008;
uint16_t MorseIntercharacterSpace = 0x0010;
uint16_t MorseInterwordSpace = 0x0018;


+(NSString*)stringFromMorse:(uint16_t)morse
{
  if (morse == MorseNoCharacter) return nil;
  if (morse == MorseInterwordSpace) return @" ";
  if (morse == MorseInterelementSpace || morse == MorseIntercharacterSpace) return @"";
  NSDictionary* rd = [Morse reverseDictionary];
  return [rd objectForKey:[NSNumber numberWithUnsignedShort:morse]];
}

+(uint16_t*)morseFromStrings:(NSArray*)strings length:(NSUInteger*)outLength
{
  NSMutableArray* substrings = [[NSMutableArray alloc] init];
  NSDictionary* d = [[Morse dictionary] objectForKey:@"Code"];
  NSUInteger i, length = [strings count];
  BOOL wasSpace = YES;
  for (i = 0; i < length; i++)
  {
    NSNumber* num;
    NSString* str = [strings objectAtIndex:i];
    unichar chr = [str characterAtIndex:0];
    if (chr == ' ')
    {
      num = [[NSNumber alloc] initWithUnsignedShort:MorseInterwordSpace];
      wasSpace = YES;
      [substrings addObject:num];
      [num release];
    }
    else
    {
      // If not the first character group, prepend an intercharacter space.
      if (i > 0 && !wasSpace) [substrings addObject:[NSNumber numberWithUnsignedShort:MorseIntercharacterSpace]];
      wasSpace = NO;
      NSUInteger slen = [str length];
      NSUInteger j;
      for (j = 0; j < slen; j++)
      {
        NSString* asString = str;
        if (slen > 1) 
        {
          chr = [str characterAtIndex:j];
          asString = [NSString stringWithFormat:@"%C", chr];
          if (j > 0) [substrings addObject:[NSNumber numberWithUnsignedShort:MorseInterelementSpace]];
        }
        asString = [asString uppercaseString];
        num = [d objectForKey:asString];
        if (nil == num) [[NSException exceptionWithName:@"Unsupported Character" reason:asString userInfo:nil] raise];
        [substrings addObject:num];
      }
    }
  }
  NSUInteger count = [substrings count];
  *outLength = count;
  uint16_t* a = malloc(sizeof(uint16_t) * count);
  uint16_t* ap = a;
  for (i = 0; i < count; i++, ap++)
    *ap = [[substrings objectAtIndex:i] unsignedShortValue];
  [substrings release];
  return a;
}

+(NSArray*)letters
{
  return [[Morse dictionary] objectForKey:@"Letters"];
}

+(NSArray*)numbers
{
  return [[Morse dictionary] objectForKey:@"Numbers"];
}

+(NSArray*)lettersAndNumbers
{
  NSDictionary* d = [Morse dictionary];
  NSMutableArray* a = [[NSMutableArray alloc] initWithArray:[d objectForKey:@"Letters"]];
  [a addObjectsFromArray:[d objectForKey:@"Numbers"]];
  NSArray* ret = [NSArray arrayWithArray:a];
  [a release];
  return ret;
}

+(NSArray*)punctuation
{
  return [[Morse dictionary] objectForKey:@"Punctuation"];
}

+(NSArray*)prosigns
{
  return [[Morse dictionary] objectForKey:@"Prosigns"];
}


//static NSString* overline = @"\u0305";
+(NSString*)formatStrings:(NSArray*)strings
{
  NSMutableString* toDraw = [[NSMutableString alloc] init];
  for (NSString* str in strings)
  {
    if ([str length] > 1)
    {
      NSUInteger i;
      for (i = 0; i < [str length]; i++)
      {
        unichar chr = [str characterAtIndex:i];
        [toDraw appendFormat:@"%C%C", chr, 0x0305];
      }
    }
    else [toDraw appendString:str];
  }
  NSString* ret = [NSString stringWithString:toDraw];
  [toDraw release];
  return ret;
}

+(NSArray*)splitString:(NSString*)string
{
  NSMutableArray* array = [[NSMutableArray alloc] init];
  NSUInteger i, n = [string length];
  NSUInteger pro;
  BOOL doingPro = NO;
  for (i = 0; i < n; i++)
  {
    unichar chr = [string characterAtIndex:i];
    if (chr == '[')
    {
      pro = i+1;
      doingPro = YES;
    }
    else if (chr == ']' && doingPro)
    {
      [array addObject:[string substringWithRange:NSMakeRange(pro, i - pro)]];
      doingPro = NO;
    }
    else if (!doingPro) [array addObject:[NSString stringWithFormat:@"%C", chr]];
  }
  NSArray* ret = [NSArray arrayWithArray:array];
  [array release];
  //NSLog(@"%@", ret);
  return ret;
}
@end

@interface MorseRecognizer (Private)
-(uint16_t)_recognize;
@end

@implementation MorseRecognizer
-(id)initWithWPM:(CGFloat)wpm
{
  self = [super init];
  [self setWPM:wpm];
  return self;
}

-(uint16_t)feed:(double*)duration
{
  uint16_t chr = MorseNoCharacter;
  // Put the event in the buffer
  if (duration)
  {
    unsigned where = (_bufferStart + _bufferCount) % MorseBufferSize;
    if (_bufferCount == MorseBufferSize)
    {
      where = _bufferStart;
      _bufferStart++;
      if (_bufferStart >= MorseBufferSize) _bufferStart = 0;
    }
    //char* type = (where % 2 == 0)? "tone":"space";
    //NSLog(@"Put %s %f ms at position %d (%d,%d)", type, *duration, where, _bufferStart, _bufferCount);
    if (_bufferCount < MorseBufferSize) _bufferCount++;
    _buffer[where] = *duration;
  }
  chr = [self _recognize];
  return chr;
}

-(MorseRecognizerQuality)quality
{
  double twpm = 0.0;
  double swpm = 0.0;
  unsigned seen = 0;
  int i = _bufferStart;
  unsigned n = 0;
  unsigned nt = 0;
  unsigned ns = 0;
  CGFloat dev = 0.0;
  CGFloat tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  CGFloat intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  CGFloat interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
  while (YES)
  {
    double unit = _buffer[i];
    if (unit > 0.0L)
    {
      if (i % 2 == 0)
      {
        if (unit > 2.0 * tone) unit /= MorseDahUnits;
        twpm += [Morse WPMPerUnitMilliseconds:unit];
        nt++;
      }
      else
      {
        if (unit > interwordCutoff) unit /= MorseInterwordUnits;
        else if (unit > intercharacterCutoff) unit /= MorseDahUnits;
        swpm += [Morse WPMPerUnitMilliseconds:unit];
        ns++;
      }
      dev += fmin(1.0,fabs((unit-tone)/tone));
      //NSLog(@"%d: dev now %f from %f = fabs((%f-%f)/%f)", i, dev, fabs((unit-tone)/tone), unit, tone, tone);
      n++;
    }
    i++;
    if (i >= MorseBufferSize) i = 0;
    seen++;
    if (seen >= MorseBufferSize) break;
  }
  MorseRecognizerQuality mrq = {0.0,0.0,0.0};
  if (n) mrq.quality = (1.0L - (dev/(CGFloat)n));
  if (nt) mrq.toneWPM = twpm/(CGFloat)nt;
  if (ns) mrq.spaceWPM = swpm/(CGFloat)ns;
  //NSLog(@"q %f from dev %f for %d units", mrq.quality, dev, n);
  return mrq;
}

-(uint16_t)_recognize
{
  uint16_t chr = MorseNoCharacter;
  uint16_t inProgress = 0x0000;
  unsigned seen = 0;
  int i = _bufferStart;
  //NSLog(@"Start while loop");
  CGFloat tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  CGFloat intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  CGFloat interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
  while (YES)
  {
    BOOL isTone = (i % 2 == 0);
    //NSLog(@"i=%d tone %s", i, isTone? "YES":"NO");
    if (isTone)
    {
      unsigned char len = inProgress & 0x0007;
      len++;
      inProgress = len | (inProgress & 0xFFF8);
      //NSLog(@"Tone: _buffer[%d] (%f) > 2.0 * tone (%f)? %s", i, _buffer[i], tone, (_buffer[i] > 2.0 * tone)?"dah":"dit");
      if (_buffer[i] > 2.0 * tone) inProgress |= 1 << (len+2);
      //NSLog(@"morse now %d (len %d)", inProgress, len);
    }
    else
    {
      //NSLog(@"Space: _buffer[%d] (%f) > interchar cutoff (%f)? %s", i, _buffer[i], intercharacterCutoff, (_buffer[i] > 2.0 * intercharacterCutoff)?"long":"short");
      if (_buffer[i] > intercharacterCutoff)
      {
        // interword or intercharacter: emit character.
        seen++;
        chr = inProgress;
        //NSLog(@"Long space: _buffer[%d] (%f) > interword cutoff (%f)? %s (%d)", i, _buffer[i], interwordCutoff, (_buffer[i] > interwordCutoff)?"YES":"NO", inProgress);
        if (_buffer[i] > interwordCutoff)
        {
          if (inProgress == MorseNoCharacter) chr = MorseInterwordSpace;
          else seen--;
        }
        _bufferStart = (_bufferStart + seen) % MorseBufferSize;
        _bufferCount -= seen;
        //NSLog(@"Emit %d; _bufferStart %d, _bufferCount %d, seen %d", chr, _bufferStart, _bufferCount, seen);
      }
    }
    if (chr) break;
    i++;
    if (i >= MorseBufferSize) i = 0;
    seen++;
    if (seen >= MorseBufferSize || seen >= _bufferCount) break;
  }
  return chr;
}

-(CGFloat)WPM { return _wpm; }
-(void)setWPM:(CGFloat)wpm { _wpm = wpm; }
@end
