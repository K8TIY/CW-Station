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

extern uint16_t MorseNoCharacter;
extern uint16_t MorseInterelementSpace;
extern uint16_t MorseIntercharacterSpace;
extern uint16_t MorseInterwordSpace;

extern uint8_t  MorseDitUnits;
extern uint8_t  MorseDahUnits;
extern uint8_t  MorseInterwordUnits;

enum
{
  MorseSetLetters,
  MorseSetNumbers,
  MorseSetPunctuation,
  MorseSetProsigns,
  MorseSetInternational,
  MorseSetKoch
};

typedef struct
{
  float intercharacterMilliseconds;
  float interwordMilliseconds;
} MorseSpacing;

@interface Morse : NSObject
{}
+(float)millisecondsPerUnitAtWPM:(float)wpm;
+(float)WPMPerUnitMilliseconds:(float)time;
+(MorseSpacing)spacingForWPM:(float)wpm CWPM:(float)cwpm;
+(NSDictionary*)dictionary;
+(NSDictionary*)reverseDictionary;
+(NSString*)stringFromMorse:(uint16_t)morse;
+(uint16_t*)morseFromString:(NSString*)string withDelay:(BOOL)del
            length:(unsigned*)outLength offsets:(NSDictionary**)offsets;
+(NSArray*)charactersFromSets:(unsigned)sets;
+(NSString*)formatString:(NSString*)string;
+(BOOL)isProsign:(NSString*)string;
+(NSString*)translateFromProsigns:(NSString*)string;
+(NSString*)translateToProsigns:(NSString*)string;
@end

typedef struct
{
  double quality;
  double toneWPM;
  double spaceWPM;
} MorseRecognizerQuality;

#define MorseBufferSize (32)
@interface MorseRecognizer : NSObject
{
  double _buffer[MorseBufferSize];
  double _lastTime;
  unsigned _bufferCount;
  unsigned _bufferStart;
  float _wpm;
  MorseRecognizerQuality _quality;
}
-(id)initWithWPM:(float)wpm;
-(uint16_t)feed:(double*)time;
-(void)clear;
-(MorseRecognizerQuality)quality;
-(float)WPM;
-(void)setWPM:(float)wpm;
@end
