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

typedef struct
{
  // Filter #1 (Low band)
  double  lf;       // Frequency
  double  f1p0;     // Poles ...
  double  f1p1;     
  double  f1p2;
  double  f1p3;
  // Filter #2 (High band)
  double  hf;       // Frequency
  double  f2p0;     // Poles ...
  double  f2p1;
  double  f2p2;
  double  f2p3;
  // Sample history buffer
  double  sdm1;     // Sample data minus 1
  double  sdm2;     //                   2
  double  sdm3;     //                   3
  // Gain Controls
  double  lg;       // low  gain
  double  mg;       // mid  gain
  double  hg;       // high gain
} EQSTATE;

typedef enum
{
  MorseRendererWaveSine,
  MorseRendererWaveSaw,
  MorseRendererWaveSquare,
  MorseRendererWaveTriangle
} MorseRendererWaveType;

typedef enum
{
  MorseRendererAgendaMode,
  MorseRendererOnMode,
  MorseRendererOffMode,
  MorseRendererDecayMode // Used internally
} MorseRendererMode;

typedef struct
{
  LED*                  led;
  uint16_t*             agenda;
  NSDictionary*         offsets;
  float                 freq;     // Radians per sample
  float                 amp;
  float                 pan;
  float                 freqz;    // For dezipper filter
  float                 ampz;     // For dezipper filter
  float                 phase;    // Oscillator phase in radians
  float                 wpm;
  float                 cwpm;
  float                 samplesPerDit;
  float                 intercharacter;
  float                 interword;
  float                 weight;
  unsigned              agendaCount;
  unsigned              agendaDone;
  unsigned              agendaItemElementsDone;
  unsigned              agendaItemElementSamplesDone;
  MorseRendererMode     mode;
  MorseRendererMode     lastMode;
  MorseRendererWaveType waveType;
  BOOL                  doingInterelementSpace;
  BOOL                  doingLoopSpace;
  BOOL                  loop;
  BOOL                  play;
  BOOL                  wasOn;
  BOOL                  flash;
  BOOL                  noNote;
  // Noise stuff
  // Once I figure out how to synthesize genuine-sounding radio noise
  // I'll get rid of all this white/pink/brown crap.
  float                 qrn;
  EQSTATE               eq;
} MorseRenderState;

@interface MorseRenderer : NSObject <NSCopying>
{
  AUGraph          _ag;
  AudioUnit        _mixer;
  MorseRenderState _state;
  NSMutableString* _string;
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
-(void)setWeight:(float)val;
-(void)setWaveType:(MorseRendererWaveType)type;
-(void)setLoop:(BOOL)flag;
-(BOOL)flash;
-(void)setFlash:(BOOL)flag;
-(NSString*)string;
-(void)setString:(NSString*)s;
-(void)setState:(MorseRenderState*)s;
-(void)exportAIFF:(NSURL*)url;
@end
