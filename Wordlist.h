/*
Copyright © 2010-2012 Brian S. Hall

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

@interface Wordlist : NSObject
{
  NSMutableDictionary* offsets; // NSNumber (# of words) -> NSArray of NSNumber (offset in file)
}
-(NSString*)randomStringOfLength:(unsigned)length;
@end
