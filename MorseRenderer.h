#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreAudio/AudioHardware.h>
#import <CoreServices/CoreServices.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Morse.h"

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
  uint16_t* agenda;
  NSDictionary* offsets;
  CGFloat freq;
  CGFloat amp;
  CGFloat pan;
	CGFloat freqz;    // for dezipper filter
  CGFloat ampz;	    // for dezipper filter
	CGFloat phase;		// oscillator phase in radians
  CGFloat wpm;
  CGFloat cwpm;
  CGFloat samplesPerDit;
  CGFloat intercharacter;
  CGFloat interword;
  NSUInteger agendaCount;
  NSUInteger agendaDone;
	NSUInteger agendaItemElementsDone;
	NSUInteger agendaItemElementSamplesDone;
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
  CGFloat qrn;
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

//@property (copy, readwrite) NSString* string;
@property (readwrite) BOOL flash;
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
-(NSString*)string;
-(void)setString:(NSString*)s;
-(void)setState:(MorseRenderState*)s;
-(void)exportAIFFToURL:(NSURL*)url;
@end
