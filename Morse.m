/*
Copyright © 2010-2012 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 or later as
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
    for (NSString* key in sub)
      [rd setObject:key forKey:[sub objectForKey:key]];
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

+(uint16_t*)morseFromString:(NSString*)string withDelay:(BOOL)del
            length:(unsigned*)outLength offsets:(NSDictionary**)offsets
{
  NSMutableArray* symbols = [[NSMutableArray alloc] init];
  NSMutableDictionary* offs = (offsets)? [[NSMutableDictionary alloc] init]:nil;
  NSDictionary* d = [[Morse dictionary] objectForKey:@"Code"];
  unsigned i, length = [string length];
  BOOL wasSpace = YES;
  BOOL didPro = NO;
  int wordStart = -1;
  int wordStartElem = -1;
  if (del) [symbols addObject:[NSNumber numberWithUnsignedInt:MorseInterwordSpace]];
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

+(NSArray*)charactersFromSets:(unsigned)sets
{
  NSMutableArray* a = [[NSMutableArray alloc] init];
  NSDictionary* d = [Morse dictionary];
  if (sets & 1 << MorseSetLetters)
  {
    [a addObjectsFromArray:[d objectForKey:@"Letters"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"Letters"]);
  }
  if (sets & 1 << MorseSetNumbers)
  {
    [a addObjectsFromArray:[d objectForKey:@"Numbers"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"Numbers"]);
  }
  if (sets & 1 << MorseSetPunctuation)
  {
    [a addObjectsFromArray:[d objectForKey:@"Punctuation"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"Punctuation"]);
  }
  if (sets & 1 << MorseSetProsigns)
  {
    [a addObjectsFromArray:[d objectForKey:@"Prosigns"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"Prosigns"]);
  }
  if (sets & 1 << MorseSetInternational)
  {
    [a addObjectsFromArray:[d objectForKey:@"International"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"International"]);
  }
  if (sets & 1 << MorseSetKoch)
  {
    [a addObjectsFromArray:[d objectForKey:@"Koch"]];
    //NSLog(@"%@ from %@", a, [d objectForKey:@"Koch"]);
  }
  return [a autorelease];
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

+(BOOL)isProsign:(NSString*)string
{
  unsigned i, n = [string length];
  for (i = 0; i < n; i++)
  {
    unichar chr = [string characterAtIndex:i];
    if (chr == 0x0305) return YES;
  }
  return NO;
}

+(NSString*)translateFromProsigns:(NSString*)string
{
  NSDictionary* d = [[Morse dictionary] objectForKey:@"ProsignToSymbol"];
  NSMutableString* s = [[NSMutableString alloc] initWithString:string];
  for (NSString* pro in [d allKeys])
    [s replaceOccurrencesOfString:pro withString:[d objectForKey:pro]
                                      options:NSCaseInsensitiveSearch
                                      range:NSMakeRange(0, [s length])];
  NSString* ret = [NSString stringWithString:s];
  [s release];
  return ret;
}

+(NSString*)translateToProsigns:(NSString*)string
{
  NSDictionary* d = [[Morse dictionary] objectForKey:@"SymbolToProsign"];
  NSMutableString* s = [[NSMutableString alloc] initWithString:string];
  for (NSString* pro in [d allKeys])
    [s replaceOccurrencesOfString:pro withString:[d objectForKey:pro]
                                      options:NSCaseInsensitiveSearch
                                      range:NSMakeRange(0, [s length])];
  NSString* ret = [NSString stringWithString:s];
  [s release];
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

-(uint16_t)feed:(double*)time
{
  // Put the event in the buffer
  if (time)
  {
    unsigned where = (_bufferStart + _bufferCount) % MorseBufferSize;
    if (_bufferCount == MorseBufferSize)
    {
      where = _bufferStart;
      _bufferStart++;
      if (_bufferStart >= MorseBufferSize) _bufferStart = 0;
    }
    double duration = *time - _lastTime;
    if (_lastTime)
    {
      _buffer[where] = duration;
      if (_bufferCount < MorseBufferSize) _bufferCount++;
      //char* type = (where % 2 == 0)? "tone":"space";
      //NSLog(@"Put %s %f ms at position %d (%d,%d)", type, duration, where, _bufferStart, _bufferCount);
    }
    _lastTime = *time;
  }
  return [self _recognize];
}

-(void)clear
{
  _bufferStart = 0;
  _bufferCount = 0;
  _lastTime = 0.0;
}

-(MorseRecognizerQuality)quality
{
  return _quality;
}

-(NSString*)description
{
  NSMutableString* s = [[NSMutableString alloc] init];
  int i = _bufferStart;
  float tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  float intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  float interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
  unsigned seen = 0;
  while (seen < _bufferCount)
  {
    float delta = _buffer[i];
    BOOL isTone = (i % 2 == 0);
    //NSLog(@"i=%d key %s", i, isKeyUp? "UP":"DOWN");
    if (isTone)
    {
      [s appendFormat:@"%C", (delta > 2.0 * tone)? '-':'.'];
    }
    else
    {
      if (delta > intercharacterCutoff)
      {
        // interword or intercharacter: emit character.
        if (delta > interwordCutoff)
        {
          [s appendString:@" "];
        }
        //else [s appendString:@"_"];
      }
    }
    seen++;
    i++;
    if (i >= MorseBufferSize) i = 0;
  }
  NSString* ret = [NSString stringWithFormat:@"<MR start=%d count=%d [%@]>", _bufferStart, _bufferCount, s];
  [s release];
  return ret;
}

-(uint16_t)_recognize
{
  uint16_t chr = MorseNoCharacter;
  uint16_t inProgress = 0x0000;
  //if (_bufferCount < 2) return inProgress;
  double twpm = 0.0;
  double swpm = 0.0;
  unsigned seen = 0;
  unsigned n = 0;
  unsigned nt = 0;
  unsigned ns = 0;
  float dev = 0.0;
  int i = _bufferStart;
  //NSLog(@"====== Start while loop");
  float tone = [Morse millisecondsPerUnitAtWPM:_wpm];
  MorseSpacing spacing = [Morse spacingForWPM:_wpm CWPM:_wpm];
  float intercharacterCutoff = (tone + spacing.intercharacterMilliseconds)/2.0L;
  float interwordCutoff = (spacing.intercharacterMilliseconds + spacing.interwordMilliseconds)/2.0L;
  //NSLog(@"intercharacterMilliseconds=%f, intercharacterCutoff=%f, interwordCutoff=%f", spacing.intercharacterMilliseconds, intercharacterCutoff, interwordCutoff);
  while (YES)
  {
    float delta = _buffer[i];
    BOOL isTone = (i % 2 == 0);
    //NSLog(@"i=%d seen=%d %s", i, seen, isTone? "TONE":"SPACE");
    if (isTone)
    {
      unsigned char len = inProgress & 0x0007;
      len++;
      inProgress = len | (inProgress & 0xFFF8);
      //NSLog(@"Tone: _buffer[%d] (%f) > 2.0 * tone (%f)? %s", i, _buffer[i], tone, (delta > 2.0 * tone)?"dah":"dit");
      if (delta > 2.0 * tone) inProgress |= 1 << (len+2);
      //NSLog(@"morse now 0x%04X (len %d)", inProgress, len);
      if (delta > 2.0 * tone) delta /= MorseDahUnits;
      if (delta) twpm += [Morse WPMPerUnitMilliseconds:delta];
      //NSLog(@"twpm now %f from delta %f", twpm, delta);
      nt++;
    }
    else
    {
      //NSLog(@"Space: _buffer[%d] (%f) > interchar cutoff (%f)? %s", i, _buffer[i], intercharacterCutoff, (delta > 2.0 * intercharacterCutoff)?"long":"short");
      if (delta > intercharacterCutoff)
      {
        // interword or intercharacter: emit character.
        seen++;
        chr = inProgress;
        //NSLog(@"Long space: _buffer[%d] (%f) > interword cutoff (%f)? %s (%d)", i, _buffer[i], interwordCutoff, (delta > interwordCutoff)?"YES":"NO", inProgress);
        if (delta > interwordCutoff)
        {
          if (inProgress == MorseNoCharacter) chr = MorseInterwordSpace;
          else seen--;
        }
        _bufferStart = (_bufferStart + seen) % MorseBufferSize;
        _bufferCount -= seen;
        //NSLog(@"Emit 0x%04X; _bufferStart %d, _bufferCount %d, seen %d", chr, _bufferStart, _bufferCount, seen);
      }
      if (delta > interwordCutoff) delta /= MorseInterwordUnits;
      else if (delta > intercharacterCutoff) delta /= MorseDahUnits;
      swpm += (delta)? [Morse WPMPerUnitMilliseconds:delta]:_wpm;
      //NSLog(@"swpm now %f from delta %f", swpm, delta);
      ns++;
    }
    dev += fmin(1.0,fabs((delta-tone)/tone));
    //NSLog(@"%d: dev now %f from %f = fabs((%f-%f)/%f) twpm %f, swpm %f", i, dev, fabs((delta-tone)/tone), delta, tone, tone, twpm, swpm);
    n++;
    if (chr) break;
    i++;
    if (i >= MorseBufferSize) i = 0;
    seen++;
    if (seen >= MorseBufferSize || seen >= _bufferCount) break;
  }
  if (n) _quality.quality = (1.0L - (dev/(float)n));
  if (nt) _quality.toneWPM = twpm/(float)nt;
  if (ns) _quality.spaceWPM = swpm/(float)ns;
  if (chr == MorseInterwordSpace) _lastTime = 0.0;
  //NSLog(@"q %f (t %f, s %f) from dev %f for %d units", _quality.quality, _quality.toneWPM, _quality.spaceWPM, dev, n);
  return chr;
}

-(float)WPM { return _wpm; }
-(void)setWPM:(float)wpm { _wpm = wpm; }
@end
