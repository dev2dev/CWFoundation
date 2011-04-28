//
//  SampleAppAppDelegate.m
//  SampleApp
//
//  Created by Fredrik Olsson on 2011-02-14.
//  Copyright 2011 Jayway. All rights reserved.
//

#import "SampleAppAppDelegate.h"
#import "CWNetworkMonitor.h"

@implementation SampleAppAppDelegate

@synthesize window, label;


-(void)updateLabelWithNetworkStatus:(CWNetworkStatus)status;
{
    switch (status) {
		case CWNetworkStatusUnknown:
            self.label.text = @"Network access unknown";
            break;
        case CWNetworkStatusNotAvailable:
            self.label.text = @"Network access not available";
            break;
        case CWNetworkStatusAvailableViaWWAN:
            self.label.text = @"Network access with WWAN";
            break;
        case CWNetworkStatusAvailableViaWiFi:
            self.label.text = @"Network access with WiFi";
            break;
    }
}

-(void)netWorkStatusDidChangeNotification:(NSNotification*)notification;
{
	CWNetworkMonitor* monitor = [notification object];
    [self updateLabelWithNetworkStatus:[monitor networkStatus]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    // Register for network status updates.
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(netWorkStatusDidChangeNotification:) 
                                                 name:CWNetWorkStatusDidChangeNotification
                                               object:nil];	

    CWNetworkMonitor* monitor = [CWNetworkMonitor defaultMonitor];
    
	// Start monitoring for network updates, will trigger an initial async check.
    [monitor startMonitoringNetworkStatus];
    
    [self updateLabelWithNetworkStatus:[monitor networkStatus]];
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
