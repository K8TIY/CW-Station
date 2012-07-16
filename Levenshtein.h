/*
Copyright © 2010-2012 Brian S. Hall
Loosely based on NString-Levenshtein by Rick Bourner

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 or later as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import <Cocoa/Cocoa.h>

@interface Levenshtein : NSObject
{
  NSString*  _s1;
  NSString*  _s2;
  void*      _d;
  unsigned   _distance;
}
-(id)initWithString:(NSString*)string1 andString:(NSString*)string2;
-(unsigned)distance;
-(NSArray*)alignmentWithPlaceholder:(NSString*)p;
@end


