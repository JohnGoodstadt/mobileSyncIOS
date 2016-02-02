//
//  ManagerViewController.m
//  MobileSync
//
//  Created by john goodstadt on 18/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "ManagerViewController.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MobileHelper.h"

#import "AppDelegate.h"
#import "MobileHelper.h"

@interface ManagerViewController ()



@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (strong, nonatomic) NSArray *managers;

@end

@implementation ManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.managers = [MobileHelper  getManagers:self.db];
    
    //self.deviceIDLabel.text = [MobileHelper getDomainID:self.db];
    
    
    [self.tableview reloadData];
}
- (IBAction)backButtonPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma marj table view delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary* entry = self.managers[indexPath.row];
    
    cell.textLabel.text = entry[@"email_address"];
    //cell.detailTextLabel.text = @"";
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.managers.count ;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary* entry = self.managers[indexPath.row];
    NSString* row_guid = entry[@"row_guid"];
    [MobileHelper assignManagerToEmployee:self.db employee_row_guid:self.employee_guid manager_row_guid:row_guid];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSDictionary* entry = self.managers[indexPath.row];
        
        NSMutableArray* tempArray = [self.managers mutableCopy];
        [tempArray removeObject:entry];
        self.managers = tempArray;
        
       
        
        [MobileHelper logicallyDeleteManager:self.db  row_guid:entry[@"row_guid"]];
        
        [tableView reloadData];
        
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        
        
    }
    
    
    
}

- (IBAction)editButtonPressed:(id)sender {
    if(self.tableview.editing)
        self.tableview.editing = NO;
    else
        self.tableview.editing = YES;

}
- (IBAction)addButtonPressed:(id)sender {
   
//    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    
//    int manager_number = mainDelegate.managerCounter+1;
    
    
//    [MobileHelper INSERTManager:self.db first_name:@"manager" last_name:[NSString stringWithFormat:@"%i",manager_number] ];
//    mainDelegate.managerCounter = manager_number;
   
    [MobileHelper addNewManager:self.db];
    
    self.managers = [MobileHelper  getManagers:self.db];
    
    [self.tableview reloadData];
}

@end
