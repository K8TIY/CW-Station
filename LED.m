/*
Based on code by Apple, heavily modified by Brian "Moses" Hall (me).
I hereby place this code in the public domain.
*/

//#include <mach/mach_error.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include "LED.h"

static NSMutableDictionary* _CreateMatchingDict(Boolean isDeviceNotElement,
                                    uint32_t inUsagePage,
                                    uint32_t inUsage);

static NSMutableDictionary* _CreateMatchingDict(Boolean isDeviceNotElement,
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
  return [self initWithUsage:kHIDUsage_LED_CapsLock];
}

-(id)initWithUsage:(uint32_t)usage
{
  self = [super init];
  CFSetRef deviceCFSetRef = NULL;
  IOHIDDeviceRef* refs = NULL;
  // create a IO HID Manager reference
  IOHIDManagerRef mgr = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
  if (!mgr) goto Oops;
  // Create a device matching dictionary
  NSDictionary* dic = _CreateMatchingDict(true, kHIDPage_GenericDesktop,
                                          kHIDUsage_GD_Keyboard);
  if (!dic) goto Oops;
  // set the HID device matching dictionary
  IOHIDManagerSetDeviceMatching(mgr, (CFDictionaryRef)dic);
  [dic release];
  dic = nil;
  // Now open the IO HID Manager reference
  IOReturn err = IOHIDManagerOpen(mgr, kIOHIDOptionsTypeNone);
  if (err != noErr) goto Oops;
  // and copy out its devices
  deviceCFSetRef = IOHIDManagerCopyDevices(mgr);
  if (!deviceCFSetRef) goto Oops;
  // how many devices in the set?
  CFIndex deviceIndex, deviceCount = CFSetGetCount(deviceCFSetRef);
  // allocate a block of memory to extact the device refs from the set into
  refs = malloc(sizeof(IOHIDDeviceRef) * deviceCount);
  if (!refs) goto Oops;
  // now extract the device refs from the set
  CFSetGetValues(deviceCFSetRef, (const void**)refs);
  // before we get into the device loop set up element matching dictionary
  dic = _CreateMatchingDict(false, kHIDPage_LEDs, 0);
  if (!dic) goto Oops;
  for (deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++)
  {
    // if this isn't a keyboard device...
    if (!IOHIDDeviceConformsTo(refs[deviceIndex], kHIDPage_GenericDesktop,
                               kHIDUsage_GD_Keyboard))
    {
      //printf("skipping nonconforming device at %d\n", deviceIndex);
      continue;  // ...skip it
    }
    // copy all the elements
    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(refs[deviceIndex],
                                     (CFDictionaryRef)dic,
                                     kIOHIDOptionsTypeNone);
    //require(elements, next_device);
    if (elements)
    {
      // iterate over all the elements
      CFIndex i, n = CFArrayGetCount(elements);
      for (i = 0; i < n; i++)
      {
        IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
        if (element)
        {
          uint32_t usagePage = IOHIDElementGetUsagePage(element);
          // if this isn't an LED element, skip it
          if (kHIDPage_LEDs != usagePage) continue;
          uint32_t elusage = IOHIDElementGetUsage(element);
          if (elusage == usage)
          {
            ledDevice = (IOHIDDeviceRef)CFRetain(refs[deviceIndex]);
            ledElement = (IOHIDElementRef)CFRetain(element);
            break;
          }
        }
        continue;
      }
    }
  //next_device: ;
    if (elements) CFRelease(elements);
    continue;
  }
  [dic release];
Oops:
  if (mgr) CFRelease(mgr);
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
      // create the IO HID Value to be sent to this LED element
      uint64_t timestamp = 0;
      IOHIDValueRef val = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault,
                                                          ledElement, timestamp,
                                                          value);
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


