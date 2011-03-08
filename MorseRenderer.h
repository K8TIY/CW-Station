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

typedef enum
{
  MorseRendererAgendaMode,
  MorseRendererOnMode,
  MorseRendererOffMode,
  MorseRendererDecayMode // Used internally
} MorseRendererMode;

typedef struct
{
  uint16_t* agenda;
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
} MorseRenderState;

@interface MorseRenderer : NSObject
{
  AUGraph           _ag;
  MorseRenderState  _state;
  NSMutableString*  _string;
  BOOL              _ok;
}

//@property (copy, readwrite) NSString* string;
@property (readwrite) BOOL flash;
-(BOOL)isPlaying;
-(void)setMode:(MorseRendererMode)mode;
-(void)start:(NSString*)string;
-(void)stop;
-(void)setAmpVal:(float)val;
-(void)setFreqVal:(float)val;
-(void)setWPMVal:(float)val;
-(void)setCWPMVal:(float)val;
-(void)setPan:(float)val;
-(void)setLoop:(BOOL)flag;
-(NSString*)string;
@end
