#import "QSO.h"

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
  //double drand48 ();
  tmp_val = (int) (drand48 () * (Number /*-1*/ ));
  new_tmp = (int) tmp_val % INT_MAX;
  return new_tmp;
}

char* Choose (char *Words[], int Number)
{
  return (Words[Roll (Number)]);
}

enum
{
  M160,
  M80,
  M40,
  M30,
  M20,
  M17,
  M15,
  M12,
  M10,
  M6,
  NUM_BAND
};

int make_freq(void)
{
  switch (Roll(NUM_BAND))
  {
    case M160:
    return (1800 + Roll(100));
    break;
    case M80:
    return (3500 + Roll(100));
    break;
    case M40:
    return (7000 + Roll(125));
    break;
    case M30:
    return (10100 + Roll(50));
    break;
    case M20:
    return (14000 + Roll(150));
    break;
    case M17:
    return (18068 + Roll(42));
    break;
    case M15:
    return (21000 + Roll(200));
    break;
    case M12:
    return (24890 + Roll(40));
    break;
    case M10:
    return (28000 + Roll(300));
    break;
    case M6:
    return (50000 + Roll(100));
    break;
    default:
    return (7000 + Roll(125));
    break;
  }
}
