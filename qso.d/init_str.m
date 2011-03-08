#include <Cocoa/Cocoa.h>

char *Transceiver[] =
{
#include "rig.h"
    0
};

char *Antenna[] =
{
#include "antenna.h"
    0
};

char *UpFeet[] =
{
    "10", "15", "20", "25", "30", "35", "40", "45",
    "50", "55", "60", "65", "70", "75", "80", "85",
    "90", "95", "100",
    "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
    "10 1/2", "11 1/2", "25", "29 1/2", "30", "35", "40", "42",
    "45", "45 1/2", "45.5",
    "50", "55", "60", "62", "65", "70", "75", "80", "85", "87 1/3",
    "90", "95", "100", "103", "137", "189 1/2", "210", "246", "250",
    0
};

char *Weather1[] =
{
    "sunny",
    "rain",
    "freezing rain",
    "sleet",
    "snow",
    "cloudy",
    "partly cloudy",
    "partly sunny",
    "clear",
    0
};

char *Weather2[] =
{
#include "weather.h"
    0
};

char *Power[] =
{
    "2", "5", "10", "20", "25", "40", "50", "80", "100",
    "125", "140", "150", "170", "200", "250", "270", "300",
    0
};

char *Job[] =
{
#include "jobs.h"
    0
};

char *Name[] =
{
#include "names.h"
    0
};

char *CallSign[] =
{
#include "callsign.h"
    0
};

char *License[] =
{
    "novice",
    "technician",
    "tech",
    "tech",
    "tech",
    "tech",
    "tech",
    "tech plus",
    "tech no code",
    "general",
    "general",
    "general",
    "general",
    "advanced",
    "extra",
    "extra",
    "extra",
    0
};

char *City[] =
{
#include "city.h"
    0
};

char *NewCity[] =
{
#include "newcity.h"
    0
};

char *CityHeights[] =
{
#include "cityh.h"
    0
};

char *New[] =
{
    "new",
    "old",
    "north",
    "south",
    "east",
    "west",
    "new",
    "old",
    "north",
    "northeast",
    "northwest",
    "south",
    "southwest",
    "southeast",
    "east",
    "west",
    "upper",
    "lower",
    0
};

char *Heights[] =
{
#include "heights.h"
    0
};

char *State[] =
{
  "alabama",
  "alaska",
  "arizona",
  "arkansas",
  "california",
  "colorado",
  "connecticut",
  "district of columbia",
  "delaware",
  "florida",
  "georgia",
  "guam",
  "hawaii",
  "idaho",
  "illinois",
  "indiana",
  "iowa",
  "kansas",
  "kentucky",
  "louisiana",
  "maine",
  "maryland",
  "massachusetts",
  "michigan",
  "midway",
  "minnesota",
  "mississippi",
  "missouri",
  "montana",
  "nebraska",
  "nevada",
  "new hampshire",
  "new jersey",
  "new mexico",
  "new york",
  "north carolina",
  "north dakota",
  "ohio",
  "oklahoma",
  "oregon",
  "pennsylvania",
  "puerto rico",
  "rhode island",
  "saipan",
  "american samoa",
  "south carolina",
  "south dakota",
  "tennessee",
  "texas",
  "utah",
  "vermont",
  "virginia",
  "virgin islands",
  "wake island",
  "washington",
  "west virginia",
  "wisconsin",
  "wyoming",
  0
};

NSString *Frqmisc[] =
{
    @"qsn %d?",
    @"qsu %d?",
    @"qsw %d?",
    @"qsn %d",
    @"qsu %d",
    @"qsw %d",
    0
};

NSString* Callmisc[] =
{
    @"qrk %s",
    @"qrl %s",
    @"qrz %s",
    @"qsp %s",
    @"qrk %s?",
    @"qrl %s?",
    @"qrz %s?",
    @"qsp %s?",
    0
};

NSString* FrqCallmisc[] =
{
    @"qrw %s %d",
    @"qrz %s %d",
    @"qsn %s %d",
    @"qsx %s %d",
    @"qrw %s %d?",
    @"qrz %s %d?",
    @"qsn %s %d?",
    @"qsx %s %d?",
    0
};

NSString* NumMisc[] =
{
    @"qri %d",
    @"qrk %d",
    @"qrm %d",
    @"qrn %d",
    @"qrs %d",
    @"qry %d",
    @"qsg %d",
    @"qta %d",
    @"qtc %d",
    @"qri %d?",
    @"qrk %d?",
    @"qrm %d?",
    @"qrn %d?",
    @"qrs %d?",
    @"qry %d?",
    @"qsg %d?",
    @"qta %d?",
    @"qtc %d?",
    0
};

char *Miscellaneous[] =
{
#include "misc.h"
    0
};

char *RST[] =
{
    "555",
    "577",
    "578",
    "579",
    "588",
    "589",
    "599",
    "478",
    "354",
    "248",
    "126",
    0
};
