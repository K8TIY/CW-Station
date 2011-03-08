#import <Cocoa/Cocoa.h>
#import "MorseRenderer.h"
#import "BigLetterView.h"
#import <SecurityInterface/SFAuthorizationView.h>
#import "Wordlist.h";

@interface MorseWindow : NSWindow
@end

enum
{
  iMorseNotTestingState,
  iMorsePlayingState,
  iMorseWaitingState,
  iMorseShowingState,
  iMorseSendingState
};

@interface MorseController : NSObject
{
  IBOutlet MorseWindow* window;
  IBOutlet NSTabView* tabs;
	IBOutlet NSTextView* inputField;
  IBOutlet NSButton* repeatButton;
  IBOutlet NSButton* startStopButton;
  IBOutlet NSSlider* panSlider;
  IBOutlet BigLetterView* topBLV;
  IBOutlet BigLetterView* bottomBLV;
  IBOutlet NSTableView* scoreTable;
  IBOutlet NSTextField* sentField;
  IBOutlet NSLevelIndicator* qualityIndicator;
  IBOutlet NSTextField* tWPMField;
  IBOutlet NSTextField* sWPMField;
  IBOutlet NSWindow* authWindow;
  IBOutlet SFAuthorizationView* authView;
  IBOutlet NSTextField* authField;
	IBOutlet MorseRenderer* renderer;
  IBOutlet NSMenuItem* playPauseMenuItem;
  Wordlist* words;
  MorseRecognizer* recognizer;
  NSTimer* timer;
  unsigned state;
  NSMutableDictionary* score;
  CFRunLoopSourceRef _src;
  CFMachPortRef _tap;
  CGEventTimestamp lastKey;
  BOOL down;
  BOOL spaceTimerGo;
}
//-(IBAction)space:(id)sender;
-(IBAction)startStop:(id)sender;
-(IBAction)clearScore:(id)sender;
-(IBAction)repan:(id)sender;
-(IBAction)genQSO:(id)sender;
-(IBAction)makeProsign:(id)sender;
@end
