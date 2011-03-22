#import <Cocoa/Cocoa.h>

@interface Levenshtein : NSObject
{
  NSString*  _s1;
  NSString*  _s2;
  void*      _d;
  NSUInteger _distance;
}
-(id)initWithString:(NSString*)string1 andString:(NSString*)string2;
-(NSUInteger)distance;
-(NSArray*)alignmentWithPlaceholder:(NSString*)p;
@end


