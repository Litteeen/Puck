#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <spawn.h>
#import <dlfcn.h>

#define LTOpenNotification @"love.litten.puck/Shutdown"

HBPreferences* preferences;

BOOL isPuckActive = NO;
BOOL recentlyWoke = NO;
BOOL recentlyWarned = NO;
BOOL isInCall = NO;
NSTimer* timer = nil;
int volumeUpPresses = 0;

extern BOOL enabled;

// behavior
NSInteger shutdownPercentageValue = 7;
NSInteger wakePercentageValue = 10;
BOOL wakeWithVolumeButtonSwitch = YES;
BOOL wakeWhenPluggedInSwitch = YES;
BOOL respringOnWakeSwitch = NO;

// music
BOOL allowMusicPlaybackSwitch = YES;
BOOL allowVolumeChangesSwitch = YES;

// warning notification
BOOL warningNotificationSwitch = YES;
NSInteger warningPercentageValue = 10;

// calls
BOOL allowCallsSwitch = YES;
BOOL shutdownAfterCallEndedSwitch = YES;

// device locking and waking
@interface SpringBoard : UIApplication
- (void)_simulateLockButtonPress;
- (void)_simulateHomeButtonPress;
- (void)receivePuckNotification:(NSNotification *)notification;
@end

// airplane mode
@interface SBAirplaneModeController : NSObject
+ (id)sharedInstance;
- (void)setInAirplaneMode:(BOOL)arg1;
@end

// low power mode
@interface _CDBatterySaver : NSObject
+ (id)sharedInstance;
- (BOOL)setPowerMode:(long long)arg1 error:(id *)arg2;
@end

// battery state
@interface SBUIController : NSObject
+ (id)sharedInstance;
- (int)batteryCapacityAsPercentage;
- (BOOL)isOnAC;
@end

// warning notification
@interface BBAction : NSObject
+ (id)actionWithLaunchBundleID:(id)arg1 callblock:(id)arg2;
@end

@interface BBBulletin : NSObject
@property(nonatomic, copy)NSString* sectionID;
@property(nonatomic, copy)NSString* recordID;
@property(nonatomic, copy)NSString* publisherBulletinID;
@property(nonatomic, copy)NSString* title;
@property(nonatomic, copy)NSString* message;
@property(nonatomic, retain)NSDate* date;
@property(assign, nonatomic)BOOL clearable;
@property(nonatomic)BOOL showsMessagePreview;
@property(nonatomic, copy)BBAction* defaultAction;
@property(nonatomic, copy)NSString* bulletinID;
@property(nonatomic, retain)NSDate* lastInterruptDate;
@property(nonatomic, retain)NSDate* publicationDate;
@end

@interface BBServer : NSObject
- (void)publishBulletin:(BBBulletin *)arg1 destinations:(NSUInteger)arg2 alwaysToLockScreen:(BOOL)arg3;
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2;
@end

@interface BBObserver : NSObject
@end

@interface NCBulletinNotificationSource : NSObject
- (BBObserver *)observer;
@end

@interface SBNCNotificationDispatcher : NSObject
- (NCBulletinNotificationSource *)notificationSource;
@end