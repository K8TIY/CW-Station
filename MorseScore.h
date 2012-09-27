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
#import <Cocoa/Cocoa.h>

extern unsigned const MorseScoreMaxObservations;

@interface MorseScore : NSObject
{
  NSMutableDictionary* _dict; // String -> bit array of last 100 correctnesses.
}
-(id)initWithDictionary:(NSDictionary*)dict;
-(NSDictionary*)dictionaryRepresentation;
-(unsigned)count;
-(NSArray*)allKeys;
-(float)scoreForString:(NSString*)s;
-(void)addObservation:(BOOL)good forString:(NSString*)s;
-(unsigned)countObservationsForString:(NSString*)s;
-(void)clear;
@end

@interface BitArray : NSObject
{
  unsigned _capacity;
  uint8_t* _bits;
}
-(BitArray*)initWithCapacity:(unsigned)bits;
-(BitArray*)initWithString:(NSString*)string;
-(NSString*)string;
-(unsigned)count1Bits;
-(unsigned)capacity;
-(void)setCapacity:(unsigned)bits;
-(BOOL)bitAtIndex:(unsigned)i;
-(void)setBit:(BOOL)on atIndex:(unsigned)i;
-(void)shiftLeftBits:(unsigned)n;
-(void)shiftRightBits:(unsigned)n;
@end
