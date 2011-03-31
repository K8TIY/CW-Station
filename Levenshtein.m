/*
Copyright © 2010-2011 Brian S. Hall
Loosely based on NString-Levenshtein by Rick Bourner

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

#import "Levenshtein.h"

static unsigned SmallestOf(unsigned a, unsigned b, unsigned c);
#define LEV_DEBUG 0

@interface Levenshtein (Private)
-(void)_updateDistance;
@end

enum
{
  levPtrLeft   = 1 << 0,
  levPtrUp     = 1 << 1,
  levPtrUpLeft = 1 << 2
};

typedef struct
{
  unsigned d;
  unsigned p;
} LevCell;

@implementation Levenshtein
-(id)initWithString:(NSString*)string1 andString:(NSString*)string2
{
  self = [super init];
  _s1 = [string1 copy];
  _s2 = [string2 copy];
  [self _updateDistance];
  return self;
}

-(NSString*)description
{
  NSMutableString* desc = [NSMutableString stringWithFormat:@"%@ '%@' vs '%@' = %ld (0x%X)", [super description], _s1, _s2, _distance, _d];
  if (_d)
  {
    [desc appendFormat:@"\n\n<table border='1'>\n"];
    unsigned n = [_s1 length] + 1;
    unsigned m = [_s2 length] + 1;
    unsigned i, j;
    if (n && m)
    {
      LevCell* d = _d;
      for (i = -1; i < n; i++)
      {
        [desc appendFormat:@"<tr><th>%C</th>", (i > 0)? [_s1 characterAtIndex:i-1]:' '];
        for (j = 0; j < m; j++)
        {
          LevCell* dp = &d[j * n + i];
          if (i == -1) [desc appendFormat:@"<th>%C</th>", (j > 0)? [_s2 characterAtIndex:j-1]:' '];
          else [desc appendFormat:@"<td>%ld %s%s%s</td>", dp->d, (dp->p & levPtrUpLeft)? "&#x2196":"", (dp->p & levPtrLeft)? "&#x2190":"", (dp->p & levPtrUp)? "&#x2191":""];
        }
        [desc appendString:@"</tr>\n"];
      }
    }
    [desc appendFormat:@"</table>"];
  }
  NSArray* alignment = [self alignmentWithPlaceholder:@"_"];
  NSString* s1 = [alignment objectAtIndex:0];
  NSString* s2 = [alignment objectAtIndex:1];
  [desc appendFormat:@"<br/><br/>%@<br/>%@", s1, s2];
  return [NSString stringWithString:desc];
}

-(NSArray*)alignmentWithPlaceholder:(NSString*)p
{
  NSMutableString* desc1 = [NSMutableString string];
  NSMutableString* desc2 = [NSMutableString string];
  unsigned n = [_s1 length] + 1;
  unsigned m = [_s2 length] + 1;
  unsigned i = n - 1;
  unsigned j = m - 1;
  LevCell* d = _d;
  while (YES)
  {
    unichar c1 = (i>0)? [_s1 characterAtIndex:i-1]:' ';
    unichar c2 = (j>0)? [_s2 characterAtIndex:j-1]:' ';
    LevCell* dp = &d[j * n + i];
  #if LEV_DEBUG
    NSLog(@"0x%X", dp);
  #endif
    unsigned ptr = dp->p;
    if (ptr & levPtrUpLeft)
    {
      [desc1 setString:[NSString stringWithFormat:@"%C%@", c1, desc1]];
      [desc2 setString:[NSString stringWithFormat:@"%C%@", c2, desc2]];
      i--;
      j--;
    #if LEV_DEBUG
      NSLog(@"Up Left at %d (%C,%C), i=%d, j=%d", dp->d, c1, c2, i, j);
    #endif
    }
    else if (ptr & levPtrUp)
    {
      [desc1 setString:[NSString stringWithFormat:@"%C%@", c1, desc1]];
      [desc2 setString:[NSString stringWithFormat:@"%@%@", p, desc2]];
      i--;
    #if LEV_DEBUG
      NSLog(@"Up at %d (%C,%C), i=%d, j=%d", dp->d, c1, c2, i, j);
    #endif
    }
    else if (ptr & levPtrLeft)
    {
      [desc1 setString:[NSString stringWithFormat:@"%@%@", p, desc1]];
      [desc2 setString:[NSString stringWithFormat:@"%C%@", c2, desc2]];
      j--;
    #if LEV_DEBUG
      NSLog(@"Left at %d (%C,%C), i=%d, j=%d", dp->d, c1, c2, i, j);
    #endif
    }
    else break;
  }
  return [NSArray arrayWithObjects:desc1, desc2, NULL];
}

-(void)dealloc
{
  if (_d) free(_d);
  [_s1 release];
  [_s2 release];
  [super dealloc];
}

-(unsigned)distance
{
  return _distance;
}

-(void)_updateDistance
{
  // Step 1
  unsigned k, i, j;
  if (_d) free(_d);
  _distance = 0;
  unsigned n = [_s1 length] + 1;
  unsigned m = [_s2 length] + 1;
  _d = calloc( sizeof(LevCell), m * n );
  LevCell* d = _d;
  // Step 2
  for (k = 0; k < n; k++)
  {
    d[k].d = k;
    if (k > 0) d[k].p = levPtrUp;
  }
  for (k = 0; k < m; k++)
  {
    d[k * n].d = k;
    if (k > 0) d[k * n].p = levPtrLeft;
  }
  // Step 3 and 4
  for (i = 1; i < n; i++)
  {
    unichar c1 = [_s1 characterAtIndex:i-1];
    for (j = 1; j < m; j++)
    {
      char cost = 1;
      // Step 5
      if (c1 == [_s2 characterAtIndex:j-1]) cost = 0;
      // Step 6
      unsigned ptr = 0;
      unsigned up = d[j * n + i - 1].d;
      unsigned left = d[(j - 1) * n + i].d;
      unsigned upLeft = d[(j - 1) * n + i - 1].d;
      unsigned score = SmallestOf(up + 1, left + 1, upLeft + cost);
      d[j * n + i].d = score;
      if (score == left + 1) ptr |= levPtrLeft;
      if (score == up + 1) ptr |= levPtrUp;
      if (score == upLeft + cost) ptr |= levPtrUpLeft;
      d[j * n + i].p = ptr;
      //NSLog(@"'%C' vs '%C': %d/%d at position %d", c1, [_s2 characterAtIndex:j-1], score, ptr, j * n + i);
    }
  }
  _distance = d[n * m - 1].d;
}
@end

static unsigned SmallestOf(unsigned a, unsigned b, unsigned c)
{
  unsigned min = a;
  if (b < min) min = b;
  if (c < min) min = c;
  return min;
}
