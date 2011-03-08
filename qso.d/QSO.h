#import <Cocoa/Cocoa.h>

@interface QSO : NSObject
{
  NSMutableString* _qso;
  int _age; /* PERSON'S AGE, SO THEY AREN'T LICENSED MORE THAN THEIR AGE */
  char* _receiver;
  char* _sender;
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
-(void)putQ_And_Freq;
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

char* A_Or_An (char* string);
int make_freq(void);
int CountStrings(char* StringVector[]);
int CountNSStrings(NSString* StringVector[]);
int Roll (int Number);
char* Choose (char *Words[], int Number);
int make_freq(void);
