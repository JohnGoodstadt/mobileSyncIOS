//
//  ViewController.h
//  MobileSync
//
//  Created by john on 17/01/2016.
//  Copyright © 2016 John Goodstadt. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FMDatabase;

@interface EditEmployeeViewController : UIViewController

@property (strong, nonatomic) FMDatabase *db;
@property (strong, nonatomic) NSString* employee_guid;

@end
