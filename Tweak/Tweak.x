#import "Puck.h"

BOOL enabled;

AVFlashlight* flashlight;

// warning notification
static BBServer* bbServer = nil;

static dispatch_queue_t getBBServerQueue() {

    static dispatch_queue_t queue;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
    void* handle = dlopen(NULL, RTLD_GLOBAL);
        if (handle) {
            dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
            if (pointer) queue = *pointer;
            dlclose(handle);
        }
    });

    return queue;

}

static void fakeNotification(NSString *sectionID, NSDate *date, NSString *message, bool banner) {
    
	BBBulletin* bulletin = [[%c(BBBulletin) alloc] init];

	bulletin.title = @"Puck";
    bulletin.message = message;
    bulletin.sectionID = sectionID;
    bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.date = date;
    bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID:sectionID callblock:nil];
    bulletin.clearable = YES;
    bulletin.showsMessagePreview = YES;
    bulletin.publicationDate = date;
    bulletin.lastInterruptDate = date;

    if (banner) {
        if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:15];
            });
        }
    } else {
        if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:alwaysToLockScreen:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4 alwaysToLockScreen:YES];
            });
        } else if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4];
            });
        }
    }

}

void PCKWarningNotification() {

    fakeNotification(@"com.apple.Preferences", [NSDate date], @"Your device will be shut down soon", true);

}

void PuckActivatorShutdown() {

	[[NSNotificationCenter defaultCenter] postNotificationName:@"puckShutdownNotification" object:nil];

}

void PuckActivatorWake() {

	[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

%group Puck

%hook SBTapToWakeController

- (void)tapToWakeDidRecognize:(id)arg1 { // disable tap to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)pencilToWakeDidRecognize:(id)arg1 { // disable apple pencil tap to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBLiftToWakeController

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 orientation:(int)arg3 { // disable raise to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBSleepWakeHardwareButtonInteraction

- (void)_performWake { // disable sleep button

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)_performSleep { // disable sleep button

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBLockHardwareButtonActions

- (BOOL)disallowsSinglePressForReason:(id*)arg1 { // disable sleep button

	if (!isPuckActive)
		return %orig;
	else
		return YES;

}

- (BOOL)disallowsDoublePressForReason:(id *)arg1 { // disable sleep button

	if (!isPuckActive)
		return %orig;
	else
		return YES;

}

- (BOOL)disallowsTriplePressForReason:(id*)arg1 { // disable sleep button

	if (!isPuckActive)
		return %orig;
	else
		return YES;

}

- (BOOL)disallowsLongPressForReason:(id*)arg1 { // disable sleep button

	if (!isPuckActive)
		return %orig;
	else
		return YES;
	
}

%end

%hook SBHomeHardwareButton

- (void)initialButtonDown:(id)arg1 { // disable home button

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)singlePressUp:(id)arg1 { // disable home button

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBHomeHardwareButtonActions

- (void)performLongPressActions { // disable home button

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBRingerControl

- (void)setRingerMuted:(BOOL)arg1 { // disable ringer switch

	if (!isPuckActive)
		%orig;
	else
		%orig(NO);

}

%end

%hook SBBacklightController

- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 { // prevent display from turning on

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBVolumeControl

- (void)increaseVolume { // wake after three volume up steps when active

	if (!isPuckActive || (isPuckActive && allowVolumeChangesSwitch)) %orig;

	if (!isPuckActive || !wakeWithVolumeButtonSwitch) return;
	timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resetPresses) userInfo:nil repeats:NO];

	if (!timer) return;
	volumeUpPresses += 1;
	if (volumeUpPresses == 3)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

- (void)decreaseVolume { // other gestures when pressing volume down

	if (!isPuckActive || (isPuckActive && allowVolumeChangesSwitch)) %orig;

	if (isPuckActive) {
		if (toggleFlashlightSwitch) {
			if (deviceHasFlashlight && flashLightAvailable && !flashlight && (turnFlashlightOffSwitch || toggleFlashlightSwitch)) flashlight = [[%c(AVFlashlight) alloc] init];
			if ([flashlight flashlightLevel] == 0)
				[flashlight setFlashlightLevel:1 withError:nil];
			else
				[flashlight setFlashlightLevel:0 withError:nil];
		}
		if (playPauseMediaSwitch && allowMusicPlaybackSwitch) {
			[[%c(SBMediaController) sharedInstance] togglePlayPauseForEventSource:0];
		}
	}

}

%new
- (void)resetPresses { // reset presses after timer is up

	volumeUpPresses = 0;
	[timer invalidate];
	timer = nil;

}

%end

%hook TUCall

- (int)status { // check if user is currently in a call & shutdown after call ended

	int status = %orig;

	if (status == 1 && allowCallsSwitch)
		isInCall = YES;
	else
		isInCall = NO;

	if (status == 6 && shutdownAfterCallEndedSwitch && [[%c(SBUIController) sharedInstance] batteryCapacityAsPercentage] <= shutdownPercentageValue && !isPuckActive)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckShutdownNotification" object:nil];

	return status;

}

%end

%hook SBUIController

- (void)updateBatteryState:(id)arg1 { // automatic shutdown, wake & warning notification

	%orig;

	if ([self batteryCapacityAsPercentage] != shutdownPercentageValue)
		recentlyWoke = NO;
	
	if ([self batteryCapacityAsPercentage] > warningPercentageValue)
		recentlyWarned = NO;

	if ([self batteryCapacityAsPercentage] == shutdownPercentageValue && ![self isOnAC] && !recentlyWoke && !isInCall && !isPuckActive)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckShutdownNotification" object:nil];

	if ([self batteryCapacityAsPercentage] == wakePercentageValue && [self isOnAC] && isPuckActive)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

	if (warningNotificationSwitch && [self batteryCapacityAsPercentage] == warningPercentageValue && ![self isOnAC] && !recentlyWarned && !isInCall && !isPuckActive) {
		PCKWarningNotification();
		recentlyWarned = YES;
	}

}

- (void)ACPowerChanged { // wake after plugged in

	%orig;

	if (wakeWhenPluggedInSwitch && [self isOnAC] && isPuckActive)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

%end

%hook CSModalButton

- (void)didMoveToWindow { // disable puck when alarm fires

	%orig;

	if (!wakeWhenAlarmFiresSwitch) return;

	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:NO];
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil];
	isPuckActive = NO;
	recentlyWoke = YES;

}

%end

%hook AVFlashlight

+ (BOOL)hasFlashlight { // detect if device has a flashlight

	deviceHasFlashlight = %orig;

	return deviceHasFlashlight;

}

- (BOOL)isAvailable { // detect if flashlight is available

	flashLightAvailable = %orig;

	return flashLightAvailable;

}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // register puck notifications

	%orig;

	recentlyWoke = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePuckNotification:) name:@"puckShutdownNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePuckNotification:) name:@"puckWakeNotification" object:nil];
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Activator.plist"]) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PuckActivatorShutdown, (CFStringRef)ShutdownNotification, NULL, kNilOptions);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PuckActivatorWake, (CFStringRef)WakeNotification, NULL, kNilOptions);
	}

}

%new
- (void)receivePuckNotification:(NSNotification *)notification {

	if ([notification.name isEqual:@"puckShutdownNotification"]) {
		if (isPuckActive) return;
		isPuckActive = YES;
		SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
		[springboard _simulateLockButtonPress];
		[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:YES];
		[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil];
		if (deviceHasFlashlight && flashLightAvailable && !flashlight && (turnFlashlightOffSwitch || toggleFlashlightSwitch)) flashlight = [[%c(AVFlashlight) alloc] init];
		if (turnFlashlightOffSwitch) [flashlight setFlashlightLevel:0 withError:nil];

		if (!allowMusicPlaybackSwitch) {
			NSTask* task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/killall"];
			[task setArguments:[NSArray arrayWithObjects:@"mediaserverd", nil]];
			[task launch];
		}
	} else if ([notification.name isEqual:@"puckWakeNotification"]) {
		if (!isPuckActive) return;
		isPuckActive = NO;
		[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:NO];
		[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil];
		recentlyWoke = YES;
		
		if (!respringOnWakeSwitch) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
				[springboard _simulateHomeButtonPress];
			});
		} else {
			NSTask* task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/killall"];
			[task setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
			[task launch];
		}
	}

}

%end

%end

%group WarningNotification

%hook BBServer

- (id)initWithQueue:(id)arg1 {

    bbServer = %orig;
    
    return bbServer;

}

- (id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 {
    
    bbServer = %orig;

    return bbServer;

}

- (void)dealloc {

    if (bbServer == self) bbServer = nil;

    %orig;

}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.puckpreferences"];

	[preferences registerBool:&enabled default:NO forKey:@"Enabled"];

	// behavior
	[preferences registerInteger:&shutdownPercentageValue default:7 forKey:@"shutdownPercentage"];
	[preferences registerInteger:&wakePercentageValue default:10 forKey:@"wakePercentage"];
	[preferences registerBool:&wakeWithVolumeButtonSwitch default:YES forKey:@"wakeWithVolumeButton"];
	[preferences registerBool:&wakeWhenPluggedInSwitch default:YES forKey:@"wakeWhenPluggedIn"];
	[preferences registerBool:&respringOnWakeSwitch default:NO forKey:@"respringOnWake"];

	// music
	[preferences registerBool:&allowMusicPlaybackSwitch default:YES forKey:@"allowMusicPlayback"];
	[preferences registerBool:&allowVolumeChangesSwitch default:YES forKey:@"allowVolumeChanges"];

	// warning notification
	[preferences registerBool:&warningNotificationSwitch default:YES forKey:@"warningNotification"];
	[preferences registerInteger:&warningPercentageValue default:10 forKey:@"warningPercentage"];

	// calls
	[preferences registerBool:&allowCallsSwitch default:YES forKey:@"allowCalls"];
	[preferences registerBool:&shutdownAfterCallEndedSwitch default:YES forKey:@"shutdownAfterCallEnded"];

	// alarms
	[preferences registerBool:&wakeWhenAlarmFiresSwitch default:YES forKey:@"wakeWhenAlarmFires"];
	
	// flashlight
	[preferences registerBool:&turnFlashlightOffSwitch default:YES forKey:@"turnFlashlightOff"];

	// other gestures
	[preferences registerBool:&toggleFlashlightSwitch default:NO forKey:@"toggleFlashlight"];
	[preferences registerBool:&playPauseMediaSwitch default:NO forKey:@"playPauseMedia"];

	if (enabled) {
		%init(Puck);
		if (warningNotificationSwitch) %init(WarningNotification);
	}
	
}