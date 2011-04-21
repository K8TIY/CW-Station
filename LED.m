/*
Based on code by Apple, heavily modified by Brian "Moses" Hall (me).
I hereby place this code in the public domain.
*/

#include <mach/mach_error.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include "LED.h";

static NSMutableDictionary* _CreateMatchingDictionary(Boolean isDeviceNotElement,
                                    uint32_t inUsagePage,
                                    uint32_t inUsage);

static NSMutableDictionary* _CreateMatchingDictionary(Boolean isDeviceNotElement,
                                    uint32_t inUsagePage,
                                    uint32_t inUsage)
{
  NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInt:inUsagePage],
                               (isDeviceNotElement)?
                                 CFSTR(kIOHIDDeviceUsagePageKey):
                                 CFSTR(kIOHIDElementUsagePageKey),
                               NULL];
  if (inUsage) [dic setObject:[NSNumber numberWithUnsignedInt:inUsage]
                                forKey:(isDeviceNotElement)?
                                  (NSString*)CFSTR(kIOHIDDeviceUsageKey):
                                  (NSString*)CFSTR(kIOHIDElementUsageKey)];
  return dic;
}

@implementation LED
-(id)init
{
  self = [super init];
  CFSetRef deviceCFSetRef = NULL;
  IOHIDDeviceRef* refs = NULL;
  // create a IO HID Manager reference
  IOHIDManagerRef mgr = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
  require(mgr, Oops);
  // Create a device matching dictionary
  NSDictionary* dic = _CreateMatchingDictionary(true, kHIDPage_GenericDesktop,
                                                kHIDUsage_GD_Keyboard);
  require(dic, Oops);
  // set the HID device matching dictionary
  IOHIDManagerSetDeviceMatching(mgr, (CFDictionaryRef)dic);
  [dic release];
  // Now open the IO HID Manager reference
  IOReturn err = IOHIDManagerOpen(mgr, kIOHIDOptionsTypeNone);
  require_noerr(err, Oops);
  // and copy out its devices
  deviceCFSetRef = IOHIDManagerCopyDevices(mgr);
  require(deviceCFSetRef, Oops);
  // how many devices in the set?
  CFIndex deviceIndex, deviceCount = CFSetGetCount(deviceCFSetRef);
  // allocate a block of memory to extact the device refs from the set into
  refs = malloc(sizeof(IOHIDDeviceRef) * deviceCount);
  require(refs, Oops);
  // now extract the device refs from the set
  CFSetGetValues(deviceCFSetRef, (const void**)refs);
  // before we get into the device loop we'll setup our element matching dictionary
  dic = _CreateMatchingDictionary(false, kHIDPage_LEDs, 0);
  require(dic, Oops);
  for (deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++)
  {
    // if this isn't a keyboard device...
    if (!IOHIDDeviceConformsTo(refs[deviceIndex], kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard))
    {
      //printf("skipping nonconforming device at %d\n", deviceIndex);
      continue;  // ...skip it
    }
    // copy all the elements
    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(refs[deviceIndex],
                                     (CFDictionaryRef)dic,
                                     kIOHIDOptionsTypeNone);
    require(elements, next_device);
    // iterate over all the elements
    CFIndex i, n = CFArrayGetCount(elements);
    for (i = 0; i < n; i++)
    {
      IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
      require(element, next_element);
      uint32_t usagePage = IOHIDElementGetUsagePage(element);
      // if this isn't an LED element, skip it
      if (kHIDPage_LEDs != usagePage) continue;
      uint32_t usage = IOHIDElementGetUsage(element);
      if (usage == kHIDUsage_LED_CapsLock)
      {
        ledDevice = (IOHIDDeviceRef)CFRetain(refs[deviceIndex]);
        ledElement = (IOHIDElementRef)CFRetain(element);
        break;
      }
    next_element:  ;
      continue;
    }
  next_device: ;
    if (elements) CFRelease(elements);
    continue;
  }
  if (mgr) CFRelease(mgr);
  [dic release];
Oops:  ;
  if (deviceCFSetRef) CFRelease(deviceCFSetRef);
  if (refs) free(refs);
  return self;
}

-(void)dealloc
{
  if (ledDevice) CFRelease(ledDevice);
  if (ledElement) CFRelease(ledElement);
  [super dealloc];
}

-(void)setValue:(SInt32)value
{
  if (ledDevice && ledElement)
  {
    IOReturn err = IOHIDDeviceOpen(ledDevice, 0);
    if (!err)
    {
      uint64_t timestamp = 0; // create the IO HID Value to be sent to this LED element
      IOHIDValueRef val = IOHIDValueCreateWithIntegerValue( kCFAllocatorDefault, ledElement, timestamp, value );
      if (val)
      {
        // now set it on the device
        err = IOHIDDeviceSetValue(ledDevice, ledElement, val);
        CFRelease(val);
      }
      IOHIDDeviceClose(ledDevice, 0);
    }
    if (err) printf("error 0x%X\n", err);
  }
}
@end


