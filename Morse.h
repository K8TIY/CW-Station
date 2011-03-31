#import <Cocoa/Cocoa.h>

@interface NSArray (StringComparison)
-(BOOL)isEqual:(NSArray*)other;
@end

extern uint16_t MorseNoCharacter;
extern uint16_t MorseInterelementSpace;
extern uint16_t MorseIntercharacterSpace;
extern uint16_t MorseInterwordSpace;

extern uint8_t  MorseDitUnits;
extern uint8_t  MorseDahUnits;
extern uint8_t  MorseInterwordUnits;

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
+(uint16_t*)morseFromString:(NSString*)string length:(unsigned*)outLength offsets:(NSDictionary**)offsets;
+(NSArray*)letters;
+(NSArray*)numbers;
+(NSArray*)lettersAndNumbers;
+(NSArray*)punctuation;
+(NSArray*)prosigns;
+(NSString*)formatString:(NSString*)string;
@end

typedef struct
{
  double quality;
  double toneWPM;
  double spaceWPM;
} MorseRecognizerQuality;

#define MorseBufferSize (18)
@interface MorseRecognizer : NSObject
{
  double _buffer[MorseBufferSize];
  unsigned _bufferCount; 
  unsigned _bufferStart;
  float _wpm;
}
-(id)initWithWPM:(float)wpm;
-(uint16_t)feed:(double*)duration;
-(MorseRecognizerQuality)quality;
-(float)WPM;
-(void)setWPM:(float)wpm;
@end
