//
//  SampleAppAppDelegate.h
//  SampleApp
//
//  Created by Fredrik Olsson on 2011-02-14.
//  Copyright 2011 Jayway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SampleAppAppDelegate : NSObject <UIApplicationDelegate> {
@private
    UIWindow* window;
    UIViewController* rootController;
}

@property(nonatomic, retain) IBOutlet UIWindow* window;
@property(nonatomic, retain) IBOutlet UIViewController* rootController;

@end

