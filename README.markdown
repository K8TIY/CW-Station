## This is CW Station version 1.3

### What can you do with this thing?

* In the first pane, "Generate", type or paste text to play as Morse code.
  CW Station will highlight each word when it begins to play it.
  * "Generate QSO" (menu) to randomly generate one side of a possibly funny QSO.
  * Turn a group of characters into a prosign (like S̅K̅) by selecting them and
    pressing the "Make Prosign" button or menu item.
  * Instead of playing the Morse code, you can save it as audio using
    "File -> Export AIFF Audio".
    * Use GarageBand to turn this file into a custom ringtone.
      Amaze your friends; terrify your enemies!
  * For Farnsworth spacing, set (for example) CWPM to 20 and WPM to 5.
  * Simulate noisy conditions by turning on QRN as white/pink noise.
* In the "Test" pane, you can have CW Station quiz you on random symbols,
  words from a simulated QSO, or dictionary words.
  * Check "Practice Mode" for practice; it will show the words as it sends CW.
  * If not in "Practice Mode" it will keep track of your score and show it in
    the next tab.
  * To enter a prosign here, hold down the shift key.
* You can "Send" CW using your shift key as a Morse keyer.
  CW Station will try to recognize what you're sending.
  * Note: this does not work spectacularly well, but it much improved in version
    1.3.1.
  * It will use your deviation from the calculated tone/space timings to try to
    rate your fist "Quality".
  * Hint: click the "Play" button or hit the spacebar to go into keyer mode.
  * Hint: it uses your WPM setting to distinguish dots from dashes,
          but ignores CWPM.
  * _Note: in order for this to work, CW Station will prompt you to enter
          your password to authorize CW Station as a "trusted" application.
          The other option is to check "Enable access for assistive devices" in
          System Preferences -> Universal Access, but this is NOT recommended!
          (See below for why....)_

## _SECURITY WARNING_

Checking "Enable access for assistive devices" is not recommended. This enables
any program to install a callback to intercept keyboard events at a very
low level. This could allow a malicious program to record everything you type,
including all your online passwords!

CW Station only looks at the state of the shift key, and only when it is the
frontmost app. If you don't trust me (why should you?) don't leave it
running when you are doing anything else. Or better yet, check the source code
and verify my claims.

### The _Cryptonomicon_ Feature

You can have the software flash the caps lock LED in addition to playing the
audio.

### To Build

Requires my Onizuka localizer from https://github.com/K8TIY/Onizuka.
It's set up as a git submodule, so just do the usual git submodule
magic to get it set up. (Don't ask me about it -- I'm new to git and submodules
make my head hurt.)

### Todo

* Do I need to give users more time for their panicky typing in Test mode?
* Make the QSO library more up to date and/or more realistic
  (in progress; comments welcome).
* Simulate contest QSOs?
* Add a "Don't Warn Me Again" to the auth dialog box for users that can't
  or do not wish to authorize the program.
* International characters and a way to enter them in the Test pane.

### Not Todo

* Rig control/interface. CW Station is not an operating aid.
* Other digital methods. (For me, when the radio goes on the computer goes off.)
* Stuff other Mac developers have done right (in open source, that is).

### If You Contribute...

If you contribute to the project, I'll be sure to add your callsign to the QSO
library! If you're a native speaker of Japanese, please check my translations.
They're about Google-quality; some are Google-derived!
