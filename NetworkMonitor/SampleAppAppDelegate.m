//
//  SampleAppAppDelegate.m
//  CWFoundation
//  Created by Fredrik Olsson 
//
//  Copyright (c) 2011, Jayway AB All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the Jayway nor the names of its contributors may 
//       be used to endorse or promote products derived from this software 
//       without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL JAYWAY AB BE LIABLE FOR ANY DIRECT, INDIRECT, 
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
