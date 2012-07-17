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
#import <SecurityInterface/SFAuthorizationView.h>
#import "MorseRenderer.h"
#import "MorseScore.h"
#import "BigLetterView.h"
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
  MorseScore* score;
  CFRunLoopSourceRef _src;
  CFMachPortRef _tap;
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
