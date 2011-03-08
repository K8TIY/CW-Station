#import <Cocoa/Cocoa.h>

int main(int argc, char* argv[])
{
  srandom(time(NULL));
  return NSApplicationMain(argc, (const char**)argv);
}

