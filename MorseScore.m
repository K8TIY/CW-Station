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
#import "MorseScore.h"

static NSString* local_BinaryStringForByte(uint8_t b);
#define BA_DOTEST 0
#if BA_DOTEST
static void local_TestBitArray(void);
#endif

@implementation MorseScore
#if BA_DOTEST
+(void)initialize
{
  local_TestBitArray();
}
#endif

-(id)init
{
  self = [super init];
  _dict = [[NSMutableDictionary alloc] init];
  return self;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
  self = [self init];
  for (NSString* key in dict) 
  {
    BitArray* ba = nil;
    id obj = [dict objectForKey:key];
    if ([obj isKindOfClass:[NSDictionary class]])
    {
      unsigned n = [[obj objectForKey:@"n"] unsignedIntValue];
      unsigned of = [[obj objectForKey:@"of"] unsignedIntValue];
      ba = [[BitArray alloc] initWithCapacity:of];
      unsigned i;
      for (i = 0; i < n; i++) [ba setBit:1 atIndex:i];
    }
    else if ([obj isKindOfClass:[NSString class]])
    {
      ba = [[BitArray alloc] initWithString:obj];
    }
    if (ba)
    {
      [_dict setObject:ba forKey:key];
      [ba release];
    }
  }
  //NSLog(@"Score: %@", self);
  return self;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"%@", _dict];
}

-(NSDictionary*)dictionaryRepresentation
{
  NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
  for (NSString* key in _dict)
  {
    BitArray* ba = [_dict objectForKey:key];
    [d setObject:[ba string] forKey:key];
  }
  return [d autorelease];
}

-(unsigned)count { return [_dict count]; }
-(NSArray*)allKeys { return [_dict allKeys]; }

// Returns from 0.0 to 1.0 inclusive.
-(float)scoreForString:(NSString*)s
{
  float score = 0.0;
  BitArray* ba = [_dict objectForKey:s];
  if (ba)
  {
    float n = (float)[ba count1Bits];
    float of = (float)[ba capacity];
    score = n / of;
  }
  return score;
}

static unsigned const maxScoreBits = 128;
-(void)addObservation:(BOOL)good forString:(NSString*)s
{
  BitArray* ba = [_dict objectForKey:s];
  if (!ba)
  {
    ba = [[BitArray alloc] initWithCapacity:0];
    [_dict setObject:ba forKey:s];
    [ba release];
  }
  unsigned cap = [ba capacity];
  if (cap < maxScoreBits)
  {
    cap++;
    [ba setCapacity:cap];
  }
  [ba shiftRightBits:1];
  [ba setBit:good atIndex:0];
  //NSLog(@"%s for %@: now %@", (good)?"correct":"INcorrect", s, ba);
}

-(unsigned)countObservationsForString:(NSString*)s
{
  return [[_dict objectForKey:s] capacity];
}

-(void)clear
{
  [_dict removeAllObjects];
}
@end

@implementation BitArray
-(BitArray*)initWithCapacity:(unsigned)bits
{
  self = [super init];
  [self setCapacity:bits];
  return self;
}

-(BitArray*)initWithString:(NSString*)string
{
  unsigned bits = [string length];
  self = [self initWithCapacity:bits];
  unsigned i, n = [string length];
  for (i = 0; i < n; i++)
    [self setBit:([string characterAtIndex:i]=='1') atIndex:i];
  return self;
}

-(void)dealloc
{
  if (_bits) free(_bits);
  [super dealloc];
}

-(NSString*)description
{
  NSMutableString* s = [[NSMutableString alloc] initWithFormat:@"<BitArray capacity %d", _capacity];
  unsigned i;
  for (i = 0; i < _capacity; i++)
  {
    [s appendFormat:@"%s%C", (i%8)? "":" ", [self bitAtIndex:i]? '1':'0'];
  }
  unsigned bytes = _capacity >> 3;
  if (_capacity % 8) bytes++;
  [s appendFormat:@" (%d bytes:", bytes];
  for (i = 0; i < bytes; i++) [s appendFormat:@" 0x%02X", _bits[i]];
  [s appendString:@")>"];
  return [s autorelease];
}

-(NSString*)string
{
  NSMutableString* s = [[NSMutableString alloc] init];
  unsigned i;
  for (i = 0; i < _capacity; i++)
    [s appendString:([self bitAtIndex:i])? @"1":@"0"];
  NSString* ret = [NSString stringWithString:s];
  [s release];
  return ret;
}

-(unsigned)count1Bits
{
  unsigned n = 0;
  unsigned i;
  for (i = 0; i < _capacity; i++)
  {
    if ([self bitAtIndex:i]) n++;
  }
  return n;
}

-(unsigned)capacity { return _capacity; }

-(void)setCapacity:(unsigned)bits
{
  unsigned bytes = bits >> 3;
  if (bits % 8) bytes++;
  uint8_t* newbits = calloc(sizeof(uint8_t), bytes);
  if (_bits)
  {
    unsigned oldbytes = _capacity >> 3;
    if (_capacity % 8) oldbytes++;
    bytes = MIN(bytes,oldbytes);
    memcpy(newbits,_bits,bytes);
  }
  _bits = newbits;
  _capacity = bits;
}

-(BOOL)bitAtIndex:(unsigned)i
{
  if (i >= _capacity) return 0;
  unsigned whichByte = i >> 3;
  unsigned whichBit = 7 - (i % 8);
  //NSLog(@"bitAtIndex:%d (byte %d) returns %@ & 1 << %d", i, whichByte, local_BinaryStringForByte(_bits[whichByte]), whichBit);
  return _bits[whichByte] & (1 << whichBit);
}

-(void)setBit:(BOOL)on atIndex:(unsigned)i
{
  if (i >= _capacity) [self setCapacity:i+1];
  unsigned whichByte = i >> 3;
  unsigned whichBit = 7 - (i % 8);
  if (on) _bits[whichByte] |= (1 << whichBit);
  else _bits[whichByte] &= (~(1 << whichBit));
}

-(void)shiftLeftBits:(unsigned)n
{
  if (n == 0 || n > 7) return;
  //BOOL shift = NO;
  unsigned bytes = _capacity >> 3;
  if (_capacity % 8) bytes++;
  unsigned i;
  uint8_t mask = 1 << 7;
  if (n >= 2) mask |= 1 << 6;
  if (n >= 3) mask |= 1 << 5;
  if (n >= 4) mask |= 1 << 4;
  if (n >= 5) mask |= 1 << 3;
  if (n >= 6) mask |= 1 << 2;
  if (n == 7) mask |= 1 << 1;
  uint8_t masked = 0;
  for (i = 0; i < bytes; i++)
  {
    unsigned m = bytes - i - 1;
    uint8_t newbyte = _bits[m];
    uint8_t newmasked = newbyte & mask;
    //NSLog(@"iter %d m %d mask %@ masked %@ newbyte %@ newmasked %@", i, m,
    //  local_BinaryStringForByte(mask), local_BinaryStringForByte(masked),
    //  local_BinaryStringForByte(newbyte), local_BinaryStringForByte(newmasked));
    newbyte <<= n;
    //NSLog(@"newbyte %@ << %d", local_BinaryStringForByte(newbyte), n);
    if (masked) newbyte |= (masked >> (8 - n));
    //NSLog(@"writing %@", local_BinaryStringForByte(newbyte));
    _bits[m] = newbyte;
    masked = newmasked;
  }
}

-(void)shiftRightBits:(unsigned)n
{
  if (n == 0 || n > 7) return;
  //BOOL shift = NO;
  unsigned bytes = _capacity >> 3;
  if (_capacity % 8) bytes++;
  unsigned i;
  uint8_t mask = 1;
  if (n >= 2) mask |= 1 << 1;
  if (n >= 3) mask |= 1 << 2;
  if (n >= 4) mask |= 1 << 3;
  if (n >= 5) mask |= 1 << 4;
  if (n >= 6) mask |= 1 << 5;
  if (n == 7) mask |= 1 << 6;
  uint8_t masked = 0;
  for (i = 0; i < bytes; i++)
  {
    uint8_t newbyte = _bits[i];
    uint8_t newmasked = newbyte & mask;
    //NSLog(@"iter %d mask %@ masked %@ newbyte %@ newmasked %@", i,
    //  local_BinaryStringForByte(mask), local_BinaryStringForByte(masked),
    //  local_BinaryStringForByte(newbyte), local_BinaryStringForByte(newmasked));
    newbyte >>= n;
    //NSLog(@"newbyte %@ >> %d", local_BinaryStringForByte(newbyte), n);
    if (masked) newbyte |= (masked << (8 - n));
    //NSLog(@"writing %@", local_BinaryStringForByte(newbyte));
    _bits[i] = newbyte;
    masked = newmasked;
  }
}
@end

static NSString* local_BinaryStringForByte(uint8_t b)
{
  return [NSString stringWithFormat:@"%C%C%C%C%C%C%C%C [0x%02X]",
    (b&(1<<7))?'1':'0',
    (b&(1<<6))?'1':'0',
    (b&(1<<5))?'1':'0',
    (b&(1<<4))?'1':'0',
    (b&(1<<3))?'1':'0',
    (b&(1<<2))?'1':'0',
    (b&(1<<1))?'1':'0',
    (b&(1))?'1':'0',b];
}

#if BA_DOTEST
static void local_TestBitArray(void)
{
  BitArray* ba = [[BitArray alloc] initWithCapacity:0];
  unsigned i;
  for (i = 0; i < 8; i++) [ba setBit:YES atIndex:i];
  NSLog(@"1 %@", [ba description]);
  [ba setCapacity:9];
  NSLog(@"2 %@", [ba description]);
  [ba shiftRightBits:1];
  NSLog(@"3 %@", [ba description]);
  [ba setBit:1 atIndex:0];
  NSLog(@"4 %@", [ba description]);
}
#endif
