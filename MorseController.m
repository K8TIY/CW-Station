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
#import "MorseController.h"
#import "Levenshtein.h"
#import "Onizuka.h"
#import "QSO.h"
#import <Security/Security.h>
#import <unistd.h>
#import <CoreFoundation/CoreFoundation.h>

enum
{
  CWSNotTestingState,
  CWSPlayingState,
  CWSWaitingState,
  CWSShowingState,
  CWSSendingState
};

static CGEventRef TapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon);
static CGEventTimestamp UpTimeInNanoseconds(void);

@interface MorseController (Private)
-(void)gotoState:(unsigned)s;
-(void)startNewTest;
-(BOOL)checkTestResponseWithFeedback:(BOOL)fb;
-(void)updateScore;
-(void)updateScoreForString:(NSString*)s correct:(BOOL)correct;
-(NSString*)randomStringFromArray:(NSArray*)array ofLength:(unsigned)length;
-(void)shiftKey:(BOOL)isdown atTime:(CGEventTimestamp)time fromTimer:(BOOL)flag;
-(void)keycheck:(CGEventRef)event;
-(void)timer:(NSTimer*)t;
-(void)gotText:(NSNotification*)note;
-(void)renderDone:(NSNotification*)note;
-(void)wordStarted:(NSNotification*)note;
-(void)tintChanged:(NSNotification*)note;
@end


@implementation MorseController
-(void)awakeFromNib
{
  [[Onizuka sharedOnizuka] localizeMenu:[[NSApplication sharedApplication] mainMenu]];
  [[Onizuka sharedOnizuka] localizeWindow:window];
  [[Onizuka sharedOnizuka] localizeWindow:prefsWindow];
  [topBLV setCanBecomeFirstResponder:NO];
  [bottomBLV setFormatProsign:YES];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSString* where = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithContentsOfFile:where];
  [d setValue:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:@"correctColor"];
  [d setValue:[NSArchiver archivedDataWithRootObject:[NSColor redColor]] forKey:@"incorrectColor"];
  for (NSString* key in d)
    [defs addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
  [[NSUserDefaults standardUserDefaults] registerDefaults:d];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(renderDone:) name:MorseRendererFinishedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordStarted:) name:MorseRendererStartedWordNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotText:) name:BigLetterViewTextNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tintChanged:) name:NSControlTintDidChangeNotification object:nil];
  [self tintChanged:nil];
  [tabs selectTabViewItemWithIdentifier:[[NSUserDefaults standardUserDefaults] objectForKey:@"tab"]];
  score = [[NSMutableDictionary alloc] init];
  NSDictionary* scoredic = [[NSUserDefaults standardUserDefaults] objectForKey:@"score"];
  for (NSString* key in scoredic) 
  {
    NSDictionary* dic = [scoredic objectForKey:key];
    NSMutableDictionary* sdic = [dic mutableCopy];
    [score setObject:sdic forKey:key];
    [sdic release];
  }
  [scoreTable reloadData];
  words = [[Wordlist alloc] init];
  [window makeKeyAndOrderFront:self];
  if (!AXIsProcessTrusted() && !AXAPIEnabled())
  {
    AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [authView setAuthorizationRights:&rights];
    [authView setDelegate:self];
    [authView setAutoupdate:YES];
    [[Onizuka sharedOnizuka] localizeWindow:authWindow];
    [authWindow makeKeyAndOrderFront:self];
  }
  else
  {
    ProcessSerialNumber psn;
    (void)GetProcessForPID(getpid(), &psn);
    _tap = CGEventTapCreateForPSN(&psn, kCGTailAppendEventTap, kCGEventTapOptionListenOnly,
                                  CGEventMaskBit(kCGEventFlagsChanged), TapCallback, self);
    if (_tap)
    {
      _src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _tap, 0);
      CFRunLoopAddSource(CFRunLoopGetMain(), _src, kCFRunLoopCommonModes);
      CGEventTapEnable(_tap, false);
    }
    else NSLog(@"Could not create event tap");
  }
  qso = [[NSMutableArray alloc] init];
  recognizer = [[MorseRecognizer alloc]
                   initWithWPM:[[[NSUserDefaults standardUserDefaults] objectForKey:@"wpm"] doubleValue]];
}

-(void)dealloc
{
  [words release];
  [recognizer release];
  [qso release];
  [super dealloc];
}

#pragma mark Action
-(IBAction)startStop:(id)sender
{
  if (state == CWSNotTestingState)
  {
    if ([[[tabs selectedTabViewItem] identifier] isEqual:@"4"]) [self gotoState:CWSSendingState];
    else [self gotoState:CWSPlayingState];
  }
  else [self gotoState:CWSNotTestingState];
}

-(IBAction)clearScore:(id)sender
{
  [score removeAllObjects];
  [scoreTable reloadData];
}

-(IBAction)repan:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setFloat:0.5f forKey:@"pan"];
}

-(IBAction)genQSO:(id)sender
{
  #pragma unused (sender)
  [inputField setString:@""];
  QSO* q = [[QSO alloc] init];
  NSString* s = [q QSO];
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"lowercaseQSO"])
    s = [s uppercaseString];
  [inputField setString:s];
  [q release];
}

-(IBAction)makeProsign:(id)sender
{
  NSRange sel = [inputField selectedRange];
  if (sel.length)
  {
    NSTextStorage* sto = [inputField textStorage];
    NSMutableString* ms = [[NSMutableString alloc] initWithString:[[sto string] substringWithRange:sel]];
    NSString* ph = [NSString stringWithFormat:@"%C", 0x0305];
    unsigned i;
    BOOL ok = YES;
    for (i = 0; i < [ms length]; i++)
    {
      unichar ch = [ms characterAtIndex:i];
      if (ch == ' ' || ch == 0x0305)
      {
        ok = NO;
        break;
      }
      [ms insertString:ph atIndex:i+1];
      i++;
    }
    if (ok)
    {
      [sto replaceCharactersInRange:sel withString:ms];
      sel.length = [ms length];
      [inputField setSelectedRange:sel];
    }
    [ms release];
  }
}

-(IBAction)orderFrontPrefsWindow:(id)sender
{
  [prefsWindow makeKeyAndOrderFront:sender];
}

-(IBAction)exportAIFF:(id)sender
{
  #pragma unused (sender)
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setRequiredFileType:@"aiff"];
    [panel beginSheetForDirectory:nil file:nil modalForWindow:window
           modalDelegate:self
           didEndSelector:@selector(aiffExportDidEnd:returnCode:contextInfo:)
           contextInfo:nil];
}

#pragma mark Internal
-(void)gotoState:(unsigned)s
{
  [timer invalidate];
  timer = nil;
  double when;
  float wpm = [[NSUserDefaults standardUserDefaults] floatForKey:@"wpm"];
  id tabID = [[tabs selectedTabViewItem] identifier];
  switch (s)
  {
    case CWSNotTestingState:
    [renderer stop];
    if ([tabID isEqual:@"3"])
    {
      [startStopButton setImage:[NSImage imageNamed:@"PlayDisabled.tiff"]];
    }
    else
    {
      [startStopButton setImage:[NSImage imageNamed:@"PlayEnabled.tiff"]];
      [startStopButton setAlternateImage:[NSImage imageNamed:@"PlayPressed.tiff"]];
    }
    [topBLV setString:nil];
    [bottomBLV setString:nil];
    [bottomBLV setBGColor:[NSColor grayColor]];
    [bottomBLV setCanBecomeFirstResponder:NO];
    if (_tap) CGEventTapEnable(_tap, false);
    lastKey = 0.0;
    break;
    
    case CWSPlayingState:
    if ([tabID isEqual:@"1"]) [renderer start:[inputField string]];
    else if ([tabID isEqual:@"2"]) [self startNewTest];
    [startStopButton setImage:[NSImage imageNamed:@"StopEnabled.tiff"]];
    [startStopButton setAlternateImage:[NSImage imageNamed:@"StopPressed.tiff"]];
    [bottomBLV setCanBecomeFirstResponder:YES];
    [window makeFirstResponder:bottomBLV];
    break;
    
    case CWSShowingState:
    [self checkTestResponseWithFeedback:YES];
    [bottomBLV setCanBecomeFirstResponder:NO];
    case CWSWaitingState:
    // Pause 12.5 units for testing; 7 for training.
    // At 5 wpm 12.5 units is about 3 secs.
    when = ([Morse millisecondsPerUnitAtWPM:wpm]/1000.0) * 
          (([[NSUserDefaults standardUserDefaults] boolForKey:@"practice"])? 7.0:12.5);
    //NSLog(@"Waiting %f seconds from %f ms at %f", when, [Morse millisecondsPerUnitAtWPM:wpm], wpm);
    timer = [NSTimer scheduledTimerWithTimeInterval:when target:self selector:@selector(timer:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    break;
    
    case CWSSendingState:
    [startStopButton setImage:[NSImage imageNamed:@"StopEnabled.tiff"]];
    [startStopButton setAlternateImage:[NSImage imageNamed:@"StopPressed.tiff"]];
    [sentField setStringValue:@""];
    if (_tap) CGEventTapEnable(_tap, true);
    break;
  }
  state = s;
}

-(void)startNewTest
{
  [topBLV setString:nil];
  [bottomBLV setString:nil];
  [bottomBLV setBGColor:[NSColor grayColor]];
  unsigned min = [[NSUserDefaults standardUserDefaults] integerForKey:@"min"];
  unsigned max = [[NSUserDefaults standardUserDefaults] integerForKey:@"max"];
  unsigned n = min;
  if (min != max)
  {
    if (min > max)
    {
      min ^= max;
      max ^= min;
      min ^= max;
    }
    //NSLog(@"From %d to %d characters", min, max);
    n = min + (arc4random() % (max-min+1));
  }
  //NSLog(@"%d characters", n);
  unsigned src = [[NSUserDefaults standardUserDefaults] integerForKey:@"source"];
  unsigned set = [[NSUserDefaults standardUserDefaults] integerForKey:@"set"];
  NSString* s = nil;
  if (src == 1)
  {
    NSArray* whichArray;
    switch (set)
    {
      case 2: whichArray = [Morse numbers]; break;
      case 3: whichArray = [Morse lettersAndNumbers]; break;
      case 4: whichArray = [Morse punctuation]; break;
      case 5: whichArray = [Morse prosigns]; n = 1; break;
      default: whichArray = [Morse letters]; break;
    }
    s = [self randomStringFromArray:whichArray ofLength:n];
  }
  else if (src == 2)
  {
    s = [words randomStringOfLength:n];
  }
  else
  {
    if (![qso count])
    {
      QSO* q = [[QSO alloc] init];
      [qso setArray:[[[q QSO] uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
      //NSLog(@"%@", qso);
      [q release];
      qsoIndex = 0;
    }
    //NSLog(@"[qso count]=%d; qsoIndex=%d", [qso count], qsoIndex);
    if (qsoIndex < [qso count])
    {
      s = [qso objectAtIndex:qsoIndex];
      //NSLog(@"s: %@", s);
      qsoIndex++;
    }
    else [self gotoState:CWSNotTestingState];
  }
  if (s)
  {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"practice"]) [topBLV setString:s];
    [renderer start:s];
  }
}

-(BOOL)checkTestResponseWithFeedback:(BOOL)fb
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"practice"]) return YES;
  BOOL good = [[Morse formatString:[bottomBLV string]] isEqual:[renderer string]];
  if (fb)
  {
    NSString* key = (good)? @"correctColor":@"incorrectColor";
    NSData* data = [[NSUserDefaults standardUserDefaults] dataForKey:key];
    if (data)
    {
      NSColor* col = (NSColor*)[NSUnarchiver unarchiveObjectWithData:data];
      [bottomBLV setBGColor:col];
    }
    [topBLV setString:[renderer string]];
    [self updateScore];
  }
  return good;
}

#define kPlaceholder @"`"
#define kPlaceholderCh '`'
-(void)updateScore
{
  unsigned i;
  NSString* s1 = [renderer string];
  NSString* s2 = [Morse formatString:[bottomBLV string]];
  // Remove the overline from prosigns.
  // I'd prefer to treat them as full entities, but that will require mods
  // to levenshtein, so this is a stopgap.
  NSCharacterSet* cs = [NSCharacterSet characterSetWithCharactersInString:@"\xCC\x85"];
  s1 = [[s1 componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
  s2 = [[s2 componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
  NSLog(@"s1: '%@' s2: '%@'", s1, s2);
  Levenshtein* lev = [[Levenshtein alloc] initWithString:s1 andString:s2];
  NSArray* a = [lev alignmentWithPlaceholder:kPlaceholder];
  s1 = [a objectAtIndex:0];
  s2 = [a objectAtIndex:1];
  for (i = 0; i < [s1 length]; i++)
  {
    unichar c1 = [s1 characterAtIndex:i];
    unichar c2 = [s2 characterAtIndex:i];
    //NSLog(@"%C vs %C", c1, c2);
    if (c1 == kPlaceholderCh) continue;
    NSString* s3 = [[NSString alloc] initWithFormat:@"%C", c1];
    BOOL correct = (c1 == c2 && c2 != kPlaceholderCh);
    [self updateScoreForString:s3 correct:correct];
    [s3 release];
  }
  [lev release];
  //NSLog(@"Score is now %@", score);
}

-(void)updateScoreForString:(NSString*)s correct:(BOOL)correct
{
  NSMutableDictionary* d = [score objectForKey:s];
  if (!d)
  {
    d = [[NSMutableDictionary alloc] init];
    [score setObject:d forKey:s];
    [d release];
  }
  unsigned n = [[d objectForKey:@"n"] unsignedIntValue] + (correct)? 1:0;
  unsigned of = [[d objectForKey:@"of"] unsignedIntValue] + 1;
  [d setObject:[NSNumber numberWithUnsignedInt:n] forKey:@"n"];
  [d setObject:[NSNumber numberWithUnsignedInt:of] forKey:@"of"];
}

-(NSString*)randomStringFromArray:(NSArray*)array ofLength:(unsigned)length
{
  NSMutableString* ms = [[NSMutableString alloc] init];
  unsigned i;
  unsigned n = [array count];
  for (i = 0; i < length; i++)
  {
    NSString* str1 = [array objectAtIndex:arc4random() % n];
    NSString* str2 = [array objectAtIndex:arc4random() % n];
    float score1 = 0.0f;
    float score2 = 0.0f;
    NSDictionary* d = [score objectForKey:str1];
    if (d) score1 = 3.0f - (2.0f * [[d objectForKey:@"n"] floatValue] / [[d objectForKey:@"of"] floatValue]);
    d = [score objectForKey:str2];
    if (d) score2 = 3.0f - (2.0f * [[d objectForKey:@"n"] floatValue] / [[d objectForKey:@"of"] floatValue]);
    //if (score1 > score2) NSLog(@"Chose %@ (%f) over %@ (%f)", str1, score1, str2, score2);
    //else NSLog(@"Chose %@ (%f) over %@ (%f)", str2, score2, str1, score1);
    [ms appendString:(score1 > score2)? str1:str2];
  }
  NSString* ret = [NSString stringWithString:ms];
  [ms release];
  return ret;
}

-(void)keycheck:(CGEventRef)event
{
  CGEventTimestamp time = CGEventGetTimestamp(event);
  CGEventFlags mask = kCGEventFlagMaskAlphaShift | kCGEventFlagMaskShift |
                      kCGEventFlagMaskControl | kCGEventFlagMaskAlternate |
                      kCGEventFlagMaskCommand | kCGEventFlagMaskHelp |
                      kCGEventFlagMaskSecondaryFn;
  CGEventFlags flags = CGEventGetFlags(event) & mask;
  //NSLog(@"0x%X  0x%X", down, kCGEventFlagMaskShift & flags);
  if (kCGEventFlagMaskShift == (kCGEventFlagMaskShift & flags) || (down && !flags))
  {
    [self shiftKey:((kCGEventFlagMaskShift & flags) == kCGEventFlagMaskShift) atTime:time fromTimer:NO];
    //NSLog(@"0x%X  0x%X", down, kCGEventFlagMaskShift & flags);
  }
}

-(void)shiftKey:(BOOL)isdown atTime:(CGEventTimestamp)time fromTimer:(BOOL)flag
{
  if (flag && !spaceTimerGo) return;
  if (timer) [timer invalidate];
  timer = nil;
  spaceTimerGo = NO;
  //if (flag) NSLog(@"SPACE TIMER");
  MorseRecognizerQuality q = {0.0,0.0};
  down = isdown;
  double wpm = [recognizer WPM];
  MorseSpacing spacing = [Morse spacingForWPM:wpm CWPM:wpm];
  double delay = spacing.interwordMilliseconds;
  //NSLog(@"%s at %llu (0x%X)", (down)? "down":"up", time, flags);
  if (lastKey)
  {
    double dur = ((double)time-(double)lastKey)/1000000.0;
    if (flag) dur = delay;
    uint16_t morse;
    double* dp = &dur;
    do
    {
      morse = [recognizer feed:dp];
      NSString* str = [Morse stringFromMorse:morse];
      //NSLog(@"You typed %@ (%d)", str, morse);
      if (!str && morse != MorseNoCharacter) str = [NSString stringWithFormat:@"%C", 0x203D]; // interrobang
      else if ([str length] > 1) str = [Morse formatString:str];
      if (str) [sentField setStringValue:[NSString stringWithFormat:@"%@%@", [sentField stringValue], str]];
      dp = NULL;
    } while (morse != MorseNoCharacter);
    q = [recognizer quality];
    //NSLog(@"QUALITY %f", q.quality);
  }
  if (down) [renderer setMode:MorseRendererOnMode];
  else
  {
    [renderer setMode:MorseRendererOffMode];
    [tWPMField setDoubleValue:q.toneWPM];
    [sWPMField setDoubleValue:q.spaceWPM];
    [qualityIndicator setDoubleValue:q.quality*100.0];
    if (!flag)
    {
      spaceTimerGo = YES;
      delay /= 1000.0;
      //NSLog(@"delay %f s from %f (%f WPM)", delay, [Morse millisecondsPerUnitAtWPM:[recognizer WPM]], [recognizer WPM]);
      timer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(spaceTimer:) userInfo:nil repeats:NO];
    }
  }
  lastKey = time;
}

#pragma mark Delegate
-(void)applicationWillTerminate:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setObject:[[tabs selectedTabViewItem] identifier] forKey:@"tab"];
  [[NSUserDefaults standardUserDefaults] setObject:score forKey:@"score"];
  if (_tap)
  {
    CGEventTapEnable(_tap, false);
    CFMachPortInvalidate(_tap);
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _src, kCFRunLoopCommonModes);
    CFRelease(_tap);
  }
  if (_src) CFRelease(_src);
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app
{
  return YES;
}

-(void)tabView:(NSTabView*)tv didSelectTabViewItem:(NSTabViewItem*)item
{
  [self gotoState:CWSNotTestingState];
  BOOL loop = ([[[tabs selectedTabViewItem] identifier] isEqual:@"1"])? [[[NSUserDefaults standardUserDefaults] valueForKey:@"loop"] boolValue]:NO;
  [renderer setLoop:loop];
}

-(void)authorizationViewDidAuthorize:(SFAuthorizationView*)view
{
  AuthorizationRef auth = [[view authorization] authorizationRef];
  NSString* me = [[NSBundle mainBundle] executablePath];
  NSString* mktrusted = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"mktrusted"];
  char* args[2] = {NULL,NULL};
  args[0] = (char*)[me UTF8String];
  OSStatus authErr = AuthorizationExecuteWithPrivileges(auth, [mktrusted UTF8String], kAuthorizationFlagDefaults, &args[0], NULL);
  NSString* ti = [[Onizuka sharedOnizuka] copyLocalizedTitle:(0 == authErr)? @"__AUTH_SUCCESS__":@"__AUTH_FAILURE__"];
  if (0 != authErr)
  {
    NSString* tmp = ti;
    ti = [[NSString alloc] initWithFormat:ti, authErr];
    [tmp release];
  }
  [authField setStringValue:ti];
  [ti release];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  id tabID = [[tabs selectedTabViewItem] identifier];
  SEL action = [item action];
  /*if ([item action] == @selector(startStop:))
  {
    NSString* ti = [[Onizuka sharedOnizuka] copyLocalizedTitle:(state == CWSNotTestingState)? @"__PLAY__":@"__PAUSE__"];
    [playPauseMenuItem setTitle:ti];
    [ti release];
    if ([tabID isEqual:@"3"]) return NO;
  }
  else*/ if (action == @selector(genQSO:))
  {
    if (![tabID isEqual:@"1"]) return NO;
  }
  else if (action == @selector(makeProsign:))
  {
    if (![tabID isEqual:@"1"]) return NO;
  }
  return YES;
}

#pragma mark Callbacks
-(void)timer:(NSTimer*)t
{
  if (state == CWSWaitingState) [self gotoState:CWSShowingState];
  else if (state == CWSShowingState) [self gotoState:CWSPlayingState];
}

-(void)spaceTimer:(NSTimer*)t
{
  if (spaceTimerGo && t == timer)
  {
    //NSLog(@"timer fired: %@", t);
    [self shiftKey:NO atTime:UpTimeInNanoseconds() fromTimer:YES];
    lastKey = 0.0;
  }
  spaceTimerGo = NO;
  [timer invalidate];
  timer = nil;
}

-(void)gotText:(NSNotification*)note
{
  if (state == CWSWaitingState && [self checkTestResponseWithFeedback:NO])
  {
    [self gotoState:CWSShowingState];
  }
}

-(void)renderDone:(NSNotification*)note
{
  //NSLog(@"renderDone:");
  if ([[[tabs selectedTabViewItem] identifier] isEqual:@"1"]) [self gotoState:CWSNotTestingState];
  else
  {
    if ([self checkTestResponseWithFeedback:NO]) [self gotoState:CWSShowingState];
    else [self gotoState:CWSWaitingState];
  }
}

-(void)wordStarted:(NSNotification*)note
{
  NSString* s = [note object];
  NSRange range = NSRangeFromString(s);
  [inputField setSelectedRange:range];
  [inputField scrollRangeToVisible: range];
  //NSLog(@"wordStarted: %@", s);
}

-(void)tintChanged:(NSNotification*)note
{
  NSString* tintImageName = @"repeat_embedded_blue.png";
  if ([NSColor currentControlTint] == NSGraphiteControlTint)
    tintImageName=@"repeat_embedded_graphite.png";
  [repeatButton setAlternateImage:[NSImage imageNamed:tintImageName]];
}

-(void)observeValueForKeyPath:(NSString*)path ofObject:(id)object change:(NSDictionary*)change context:(void*)ctx
{
  #pragma unused (object,ctx)
  //NSLog(@"observeValueForKeyPath:%@ ofObject:%@ change:%@", path, object, change);
  id newval = [change objectForKey:NSKeyValueChangeNewKey];
  if ([path isEqual:@"freq"])
  {
    [renderer setFreq:[newval floatValue]];
  }
  else if ([path isEqual:@"amp"])
  {
    [renderer setAmp:[newval floatValue]];
  }
  else if ([path isEqual:@"wpm"])
  {
    float newvalf = [newval floatValue];
    //NSLog(@"wpm %f", newvalf);
    [renderer setWPM:newvalf];
    [recognizer setWPM:newvalf];
    float cwpm = [[[NSUserDefaults standardUserDefaults] objectForKey:@"cwpm"] floatValue];
    if (cwpm < newvalf) [[NSUserDefaults standardUserDefaults] setFloat:newvalf forKey:@"cwpm"];
  }
  else if ([path isEqual:@"cwpm"])
  {
    float newvalf = [newval floatValue];
    //NSLog(@"cwpm %f", newvalf);
    [renderer setCWPM:newvalf];
    //[recognizer setCWPM:newvalf];
    float wpm = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wpm"] floatValue];
    if (wpm > newvalf) [[NSUserDefaults standardUserDefaults] setFloat:newvalf forKey:@"wpm"];
  }
  else if ([path isEqual:@"loop"])
  {
    [renderer setLoop:[newval boolValue]];
  }
  else if ([path isEqual:@"flash"])
  {
    [renderer setFlash:[newval boolValue]];
  }
  else if ([path isEqual:@"pan"])
  {
    [renderer setPan:[newval floatValue]];
  }
  else if ([path isEqual:@"qrn"])
  {
    [renderer setQRN:[newval floatValue]];
  }
  else if ([path isEqual:@"qrnWhite"])
  {
    [renderer setQRNWhite:[newval boolValue]];
  }
  unsigned src = [[NSUserDefaults standardUserDefaults] integerForKey:@"source"];
  unsigned set = [[NSUserDefaults standardUserDefaults] integerForKey:@"set"];
  [minButton setEnabled:(src<3&&set<5)];
  [maxButton setEnabled:(src<3&&set<5)];
  [setButton setEnabled:(src==1)];
}

-(void)aiffExportDidEnd:(NSSavePanel*)sheet returnCode:(int)code contextInfo:(void*)contextInfo
{
  #pragma unused (contextInfo)
  if (code == NSOKButton)
  {
    [sheet orderOut:nil];
    MorseRenderer* mr = [renderer copy];
    [mr setMode:MorseRendererAgendaMode];
    [mr setString:[inputField string]];
    [mr exportAIFF:[sheet filename]];
    [mr release];
  }
}

#pragma mark Score Table
-(unsigned)numberOfRowsInTableView:(NSTableView*)tv
{
  return [score count];
}

-(id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(unsigned)row
{
  NSArray* keys = [[score allKeys] sortedArrayUsingSelector:@selector(compare:)];
  id key = [keys objectAtIndex:row];
  if ([[col identifier] isEqual:@"Correct"])
  {
    NSDictionary* d = [score objectForKey:key];
    unsigned n = [[d objectForKey:@"n"] unsignedIntValue];
    unsigned of = [[d objectForKey:@"of"] unsignedIntValue];
    float pct = 100.0f*(float)n/(float)of;
    key = [NSString stringWithFormat:@"%d/%d (%.2f%%)", n, of, pct];
    if (pct >= 95.0f)
    {
      NSColor* green = [NSColor colorWithCalibratedRed:0.0f green:0.67f blue:0.0f alpha:1.0f];
      NSDictionary* attrs = [[NSDictionary alloc] initWithObjectsAndKeys:green, NSForegroundColorAttributeName, NULL];
      key = [[NSAttributedString alloc] initWithString:key attributes:attrs];
      [key autorelease];
      [attrs release];
    }
  }
  return key;
}
@end

#pragma mark -
#pragma mark Static Routines
static CGEventRef TapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon)
{
  #pragma unused (proxy,type)
  MorseController* myself = refcon;
  [myself keycheck:event];
  return event;
}


#include <mach/mach.h>
#include <mach/mach_time.h>
// Boosted from Apple sample code
static CGEventTimestamp UpTimeInNanoseconds(void)
{
  CGEventTimestamp time;
  CGEventTimestamp timeNano;
  static mach_timebase_info_data_t sTimebaseInfo;

  time = mach_absolute_time();
  // Convert to nanoseconds.
  // If this is the first time we've run, get the timebase.
  // We can use denom == 0 to indicate that sTimebaseInfo is
  // uninitialised because it makes no sense to have a zero
  // denominator is a fraction.
  if ( sTimebaseInfo.denom == 0 )
  {
      (void) mach_timebase_info(&sTimebaseInfo);
  }
  // Do the maths.  We hope that the multiplication doesn't
  // overflow; the price you pay for working in fixed point.
  timeNano = time * sTimebaseInfo.numer / sTimebaseInfo.denom;
  return timeNano;
}

