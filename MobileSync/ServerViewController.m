//
//  ServerViewController.m
//  MobileSync
//
//  Created by john goodstadt on 15/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "ServerViewController.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MobileHelper.h"
#import "ServerHelper.h"

static NSString *const mobileDatabasePath = @"/server.db";

@interface ServerViewController ()
@property (strong, nonatomic) FMDatabase *db;
@property (strong, nonatomic) ServerHelper* serverHelper;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UITableView *domainTableview;

@property (strong, nonatomic) NSArray *employees;
@property (strong, nonatomic) NSArray *domains;
@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.serverHelper = [[ServerHelper alloc] init];
    
   
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshFromDBToView];
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if(tableView == self.tableview){
    
        static NSString *CellIdentifier = @"cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        //customize cell before showing it
        
        NSDictionary* entry = self.employees[indexPath.row];
        
        cell.textLabel.text = entry[@"email_address"];
        
        NSString* domain_guid = entry[@"domain_guid"];
        NSString* manager_guid = entry[@"manager_guid"];

        if(manager_guid.length > 0){
            
            NSDictionary *manager = [self.serverHelper getManager:manager_guid];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"deleted:%@ domain_id:%@...%@",entry[@"deleted"],[domain_guid substringToIndex:9],manager[@"email_address"]];
        }
        else{
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"deleted:%@ domain_id:%@...",entry[@"deleted"],[domain_guid substringToIndex:9]];
            
        }
        
        return cell;
    }
    else
    {
        static NSString *CellIdentifierDomain = @"domaincell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierDomain];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierDomain];
        }
        
        //customize cell before showing it
        
        NSDictionary* entry = self.domains[indexPath.row];
        
        NSString* login_id = entry[@"login_id"];
        
        if(login_id.length == 0){
            cell.textLabel.text = @"No Login";
        }
        else{
            cell.textLabel.text = entry[@"login_id"];
        }
        
        
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"time:%@ guid:%@",entry[@"row_timestamp"],entry[@"domain_guid"]];
       
         NSString* domain_guid = entry[@"domain_guid"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@...",[domain_guid substringToIndex:9]];
        
        return cell;

    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
     if(tableView == self.tableview){
         return self.employees.count ;
     }
     else{
         return self.domains.count;
     }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}
- (IBAction)refreshButtonPressed:(id)sender {
    
   [self refreshFromDBToView];
}
-(void)refreshFromDBToView
{
    self.employees = [self.serverHelper getEmployees];
    
    [self.tableview reloadData];
    
    self.domains = [self.serverHelper getDomains];
    
    [self.domainTableview reloadData];

}
@end
