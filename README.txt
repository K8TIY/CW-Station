This is CW Station version 1.0.

What can you do with this thing?

- In the first pane, "Generate", type in text to play as Morse code.
--- You can "Generate QSO" to randomly generate one side of a possibly funny QSO.
--- Turn a group of characters into a prosign (like S̅K̅) by selecting them and pressing the "Make Prosign" button.
--- Instead of playing the Morse code, you can save it as audio using "File -> Export AIFF Audio".
----- Use GarageBand to turn this file into a custom ringtone. Amaze your friends; terrify your enemies!
--- For Farnsworth spacing, set (for example) CWPM to 20 and WPM to 5.
- In the "Test" pane, you can have CW Station quiz you on random symbols, or dictionary words.
--- Check the "Practice Mode" box for practice; it will show the words as it sends CW.
--- If not in "Practice Mode" it will keep track of your score and show it in the next tab.
--- To enter a prosign here, hold down the shift key.
- You can "Send" CW using your shift key as a Morse keyer. CW Station will try to recognize what you're sending.
--- It will use your deviation from the calculated tone/space timings to try to rate your fist "Quality".
--- Hint: you have to click the "Play" button before it will go into "keyer" mode.
--- Hint: it your WPM setting to distinguish dots from dashes, but ignores CWPM.
--- Note: this does not work all that well, and is probably inferior to more specialized practice setups.
--- Note: in order for this to work, CW Station will prompt you to enter
          your password to authorize CW Station as a "trusted" application.
          The other option is to check "Enable access for assistive devices" in
          System Preferences -> Universal Access, but this is NOT recommended!
          (See below for why....)

*** !!! SECURITY WARNING !!! ***

Checking "Enable access for assistive devices" is not recommended. This enables
any program to install a callback to intercept keyboard events at a very
low level. This could allow a malicious program to record everything you type,
including all your online passwords!

CW Station only looks at the state of the shift key, and only when it is the
frontmost app. If you don't trust me (why should you?) don't leave it
running when you are doing anything else. Or better yet, check the source code
and verify my claims.

*** THE "CRYPTONOMICON" FEATURE ***

You can have the software flash the caps lock LED in addition to playing the
audio.

*** TO COMPILE THE CODE ***

Requires my Onizuka localizer from https://github.com/K8TIY/Onizuka.
Needs to be in the same directory as the CW Station directory, or you can tell
XCode where to find the Onizuka files if they are elsewhere.

*** TODO ***

Koch method?
QRM/QRN synthesis?
Make the QSO library more up to date and/or more realistic?
Simulate contest QSOs?
Option to flash num lock LED (if it exists) instead of caps lock.
Weight random character selection by score.

*** NOT TODO ***

Rig control/interface. CW Station is not an operating aid.
Other digital methods. (For me, when the radio goes on the computer goes off.)
Stuff other Mac developers have done right.
