#import <Cocoa/Cocoa.h>
#import "MorseRenderer.h"
#import "BigLetterView.h"
#import <SecurityInterface/SFAuthorizationView.h>
#import "Wordlist.h";

@interface MorseWindow : NSWindow
@end

@interface MorseController : NSObject
{
  IBOutlet NSWindow* window;
  IBOutlet NSWindow* prefsWindow;
  IBOutlet NSTabView* tabs;
  IBOutlet NSTextView* inputField;
  IBOutlet NSButton* repeatButton;
  IBOutlet NSButton* startStopButton;
  IBOutlet NSSlider* panSlider;
  // Test pane
  IBOutlet BigLetterView* topBLV;
  IBOutlet BigLetterView* bottomBLV;
  IBOutlet NSPopUpButton* minButton;
  IBOutlet NSPopUpButton* maxButton;
  IBOutlet NSPopUpButton* sourceButton;
  IBOutlet NSPopUpButton* setButton;
  // Score pane
  IBOutlet NSTableView* scoreTable;
  // Send pane
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
  NSMutableArray* qso;
  unsigned qsoIndex;
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
-(IBAction)startStop:(id)sender;
-(IBAction)clearScore:(id)sender;
-(IBAction)repan:(id)sender;
-(IBAction)genQSO:(id)sender;
-(IBAction)makeProsign:(id)sender;
-(IBAction)orderFrontPrefsWindow:(id)sender;
-(IBAction)exportAIFF:(id)sender;
-(void)windowDidReceiveSpace:(id)sender;
@end
