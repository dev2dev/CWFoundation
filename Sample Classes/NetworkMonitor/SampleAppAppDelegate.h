//
//  SampleAppAppDelegate.h
//  SampleApp
//
//  Created by Fredrik Olsson on 2011-02-14.
//  Copyright 2011 Jayway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SampleAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UILabel* label;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UILabel *label;

@end

