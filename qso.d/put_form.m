#include <QSO.h>

@implementation QSO (Form)
-(void)putForm0
{
  [self putRST];
  [self putName];
  [self putLocation];
  [self putMisc];
  [self putRig];
  [self putWeather];
  [self putJob];
  [self putAge];
  [self putMisc];
  [self putQFreq];
  [self putLicense];
}

-(void)putForm1
{
  [self putLocation];
  [self putRST];
  [self putRig];
  [self putWeather];
  [self putMisc];
  [self putName];
  [self putLicense];
  [self putMisc];
  [self putQFreq];
  [self putAge];
  [self putJob];
}

-(void)putForm2
{
  [self putThanks];
  [self putRST];
  [self putName];
  [self putWeather];
  [self putLocation];
  [self putJob];
  [self putLicense];
  [self putRig];
  [self putAge];
  [self putQFreq];
}

-(void)putForm3
{
  [self putLocation];
  [self putRST];
  [self putRig];
  [self putMisc];
  [self putName];
  [self putMisc];
  [self putAge];
  [self putJob];
  [self putLicense];
  [self putMisc];
  [self putWeather];
  [self putMisc];
  [self putQFreq];
}

-(void)putForm4
{
  [self putThanks];
  [self putRST];
  [self putJob];
  [self putMisc];
  [self putMisc];
  [self putName];
  [self putAge];
  [self putLicense];
  [self putRig];
  [self putLocation];
  [self putWeather];
  [self putMisc];
}

-(void)putForm5
{
  [self putLocation];
  [self putRST];
  [self putRig];
  [self putName];
  [self putJob];
  [self putAge];
  [self putMisc];
  [self putLicense];
  [self putWeather];
  [self putMisc];
  [self putQFreq];
}

-(void)PutQSO
{
  [self putFirstCallsign];
  unsigned roll = Roll(6);
  switch (roll)
  {
    case 0:
    [self putForm0];
    break;
    case 1:
    [self putForm1];
    break;
    case 2:
    [self putForm2];
    break;
    case 3:
    [self putForm3];
    break;
    case 4:
    [self putForm4];
    break;
    default:
    [self putForm5];
    break;
  }
  [self putLastCallsign];
}
@end
