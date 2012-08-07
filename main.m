#import <Cocoa/Cocoa.h>
#import "Morse.h"

#define __MRT_TEST__ 0

int main(int argc, char* argv[])
{
  srandom(time(NULL));
#if __MRT_TEST__
  NSAutoreleasePool* arp = [[NSAutoreleasePool alloc] init];
  double times[] = {0.0,//down S
                    120.0,//up
                    240.0,//down
                    360.0,//up
                    480.0,//down
                    600.0,//up
                    960.0,//down O
                    1320.0,//up
                    1440.0,//down
                    1800.0,//up
                    1920.0,//down
                    2280.0,//up
                    2640.0//end
                    };
  srandom(time(NULL));
  double ms = [Morse millisecondsPerUnitAtWPM:10.0];
  NSLog(@"unit %f ms", ms);
  MorseRecognizer* mr = [[MorseRecognizer alloc] initWithWPM:10.0L];
  unsigned i;
  for (i = 0; i < 13; i++)
  {
    double time = times[i];
    double* timep = &time;
    uint16_t res = 0;
    do
    {
      res = [mr feed:timep];
      if (res) NSLog(@"fed %f, result (0x%04X) %@", times[i], res, [Morse stringFromMorse:res]);
      timep = NULL;
    } while (res != 0);
  }
  MorseRecognizerQuality q = [mr quality];
  NSLog(@"wpm is %f, Q is %f", [mr WPM], q.quality);
  [arp release];
#endif
  return NSApplicationMain(argc, (const char**)argv);
}
