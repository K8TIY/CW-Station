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
  CGFloat intercharacterMilliseconds;
  CGFloat interwordMilliseconds;
} MorseSpacing;

@interface Morse : NSObject
{}
+(CGFloat)millisecondsPerUnitAtWPM:(CGFloat)wpm;
+(CGFloat)WPMPerUnitMilliseconds:(CGFloat)time;
+(MorseSpacing)spacingForWPM:(CGFloat)wpm CWPM:(CGFloat)cwpm;
+(NSDictionary*)dictionary;
+(NSDictionary*)reverseDictionary;
+(NSString*)stringFromMorse:(uint16_t)morse;
+(uint16_t*)morseFromStrings:(NSArray*)strings length:(NSUInteger*)outLength;
+(NSArray*)letters;
+(NSArray*)numbers;
+(NSArray*)lettersAndNumbers;
+(NSArray*)punctuation;
+(NSArray*)prosigns;
+(NSString*)formatStrings:(NSArray*)strings;
+(NSArray*)splitString:(NSString*)string;
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
  CGFloat _wpm;
}
-(id)initWithWPM:(CGFloat)wpm;
-(uint16_t)feed:(double*)duration;
-(MorseRecognizerQuality)quality;
-(CGFloat)WPM;
-(void)setWPM:(CGFloat)wpm;
@end