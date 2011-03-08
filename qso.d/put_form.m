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
    [self putQ_And_Freq];
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
    [self putQ_And_Freq];
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
    [self putQ_And_Freq];
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
    [self putQ_And_Freq];
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
    [self putQ_And_Freq];
}

-(void)PutQSO
{
    
  [self putFirstCallsign];
  switch (Roll (6))
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
  unichar ol = 0x0305;
  [_qso appendFormat:@"A%CR%C S%CK%C\n", ol, ol, ol, ol];
  [self putLastCallsign];
  [_qso appendFormat:@"\n"];
}
@end
