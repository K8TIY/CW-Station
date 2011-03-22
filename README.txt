This is iMorse version 0.1.

What can you do with this thing?

- In the first pane, "Generate", type in text to play as Morse code.
--- You can "Generate QSO" to randomly generate a possibly funny QSO. (With Preferences you can control upper/lower case.)
--- Turn a group of characters into a prosign (like S̅K̅) by selecting them and pressing the "Make Prosign" button.
--- Instead of playing the Morse code, you can save it as audio using "File -> Export AIFF Audio".
----- Use GarageBand to turn this file into a custom ringtone. Amaze your friends; terrify your enemies!
--- For Farnsworth spacing, set (for example) CWPM to 20 and WPM to 5.
- In the "Test" pane, you can have iMorse quiz you on random symbols, or dictionary words.
--- Check the "Practice Mode" box for practice; it will show the words as it sends CW.
--- If not in "Practice Mode" it will keep track of your score and show it in the next tab.
- You can "Send" CW using your shift key as a Morse keyer. iMorse will try to recognize what you're sending.
--- It will use your deviation from the calculated tone/space timings to try to rate your fist "Quality".
--- Hint: you have to click the "Play" button before it will go into "keyer" mode.
--- Hint: iMorse uses your WPM setting to distinguish dots from dashes, but ignores CWPM.
--- Note: this does not work all that well, and is probably inferior to more specialized practice setups.
--- Note: in order for this to work, you have to either check "Enable access for assistive devices" in
          System Preferences -> Universal Access; if this is unchecked iMorse will prompt you to enter
          your password to authorize iMorse as a "trusted" application.


!!! SECURITY WARNING !!!

Checking "Enable access for assistive devices" is not recommended. This enables any program to install
a callback to intercept keyboard events at a very low level. This could allow a malicious program to
record everything you type, including all your online passwords!

iMorse only looks at the state of the shift key, and only when iMorse is the frontmost app. If you don't
trust me (why should you?) don't leave iMorse running when you are doing anything else. Or better yet,
download the source code from GitHub, verify I'm telling the truth, and compile it yourself.