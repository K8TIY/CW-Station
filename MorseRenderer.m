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
#import "MorseRenderer.h"

#include <mach/mach_error.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDUsageTables.h>


NSString* MorseRendererFinishedNotification = @"MorseRendererFinishedNotification";
static const float gSampleRate = 22050.0f;

@interface MorseRenderer (Private)
-(void)_updatePadding;
-(void)setAgenda:(NSArray*)strings;
@end



static OSStatus	MyRenderer(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags,
			      	             const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber,
				                   UInt32 inNumberFrames, AudioBufferList* ioData);
static void local_SendNote(void);
static io_service_t find_a_keyboard(void);
static void find_led_cookies(IOHIDDeviceInterface122** handle);
static HRESULT create_hid_interface(io_object_t hidDevice, IOHIDDeviceInterface*** hdi);
static void manipulate_led(UInt32 value);

// Audio processing callback
static OSStatus	MyRenderer(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags,
			      	             const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber,
				                   UInt32 inNumberFrames, AudioBufferList* ioData)
{
  float fadeSamples = gSampleRate * 0.004f;
  MorseRenderState* state = (MorseRenderState*)inRefCon;
  CGFloat phase = state->phase;
  CGFloat amp = state->amp;
  CGFloat freq = state->freq;
  CGFloat ampz = state->ampz;
  CGFloat freqz = state->freqz;
  CGFloat decay;
  float* lBuffer = ioData->mBuffers[0].mData;
  float* rBuffer = ioData->mBuffers[1].mData;
  uint16_t* item = NULL;
  uint16_t code = 0;
  BOOL gotNoise = NO;
  if (state->agenda && state->play)
  {
    item = &(state->agenda)[state->agendaDone];
    code = *item;
  }
  uint16_t lengthBits = code & 0x0007;
  uint16_t elements = lengthBits? lengthBits:1;
  BOOL on = NO;
  unsigned dits = 1;
  NSUInteger i;
  for (i = 0; i < inNumberFrames; i++)
  {
    float lsample = 0.0f;
    float rsample = 0.0f;
    if ((item && state->agendaDone < state->agendaCount) || state->mode == MorseRendererOnMode || state->mode == MorseRendererDecayMode)
    {
      if (state->mode == MorseRendererDecayMode && state->lastMode != MorseRendererDecayMode)
      {
        state->agendaItemElementSamplesDone = 0;
        state->lastMode = MorseRendererDecayMode;
      }
      if (state->mode == MorseRendererOnMode && state->lastMode != MorseRendererOnMode)
      {
        state->agendaItemElementSamplesDone = 0;
        state->lastMode = MorseRendererOnMode;
      }
      if (code == MorseInterelementSpace || state->doingInterelementSpace) dits = MorseDitUnits;
      else if (code == MorseIntercharacterSpace) dits = MorseDahUnits;
      else if (code == MorseInterwordSpace || state->doingLoopSpace) dits = MorseInterwordUnits;
      else
      {
        BOOL bit = (code >> (3 + state->agendaItemElementsDone)) & 0x0001;
        dits = (bit)? MorseDahUnits:MorseDitUnits;
        on = YES;
        if (state->mode == MorseRendererDecayMode)
        {
          decay = (fadeSamples - state->agendaItemElementSamplesDone) * (1.0/fadeSamples);
          decay = sin(M_PI_2 * decay);
          if (state->agendaItemElementSamplesDone >= fadeSamples)
          {
            state->mode = MorseRendererOffMode;
          }
          //if (decay != 1.0f) NSLog(@"decay %f from samples %d, %f", decay, state->agendaItemElementsDone, (1.0/fadeSamples));
        }
        else if (state->agendaItemElementSamplesDone < fadeSamples)
        {
          decay = state->agendaItemElementSamplesDone * (1.0/fadeSamples);
          decay = sin(M_PI_2 * decay);
          //if (decay != 1.0f) NSLog(@"decay %f from state->agendaItemElementSamplesDone (%d) * (1.0/%d)", decay, state->agendaItemElementSamplesDone, fadeSamples);
        }
        else if (state->mode != MorseRendererOnMode)
        {
          NSUInteger remaining = (dits * state->samplesPerDit) - state->agendaItemElementSamplesDone;
          if (remaining < fadeSamples)
          {
            decay = remaining * (1.0/fadeSamples);
            decay = sin(M_PI_2 * decay);
          }
          else decay = 1.0f;
          //if (decay != 1.0f) NSLog(@"decay %f from remaining (%d) * %f", decay, remaining, (1.0/fadeSamples));
        }
      }
      if (state->agendaItemElementsDone < elements || state->mode == MorseRendererOnMode || state->mode == MorseRendererDecayMode)
      {
        // This sample is on if not doing interelement and this is not a space character.
        if ((lengthBits > 0 && !state->doingInterelementSpace) || state->mode == MorseRendererOnMode || state->mode == MorseRendererDecayMode)
        {
          lsample = sinf(phase);
          if (ampz != 1.0f) lsample *= ampz;
          phase = phase + freqz;
          if (decay != 1.0f) lsample *= decay;
          rsample = lsample;
          if (lsample != 0.0f)
          {
            gotNoise = YES;
            lsample *= ((-2.0f * state->pan) + 2.0f);
            rsample *= (2.0f * state->pan);
          }
        }
      }
    }
    *lBuffer++ = lsample;
    *rBuffer++ = rsample;
    ampz  = 0.001f * amp  + 0.999f * ampz;
    freqz = 0.001f * freq + 0.999f * freqz;
    state->agendaItemElementSamplesDone++;
    if (state->wasOn != on)
    {
      state->wasOn = on;
      if (state->flash) manipulate_led(on);
    }
    if (item)
    {
      CGFloat needed = dits * state->samplesPerDit;
      if (!on)
      {
        if (dits == MorseDahUnits && state->intercharacter > 0.0L) needed = state->intercharacter;
        else if (dits == MorseInterwordUnits && state->interword > 0.0L) needed = state->interword;
      }
      if (state->agendaItemElementSamplesDone >= needed)
      {
        // If this is a nonfinal element, do interelement space. Otherwise move to next element.
        if (!state->doingInterelementSpace && on && state->agendaItemElementsDone < elements-1)
        {
          state->doingInterelementSpace = YES;
          on = NO;
        }
        else
        {
          (state->agendaItemElementsDone)++;
          state->doingInterelementSpace = NO;
          state->doingLoopSpace = NO;
          decay = 0.0f;
        }
        state->agendaItemElementSamplesDone = 0;
        phase = 0.0f;
        freqz = freq;
        ampz = amp;
        if (state->agendaItemElementsDone >= elements)
        {
          (state->agendaDone)++;
          state->agendaItemElementsDone = 0;
          if (state->mode != MorseRendererOnMode) item = &(state->agenda)[state->agendaDone];
        }
        //NSLog(@"%d/%d elements done", state->agendaItemElementsDone, elements);
        if (state->agendaDone >= state->agendaCount)
        {
          if (state->loop && state->mode != MorseRendererOnMode)
          {
            state->doingLoopSpace = YES;
            state->agendaDone = 0;
            item = &(state->agenda)[0];
          }
          else
          {
            item = NULL;
            state->play = NO;
            local_SendNote();
          }
        }
        //NSLog(@"item 0x%X", item);
      }
    }
    if (item) code = *item;
    else code = 0;
    lengthBits = code & 0x0007;
    elements = lengthBits? lengthBits:1;
  }
  state->phase = phase;
  state->freqz = freqz;
  state->ampz = ampz;
  state->lastMode = state->mode;
  if (!gotNoise) *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
  return kAudioHardwareNoError;
}

static void local_SendNote(void)
{
  NSAutoreleasePool* arp = [[NSAutoreleasePool alloc] init];
  NSNotification* note = [NSNotification notificationWithName:MorseRendererFinishedNotification object:nil];
  [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
  [arp release];
}

@implementation MorseRenderer
-(id)init
{
  self = [super init];
  _strings = [[NSArray alloc] init];
  AUNode node;
  AudioUnit unit;
	ComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_DefaultOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
  OSStatus err = NewAUGraph(&_ag);
  if (err) printf("NewAUGraph=%ld\n", (long)err);
  else
  {
    err = AUGraphOpen(_ag);
    if (!err) err = AUGraphAddNode(_ag, &desc, &node);
    if (!err) err = AUGraphNodeInfo(_ag, node, 0, &unit);
    if (err) printf("AUGraphOpen/AUGraphAddNode/AUGraphNodeInfo=%ld\n", (long)err);
    else
    {
      AudioStreamBasicDescription fmt;
      fmt.mSampleRate = gSampleRate;
      fmt.mFormatID = kAudioFormatLinearPCM;
      fmt.mFormatFlags = kAudioFormatFlagsCanonical | kAudioFormatFlagIsNonInterleaved;
      fmt.mBytesPerPacket = 4;
      fmt.mFramesPerPacket = 1;
      fmt.mBytesPerFrame = 4;
      fmt.mChannelsPerFrame = 2;
      fmt.mBitsPerChannel = 32;
      err = AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                 0, &fmt, sizeof(AudioStreamBasicDescription));
      if (err) printf ("AudioUnitSetProperty-SF=%4.4s, %ld\n", (char*)&err, (long)err);
      else
      {
        err = AUGraphInitialize(_ag);
        //CAShow(_ag);
        if (err) printf ("AUGraphInitialize=%ld\n", (long)err);
        AURenderCallbackStruct input;
        input.inputProc = MyRenderer;
        input.inputProcRefCon = &_state;
        err = AudioUnitSetProperty(unit, kAudioUnitProperty_SetRenderCallback, 
                                   kAudioUnitScope_Input, 0, &input, sizeof(input));
        if (err) printf ("AudioUnitSetProperty-CB=%ld\n", (long)err);
        err = AUGraphInitialize(_ag);
      }
    }
  }
  if (err)
  {
    [self dealloc];
    self = nil;
  }
	return self;
}


-(void)setAmpVal:(float)val
{
  _state.amp = val;
  _state.ampz = val;
}

-(void)setFreqVal:(float)val
{
  _state.freq = val * 2.0f * 3.14159265359f / gSampleRate;
  _state.freqz = _state.freq;
}

-(void)setWPMVal:(float)val
{
  _state.wpm = val;
  [self _updatePadding];
}

-(void)setCWPMVal:(float)val
{
  _state.cwpm = val;
  _state.samplesPerDit = 1.2f/val * gSampleRate;
  [self _updatePadding];
}

-(void)setPan:(float)val
{
  if (val < 0.0) val = 0.0f;
  if (val > 1.0) val = 1.0f;
  _state.pan = val;
}


-(void)setLoop:(BOOL)flag {_state.loop = flag;}
-(BOOL)flash { return _state.flash; }
-(void)setFlash:(BOOL)flag { _state.flash = flag; }

-(void)_updatePadding
{
  MorseSpacing spacing = [Morse spacingForWPM:_state.wpm CWPM:_state.cwpm];
  _state.intercharacter = spacing.intercharacterMilliseconds / 1000.0L * gSampleRate;
  _state.interword = spacing.interwordMilliseconds / 1000.0L * gSampleRate;
  //NSLog(@"intercharacter %f sec, interword %f sec", tc, tw);
}

-(void)setAgenda:(NSArray*)str
{
  [self setStrings:str];
  if (_state.agenda) free(_state.agenda);
  _state.agenda = NULL;
  if (str) _state.agenda = [Morse morseFromStrings:_strings length:&_state.agendaCount];
}

-(void)setMode:(MorseRendererMode)mode
{
  if (_state.mode != mode)
  {
    if (mode == MorseRendererOffMode) mode = MorseRendererDecayMode;
    _state.mode = mode;
    if (mode == MorseRendererAgendaMode) [self stop];
    else [self start:nil];
  }
}

-(void)start:(NSArray*)str
{
  if (!_state.play)
  {
    if (str) [self setAgenda:str];
    // initialize phase and de-zipper filters.
    _state.phase = 0.0f;
    _state.freqz = _state.freq;
    _state.ampz = _state.amp;
    _state.agendaDone = 0;
    _state.agendaItemElementsDone = 0;
    _state.agendaItemElementSamplesDone = 0;
    OSStatus err = AUGraphStart(_ag);
    if (err) printf ("AUGraphStart=%ld\n", (long)err);
    else _state.play = YES;
  }
}

-(void)stop
{
  OSStatus err = AUGraphStop(_ag);
  if (err) NSLog(@"AUGraphStop=%ld\n", err);
  if (_state.agenda) free(_state.agenda);
  _state.agenda = NULL;
  _state.agendaCount = 0;
  _state.agendaDone = 0;
	_state.agendaItemElementsDone = 0;
	_state.agendaItemElementSamplesDone = 0;
  _state.doingInterelementSpace = NO;
  _state.doingLoopSpace = NO;
  _state.play = NO;
  _state.wasOn = NO;
  manipulate_led(0);
}

-(BOOL)isPlaying {return _state.play;}

-(void)setStrings:(NSArray*)str
{
  [str retain];
  [_strings release];
  _strings = str;
}

-(NSArray*)strings { return _strings; }
@end


static io_service_t find_a_keyboard(void)
{
  io_service_t result = (io_service_t)0;
  CFNumberRef usagePageRef = (CFNumberRef)0;
  CFNumberRef usageRef = (CFNumberRef)0;
  CFMutableDictionaryRef matchingDictRef = (CFMutableDictionaryRef)0;

  if (!(matchingDictRef = IOServiceMatching(kIOHIDDeviceKey))) return result;
  UInt32 usagePage = kHIDPage_GenericDesktop;
  UInt32 usage = kHIDUsage_GD_Keyboard;
  if (!(usagePageRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usagePage))) goto out;
  if (!(usageRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage))) goto out;
  CFDictionarySetValue(matchingDictRef, CFSTR(kIOHIDPrimaryUsagePageKey), usagePageRef);
  CFDictionarySetValue(matchingDictRef, CFSTR(kIOHIDPrimaryUsageKey), usageRef);
  result = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDictRef);
out:
  if (usageRef) CFRelease(usageRef);
  if (usagePageRef) CFRelease(usagePageRef);
  return result;
}

static IOHIDElementCookie capslock_cookie = (IOHIDElementCookie)0;
static IOHIDElementCookie numlock_cookie  = (IOHIDElementCookie)0;
static void find_led_cookies(IOHIDDeviceInterface122** handle)
{
  IOHIDElementCookie cookie;
  CFTypeRef          object;
  long               number;
  long               usage;
  long               usagePage;
  CFArrayRef         elements;
  CFDictionaryRef    element;
  IOReturn           result;

  if (!handle || !(*handle)) return;
  result = (*handle)->copyMatchingElements(handle, NULL, &elements);
  if (result != kIOReturnSuccess) return;
  CFIndex i;
  for (i = 0; i < CFArrayGetCount(elements); i++)
  {
    element = CFArrayGetValueAtIndex(elements, i);
    object = (CFDictionaryGetValue(element, CFSTR(kIOHIDElementCookieKey)));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID()) continue;
    if (!CFNumberGetValue((CFNumberRef) object, kCFNumberLongType, &number)) continue;
    cookie = (IOHIDElementCookie)number;
    object = CFDictionaryGetValue(element, CFSTR(kIOHIDElementUsageKey));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID()) continue;
    if (!CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &number)) continue;
    usage = number;
    object = CFDictionaryGetValue(element,CFSTR(kIOHIDElementUsagePageKey));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID()) continue;
    if (!CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &number)) continue;
    usagePage = number;
    if (usagePage == kHIDPage_LEDs)
    {
      switch (usage)
      {
        case kHIDUsage_LED_NumLock:
        numlock_cookie = cookie;
        break;

        case kHIDUsage_LED_CapsLock:
        capslock_cookie = cookie;
        break;

        default:
        break;
      }
    }
  }
}

static HRESULT create_hid_interface(io_object_t hidDevice, IOHIDDeviceInterface*** hdi)
{
  IOCFPlugInInterface** plugInInterface = NULL;
  io_name_t className;
  HRESULT   plugInResult = S_OK;
  SInt32    score = 0;
  IOReturn  ioReturnValue;

  ioReturnValue = IOObjectGetClass(hidDevice, className);
  if (ioReturnValue != kIOReturnSuccess) return S_FALSE;
  ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice, kIOHIDDeviceUserClientTypeID,
                                                    kIOCFPlugInInterfaceID, &plugInInterface, &score);
  if (ioReturnValue != kIOReturnSuccess) return S_FALSE;
  plugInResult = (*plugInInterface)->QueryInterface(plugInInterface,
                   CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID)hdi);
  (*plugInInterface)->Release(plugInInterface);
  return plugInResult;
}

static void manipulate_led(UInt32 value)
{
  static UInt32 whichLED = kHIDUsage_LED_CapsLock;
  io_service_t           hidService = (io_service_t)0;
  io_object_t            hidDevice = (io_object_t)0;
  IOHIDDeviceInterface **hidDeviceInterface = NULL;
  IOReturn               ioReturnValue = kIOReturnError;
  IOHIDElementCookie     theCookie = (IOHIDElementCookie)0;
  IOHIDEventStruct       theEvent;
  HRESULT                result;
  
  if (!(hidService = find_a_keyboard()))
  {
    //fprintf(stderr, "No keyboard found.\n");
    return;
  }
  hidDevice = (io_object_t)hidService;
  result = create_hid_interface(hidDevice, &hidDeviceInterface);
  if (result != S_OK) return;
  find_led_cookies((IOHIDDeviceInterface122**)hidDeviceInterface);
  ioReturnValue = IOObjectRelease(hidDevice);
  if (ioReturnValue != kIOReturnSuccess) goto out;
  ioReturnValue = kIOReturnError;
  if (hidDeviceInterface == NULL)
  {
    //fprintf(stderr, "Failed to create HID device interface.\n");
    return;
  }
  if (whichLED == kHIDUsage_LED_NumLock) theCookie = numlock_cookie;
  else if (whichLED == kHIDUsage_LED_CapsLock) theCookie = capslock_cookie;
  if (theCookie == 0)
  {
    //fprintf(stderr, "Bad or missing LED cookie.\n");
    goto out;
  }
  ioReturnValue = (*hidDeviceInterface)->open(hidDeviceInterface, 0);
  if (ioReturnValue != kIOReturnSuccess)
  {
    //fprintf(stderr, "Failed to open HID device interface.\n");
    goto out;
  }
  ioReturnValue = (*hidDeviceInterface)->getElementValue(hidDeviceInterface, theCookie, &theEvent);
  if (ioReturnValue != kIOReturnSuccess)
  {
    (void)(*hidDeviceInterface)->close(hidDeviceInterface);
    goto out;
  }
  if (value != -1)
  {
    if (theEvent.value != value)
    {
      theEvent.value = value;
      ioReturnValue = (*hidDeviceInterface)->setElementValue(hidDeviceInterface, theCookie, &theEvent, 0, 0, 0, 0);
    }
  }
  ioReturnValue = (*hidDeviceInterface)->close(hidDeviceInterface);
out:
  (void)(*hidDeviceInterface)->Release(hidDeviceInterface);
}
