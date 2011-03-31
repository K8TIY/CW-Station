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
  unsigned i;
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
+(float)millisecondsPerUnitAtWPM:(float)wpm
{
  return 1200.0L / wpm;
}

+(float)WPMPerUnitMilliseconds:(float)time
{
  return 1200.0L / time;
}

+(MorseSpacing)spacingForWPM:(float)wpm CWPM:(float)cwpm
{
  float tc = 0.0L;
  float tw = 0.0L;
  if (cwpm != wpm)
  {
    float ta = ((60.0L * cwpm)-(37.2L * wpm)) / (cwpm * wpm);
    tc = 1000.0L * (3.0L * ta) / 19.0L;
    tw = 1000.0L * (7.0L * ta) / 19.0L;
  }
  else
  {
    float unit = [Morse millisecondsPerUnitAtWPM:wpm];
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
    NSEnumerator* enu = [sub keyEnumerator];
    NSString* key;
    while ((key = [enu nextObject]))
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

+(uint16_t*)morseFromString:(NSString*)string length:(unsigned*)outLength offsets:(NSDictionary**)offsets
{
  NSMutableArray* symbols = [[NSMutableArray alloc] init];
  NSMutableDictionary* offs = (offsets)? [[NSMutableDictionary alloc] init] : nil;
  NSDictionary* d = [[Morse dictionary] objectForKey:@"Code"];
  unsigned i, length = [string length];
  BOOL wasSpace = YES;
  BOOL didPro = NO;
  int wordStart = -1;
  int wordStartElem = -1;
  for (i = 0; i < length; i++)
  {
    NSNumber* num;
    unichar chr = [string characterAtIndex:i];
    if (chr == ' ' || chr == '\n' || chr == '\t')
    {
      if (didPro) [symbols removeLastObject];
      num = [[NSNumber alloc] initWithUnsignedShort:MorseInterwordSpace];
      [symbols addObject:num];
      [num release];
      wasSpace = YES;
      didPro = NO;
      if (wordStart > -1 && wordStartElem > -1)
      {
        [offs setObject:NSStringFromRange(NSMakeRange(wordStart,i-wordStart))
              forKey:[NSNumber numberWithUnsignedShort:wordStartElem]];
      }
      wordStart = wordStartElem = -1;
    }
    else
    {
      if (chr == 0x0305)
      {
        if (i > 0 && !wasSpace && i < length-1)
        {
          [symbols addObject:[NSNumber numberWithUnsignedShort:MorseInterelementSpace]];
          didPro = YES;
        }
      }
      else
      {
        if (i > 0 && !wasSpace && !didPro) [symbols addObject:[NSNumber numberWithUnsignedShort:MorseIntercharacterSpace]];
        NSString* asString = [[NSString stringWithFormat:@"%C", chr] uppercaseString];
        //NSLog(@"%@", asString);
        num = [d objectForKey:asString];
        if (nil == num) [[NSException exceptionWithName:@"Unsupported Character"
                                      reason:[NSString stringWithFormat:@"Unsupported Character: '%C' (%d)", chr, chr]
                                      userInfo:nil] raise];
        [symbols addObject:num];
        if (wordStart == -1 && wordStartElem == -1)
        {
          wordStart = i;
          wordStartElem = [symbols count]-1;
        }
        didPro = NO;
      }
      wasSpace = NO;
    }
  }
  if (wordStart > 0 && wordStartElem > 0)
  {
    [offs setObject:NSStringFromRange(NSMakeRange(wordStart,i-wordStart))
          forKey:[NSNumber numberWithUnsignedShort:wordStartElem]];
  }
  unsigned count = [symbols count];
  *outLength = count;
  uint16_t* a = malloc(sizeof(uint16_t) * count);
  uint16_t* ap = a;
  for (i = 0; i < count; i++, ap++)
    *ap = [[symbols objectAtIndex:i] unsignedShortValue];
  //NSLog(@"%@", offs);
  [symbols release];
  if (offsets) *offsets = [NSDictionary dictionaryWithDictionary:offs];
  if (offs) [offs release];
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

// Merges consecutive uppercase characters into prosigns.
+(NSString*)formatString:(NSString*)string
{
  NSMutableString* ms = [[NSMutableString alloc] init];
  unsigned i, n = [string length];
  NSCharacterSet* set = [NSCharacterSet uppercaseLetterCharacterSet];
  for (i = 0; i < n; i++)
  {
    unichar chr = [string characterAtIndex:i];
    if ([set characterIsMember:chr]) [ms appendFormat:@"%C%C", chr, 0x0305];
    else [ms appendFormat:@"%C", chr];
  }
  NSString* ret = [ms uppercaseString];
  [ms release];
  //NSLog(@"%@ -> %@", string, ret);
  return ret;
}
@end

@interface MorseRecognizer (Private)
-(uint16_t)_recognize;
@end

@implementation MorseRecognizer
-(id)initWithWPM:(float)wpm
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
  float dev = 0.0;
  float tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  float intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  float interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
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
  if (n) mrq.quality = (1.0L - (dev/(float)n));
  if (nt) mrq.toneWPM = twpm/(float)nt;
  if (ns) mrq.spaceWPM = swpm/(float)ns;
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
  float tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  float intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  float interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
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

-(float)WPM { return _wpm; }
-(void)setWPM:(float)wpm { _wpm = wpm; }
@end
