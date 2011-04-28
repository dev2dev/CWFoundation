//
//  SampleAppAppDelegate.m
//  SampleApp
//
//  Created by Fredrik Olsson on 2011-02-14.
//  Copyright 2011 Jayway. All rights reserved.
//

#import "SampleAppAppDelegate.h"

@implementation SampleAppAppDelegate

@synthesize window, rootController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    [self.window addSubview:self.rootController.view];
    [self.window makeKeyAndVisible];    
    return YES;
}

- (void)dealloc;
{
    [window release];
    [rootController release];
    [super dealloc];
}


@end
