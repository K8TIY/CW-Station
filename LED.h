#import <Cocoa/Cocoa.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>

@interface LED : NSObject
{
  IOHIDDeviceRef  ledDevice;
  IOHIDElementRef ledElement;
}

-(void)setValue:(SInt32)value;
@end
