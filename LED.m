/*
 * keyboard_leds.c
 * Manipulate keyboard LEDs (capslock and numlock) programmatically.
 *
 * Copyright (c) 2007,2008 Amit Singh. All Rights Reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *     
 *  THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 *  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 *  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 *  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 *  SUCH DAMAGE.
 */
#include <mach/mach_error.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include "LED.h";

@implementation LED
static CFMutableDictionaryRef hu_CreateMatchingDictionaryUsagePageUsage( Boolean isDeviceNotElement,
																		UInt32 inUsagePage,
																		UInt32 inUsage )
{
	// create a dictionary to add usage page / usages to
	CFMutableDictionaryRef result = CFDictionaryCreateMutable( kCFAllocatorDefault,
															  0,
															  &kCFTypeDictionaryKeyCallBacks,
															  &kCFTypeDictionaryValueCallBacks );
	
	if ( result ) {
		if ( inUsagePage ) {
			// Add key for device type to refine the matching dictionary.
			CFNumberRef pageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsagePage );
			
			if ( pageCFNumberRef ) {
				if ( isDeviceNotElement ) {
					CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsagePageKey ), pageCFNumberRef );
				} else {
					CFDictionarySetValue( result, CFSTR( kIOHIDElementUsagePageKey ), pageCFNumberRef );
				}
				CFRelease( pageCFNumberRef );
				
				// note: the usage is only valid if the usage page is also defined
				if ( inUsage ) {
					CFNumberRef usageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsage );
					
					if ( usageCFNumberRef ) {
						if ( isDeviceNotElement ) {
							CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsageKey ), usageCFNumberRef );
						} else {
							CFDictionarySetValue( result, CFSTR( kIOHIDElementUsageKey ), usageCFNumberRef );
						}
						CFRelease( usageCFNumberRef );
					} else {
						fprintf( stderr, "%s: CFNumberCreate( usage ) failed.", __PRETTY_FUNCTION__ );
					}
				}
			} else {
				fprintf( stderr, "%s: CFNumberCreate( usage page ) failed.", __PRETTY_FUNCTION__ );
			}
		}
	} else {
		fprintf( stderr, "%s: CFDictionaryCreateMutable failed.", __PRETTY_FUNCTION__ );
	}
	return result;
}

-(id)init
{
  self = [super init];
  // create a IO HID Manager reference
	IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
	require( tIOHIDManagerRef, Oops );
	// Create a device matching dictionary
	CFDictionaryRef matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( TRUE,
																				  kHIDPage_GenericDesktop,
																				  kHIDUsage_GD_Keyboard );
	printf("1\n");
  require( matchingCFDictRef, Oops );
	// set the HID device matching dictionary
	IOHIDManagerSetDeviceMatching( tIOHIDManagerRef, matchingCFDictRef );
	CFRelease( matchingCFDictRef );
	// Now open the IO HID Manager reference
	IOReturn tIOReturn = IOHIDManagerOpen( tIOHIDManagerRef, kIOHIDOptionsTypeNone );
	require_noerr( tIOReturn, Oops );
	// and copy out its devices
	CFSetRef deviceCFSetRef = IOHIDManagerCopyDevices( tIOHIDManagerRef );
	require( deviceCFSetRef, Oops );
	// how many devices in the set?
	CFIndex deviceIndex, deviceCount = CFSetGetCount( deviceCFSetRef );
	// allocate a block of memory to extact the device refs from the set into
	IOHIDDeviceRef* tIOHIDDeviceRefs = malloc( sizeof( IOHIDDeviceRef ) * deviceCount );
	require( tIOHIDDeviceRefs, Oops );
	// now extract the device ref's from the set
	CFSetGetValues( deviceCFSetRef, (const void **) tIOHIDDeviceRefs );
	// before we get into the device loop we'll setup our element matching dictionary
	matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( FALSE, kHIDPage_LEDs, 0 );
	require( matchingCFDictRef, Oops );
  for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ )
  {
    // if this isn't a keyboard device...
    if ( !IOHIDDeviceConformsTo( tIOHIDDeviceRefs[deviceIndex], kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard ) ) {
      //printf("skipping nonconforming device at %d\n", deviceIndex);
      continue;	// ...skip it
    }
    // copy all the elements
    CFArrayRef elementCFArrayRef = IOHIDDeviceCopyMatchingElements( tIOHIDDeviceRefs[deviceIndex],
                                     matchingCFDictRef,
                                     kIOHIDOptionsTypeNone );
    require( elementCFArrayRef, next_device );
    // iterate over all the elements
    CFIndex elementIndex, elementCount = CFArrayGetCount( elementCFArrayRef );
    for ( elementIndex = 0; elementIndex < elementCount; elementIndex++ )
    {
      IOHIDElementRef tIOHIDElementRef = ( IOHIDElementRef ) CFArrayGetValueAtIndex( elementCFArrayRef, elementIndex );
      require( tIOHIDElementRef, next_element );
      //printf("element index %d\n", (int)elementIndex);
      uint32_t usagePage = IOHIDElementGetUsagePage( tIOHIDElementRef );
      // if this isn't an LED element, skip it
      if ( kHIDPage_LEDs != usagePage ) continue;
      uint32_t usage = IOHIDElementGetUsage( tIOHIDElementRef );
      if (usage == kHIDUsage_LED_CapsLock)
      {
        //IOHIDElementType tIOHIDElementType = IOHIDElementGetType( tIOHIDElementRef );
        ledDevice = (IOHIDDeviceRef)CFRetain(tIOHIDDeviceRefs[deviceIndex]);
        ledElement = (IOHIDElementRef)CFRetain(tIOHIDElementRef);
        break;
      }
    next_element:	;
      continue;
    }
  next_device: ;
    CFRelease( elementCFArrayRef );
    continue;
  }
	if (tIOHIDManagerRef) CFRelease( tIOHIDManagerRef );
	if (matchingCFDictRef) CFRelease( matchingCFDictRef );
  free(tIOHIDDeviceRefs);
Oops:	;
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


