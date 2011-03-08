#import "QSO.h"
/*
 ********************
 * Utility routines *
 ********************
 */
//extern int their_age;

int CountStrings (char* StringVector[])
     /*
      * Count the number of string values in the supplied vector
      * of pointers. Start with the first pointer and stop when
      * NIL (0) is encountered.
      */
{
  register char **SV;
  register int Count = 0;

  for (SV = StringVector; *SV; SV++) Count++;
  return Count;
}

int CountNSStrings(NSString* StringVector[])
{
  register NSString **SV;
  register int Count = 0;

  for (SV = StringVector; *SV; SV++) Count++;
  return (Count);
}

int Roll(int Number)
{
int new_tmp;
double tmp_val;
double drand48 ();
    tmp_val = ((int) (drand48 () * (Number /*-1*/ )));
    new_tmp = (int) tmp_val % 32767;
    if (new_tmp < 2)
	tmp_val = 2;
    return ((int) new_tmp);
}

char* Choose (char *Words[], int Number)
{
  return (Words[Roll (Number)]);
}

#define M80 2
#define M40 3
#define M15 4
#define M10 5
#define NUM_BAND 4

int make_freq(void)
{
  switch (Roll(NUM_BAND + 2))
  {
    case M80:
    return (3675 + Roll(50));
    break;
    case M40:
    return (7100 + Roll(50));
    break;
    case M15:
    return (21100 + Roll(100));
    break;
    case M10:
    return (28100 + Roll(200));
    break;
    default:
    return (7100 + Roll(50));
    break;
  }
}
