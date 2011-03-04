#import <Cocoa/Cocoa.h>

@interface Wordlist : NSObject
{
  NSMutableDictionary* offsets; // NSNumber (number of words) -> NSArray of NSNumber (offset in file)
}
-(NSString*)randomStringOfLength:(NSUInteger)length;
@end
