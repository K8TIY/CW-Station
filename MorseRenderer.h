#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreAudio/AudioHardware.h>
#import <CoreServices/CoreServices.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Morse.h"
#import "LED.h"

extern NSString* MorseRendererFinishedNotification;
extern NSString* MorseRendererStartedWordNotification;

typedef enum
{
  MorseRendererAgendaMode,
  MorseRendererOnMode,
  MorseRendererOffMode,
  MorseRendererDecayMode // Used internally
} MorseRendererMode;

#define kPinkMaxRandomRows 32
#define kPinkRandomBits    30
#define kPinkRandomShift   ((sizeof(long)*8)-kPinkRandomBits)

typedef struct
{
  LED* led;
  uint16_t* agenda;
  NSDictionary* offsets;
  float freq;
  float amp;
  float pan;
  float freqz;    // for dezipper filter
  float ampz;     // for dezipper filter
  float phase;    // oscillator phase in radians
  float wpm;
  float cwpm;
  float samplesPerDit;
  float intercharacter;
  float interword;
  unsigned agendaCount;
  unsigned agendaDone;
  unsigned agendaItemElementsDone;
  unsigned agendaItemElementSamplesDone;
  MorseRendererMode mode;
  MorseRendererMode lastMode;
  BOOL doingInterelementSpace;
  BOOL doingLoopSpace;
  BOOL loop;
  BOOL play;
  BOOL wasOn;
  BOOL flash;
  BOOL noNote;
  // Noise stuff
  float qrn;
  long pinkRows[kPinkMaxRandomRows];
  long pinkRunningSum;    // Used to optimize summing of generators
  int  pinkIndex;         // Incremented each sample
  int  pinkIndexMask;     // Index wrapped by &ing with this mask
  float pinkScalar;       // Used to scale within range of -1.0 to 1.0
  BOOL goWhite;
} MorseRenderState;

@interface MorseRenderer : NSObject <NSCopying>
{
  AUGraph           _ag;
  AudioUnit         _mixer;
  MorseRenderState  _state;
  NSMutableString*  _string;
}

-(BOOL)isPlaying;
-(void)setMode:(MorseRendererMode)mode;
-(void)start:(NSString*)string;
-(void)stop;
-(void)setAmp:(float)val;
-(void)setFreq:(float)val;
-(void)setWPM:(float)val;
-(void)setCWPM:(float)val;
-(void)setPan:(float)val;
-(void)setQRN:(float)val;
-(void)setQRNWhite:(BOOL)flag;
-(void)setLoop:(BOOL)flag;
-(BOOL)flash;
-(void)setFlash:(BOOL)flag;
-(NSString*)string;
-(void)setString:(NSString*)s;
-(void)setState:(MorseRenderState*)s;
-(void)exportAIFF:(NSString*)path;
@end
