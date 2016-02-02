//
//  ViewController.m
//  MobileSync
//
//  Created by john on 17/01/2016.
//  Copyright © 2016 John Goodstadt. All rights reserved.
//

#import "EditEmployeeViewController.h"



#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MobileHelper.h"
#import "ManagerViewController.h"

@interface EditEmployeeViewController ()

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic)  NSString *row_guid;

@property (weak, nonatomic) IBOutlet UITextField *managerTextField;

@end

@implementation EditEmployeeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.managerTextField.enabled = NO;
    
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSMutableDictionary* d =  [MobileHelper  getEmployee:self.db row_guid:self.employee_guid];
    
    self.firstNameTextField.text = d[@"first_name"];
    self.lastNameTextField.text = d[@"last_name"];
    self.emailTextField.text = d[@"email_address"];
    
    
    
    self.row_guid = d[@"row_guid"];
    
    NSString* manager_guid = d[@"manager_guid"];
    
    if(manager_guid!= nil && manager_guid.length > 0)
    {
        NSDictionary* entry = [MobileHelper getManager:self.db row_guid:manager_guid];
        
        self.managerTextField.text = entry[@"email_address"];
    }


}
- (IBAction)backButtonPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)saveButtonPressed:(id)sender {
    
    [MobileHelper  saveEmployee:self.db row_guid:self.row_guid  firstName:self.firstNameTextField.text last_name:self.lastNameTextField.text email_address:self.emailTextField.text];
    
}
- (IBAction)managerButtonPressed:(id)sender  {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ManagerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"fred"];
    vc.db = self.db;
    
    vc.employee_guid = self.row_guid;    
    
    [self presentViewController:vc animated:YES completion:NULL];
    
}
@end
