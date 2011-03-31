#import <Cocoa/Cocoa.h>

@interface QSO : NSObject
{
  NSMutableString* _qso;
  int _age; /* PERSON'S AGE, SO THEY AREN'T LICENSED MORE THAN THEIR AGE */
  NSString* _receiver;
  NSString* _sender;
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


int make_freq(void);
int Roll(int Number);


