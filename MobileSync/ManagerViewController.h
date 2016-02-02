//
//  ManagerViewController.h
//  MobileSync
//
//  Created by john goodstadt on 18/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FMDatabase;
@interface ManagerViewController : UIViewController

@property (strong, nonatomic) FMDatabase *db;
@property (strong, nonatomic) NSString* employee_guid;

@end
