#import "Puck.h"

BOOL enabled;

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

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 { // disable raise to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 orientation:(int)arg3 { // disable raise to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 orientation:(int)arg3 detectedAt:(unsigned long long)arg4 { // disable raise to wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

%end

%hook SBSleepWakeHardwareButtonInteraction

- (void)_performWake { // disable sleep button wake

	if (!isPuckActive)
		%orig;
	else
		return;

}

- (void)_performSleep { // disable sleep button sleep

	if (!isPuckActive)
		%orig;
	else
		return;

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

- (void)increaseVolume { // respring after three volume up steps when active

	%orig;

	if (!isPuckActive || !wakeWithVolumeButtonSwitch) return;
	timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resetPresses) userInfo:nil repeats:NO];

	if (!timer) return;
	volumeUpPresses += 1;
	if (volumeUpPresses == 3)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

%new
- (void)resetPresses { // reset presses after timer is up

	volumeUpPresses = 0;
	[timer invalidate];
	timer = nil;

}

%end

%hook SBUIController

- (void)updateBatteryState:(id)arg1 { // automatic shutdown and wake

	%orig;

	if ([self batteryCapacityAsPercentage] != shutdownPercentageValue)
		recentlyWoke = NO;

	if ([self batteryCapacityAsPercentage] == shutdownPercentageValue && ![self isOnAC] && !isPuckActive && !recentlyWoke)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckCallNotification" object:nil];

	if ([self batteryCapacityAsPercentage] == wakePercentageValue && [self isOnAC] && isPuckActive)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

- (void)ACPowerChanged { // wake after plugged in

	%orig;

	if (wakeWhenPluggedInSwitch && isPuckActive && [self isOnAC])
		[[NSNotificationCenter defaultCenter] postNotificationName:@"puckWakeNotification" object:nil];

}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // register puck notifications

	%orig;

	recentlyWoke = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePuckNotification:) name:@"puckCallNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePuckNotification:) name:@"puckWakeNotification" object:nil];

}

%new
- (void)receivePuckNotification:(NSNotification *)notification {

	if ([notification.name isEqual:@"puckCallNotification"]) { // shutdown
		SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
		[springboard _simulateLockButtonPress]; // lock device
		[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:YES]; // enable airplane mode
		[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil]; // enable low power mode
		isPuckActive = YES;

		if (!allowMusicPlaybackSwitch) { // stop music
			pid_t pid;
			const char* args[] = {"killall", "mediaserverd", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const *)args, NULL);
		}
	} else if ([notification.name isEqual:@"puckWakeNotification"]) { // wake
		isPuckActive = NO;
		[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:NO]; // disable airplane mode
		[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable low power mode

		pid_t pid;
		const char* args[] = {"killall", "backboardd", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const *)args, NULL);
	}

}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.puckpreferences"];

	[preferences registerBool:&enabled default:NO forKey:@"Enabled"];

	[preferences registerInteger:&shutdownPercentageValue default:5 forKey:@"shutdownPercentage"];
	[preferences registerInteger:&wakePercentageValue default:10 forKey:@"wakePercentage"];
	[preferences registerBool:&wakeWithVolumeButtonSwitch default:YES forKey:@"wakeWithVolumeButton"];
	[preferences registerBool:&wakeWhenPluggedInSwitch default:NO forKey:@"wakeWhenPluggedIn"];
	[preferences registerBool:&allowMusicPlaybackSwitch default:NO forKey:@"allowMusicPlayback"];

	if (enabled) {
		%init(Puck);
	}
	
}