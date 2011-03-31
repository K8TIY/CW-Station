/*
Copyright © 2010-2011 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import "Wordlist.h"

@interface Wordlist (Private)
-(NSString*)getEntryAtOffset:(NSNumber*)n;
@end

@implementation Wordlist
-(id)init
{
  self = [super init];
  offsets = [[NSMutableDictionary alloc] init];
  off_t offset = 0, pos = 0;
  FILE* fp = fopen("/usr/share/dict/words", "r");
  unsigned len = 0;
  while (YES)
  {
    char c;
    size_t read = fread(&c, 1, 1, fp);
    if (!read) break;
    //printf("c %C (len %d)\n", c, len);
    if (c == 0x0A || !pos)
    {
      if (len < 10 || !pos)
      {
        //printf("== len %d off %lld\n", len, offset);
        NSNumber* n = [[NSNumber alloc] initWithUnsignedInt:len];
        NSMutableArray* a = [offsets objectForKey:n];
        if (!a)
        {
          a = [[NSMutableArray alloc] init];
          [offsets setObject:a forKey:n];
          [a release];
        }
        [n release];
        n = [[NSNumber alloc] initWithUnsignedLongLong:(pos)? offset+1:0L];
        [a addObject:n];
        [n release];
      }
      len = 0;
      offset = pos;
    }
    else len++;
    pos++;
  }
  fclose(fp);
  return self;
}

-(void)dealloc
{
  [offsets release];
  [super dealloc];
}

-(NSString*)randomStringOfLength:(unsigned)length
{
  NSArray* a = [offsets objectForKey:[NSNumber numberWithUnsignedInt:length]];
  //NSLog(@"Array 0x%8X of %d items from length %d", a, [a count], length);
  NSString* str = [[self getEntryAtOffset:[a objectAtIndex:arc4random() % [a count]]] uppercaseString];
  return str;
}

-(NSString*)getEntryAtOffset:(NSNumber*)n
{
  NSMutableString* s = [[NSMutableString alloc] init];
  off_t offset = [n unsignedLongLongValue];
  FILE* fp = fopen("/usr/share/dict/words", "r");
  fseeko(fp, offset, SEEK_SET);
  while (YES)
  {
    char c;
    size_t read = fread(&c, 1, 1, fp);
    if (!read || c == 0x0A) break;
    [s appendString:[NSString stringWithFormat:@"%C", c]];
    offset++;
  }
  fclose(fp);
  NSString* ret = [NSString stringWithString:s];
  [s release];
  return ret;
}
@end
