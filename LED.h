#import <Cocoa/Cocoa.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>

@interface LED : NSObject
{
  IOHIDDeviceRef  ledDevice;
  IOHIDElementRef ledElement;
}
// Pass either kHIDUsage_LED_NumLock or kHIDUsage_LED_CapsLock
-(id)initWithUsage:(uint32_t)usage;
-(void)setValue:(SInt32)value;
@end
