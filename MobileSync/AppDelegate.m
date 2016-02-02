//
//  AppDelegate.m
//  MobileSync
//
//  Created by john goodstadt on 07/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "AppDelegate.h"
#import "ServerHelper.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
   
    
    ServerHelper* serverLibrary = [[ServerHelper alloc] init];
   
    //assumes devices have sent latest rows to server for this to work
    self.employeeCounter = [serverLibrary getHighestEmployeeNumber] + 1;
   
    self.managerCounter = [serverLibrary getHighestManagerNumber] ;
    
    [serverLibrary createDBIfNecessary];
    
    
    return YES;
}

@end
