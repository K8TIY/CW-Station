#import <Cocoa/Cocoa.h>

extern const unichar gOverline;

@interface QSO : NSObject
{
  NSMutableString* _qso;
  int _age; /* PERSON'S AGE, SO THEY AREN'T LICENSED MORE THAN THEIR AGE */
  NSString* _receiver;
  NSString* _sender;
  NSString* _delim; // Can be BT, . (period), or nothing
}
-(NSString*)QSO;
@end

@interface QSO (Private)
-(void)putMisc;
-(void)putThanks;
-(void)putName;
-(void)putJob;
-(void)putAge;
-(void)putLicense;
-(void)putTemperature;
-(void)putWeather1;
-(void)putWeather2;
-(void)putWeather;
-(void)putCityState;
-(void)putLocation;
-(void)putRig;
-(void)putRST;
-(void)putQFreq;
-(void)putFirstCallsign;
-(void)putLastCallsign;
-(int)licenseSeed;
@end

@interface QSO (Form)
-(void)putForm0;
-(void)putForm1;
-(void)putForm2;
-(void)putForm3;
-(void)putForm4;
-(void)putForm5;
-(void)PutQSO;
@end

enum
{
  M160 = 1,
  M80,
  M40,
  M30,
  M20,
  M17,
  M15,
  M12,
  M10,
  M6,
  M2
};

int MakeFrequency(unsigned band, BOOL voice);
unsigned Roll(unsigned Number);
NSString* Choose(NSString* name);

