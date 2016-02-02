//
//  FirstViewController.m
//  MobileSync
//
//  Created by john goodstadt on 07/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "FirstViewController.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MobileHelper.h"
#import "SendToServerWebservice.h"
#import "GetRowsFromServerWebservice.h"

#import "AppDelegate.h"
#import "AccountHandlingWebservice.h"

#import "EditEmployeeViewController.h"
#include "OpenUDID.h"

static NSString *const mobileDatabasePath = @"/mobile1.db";

@interface FirstViewController () <SendToServerWebserviceDelegate,GetRowsFromServerWebserviceDelegate,AccountHandlingWebserviceDelegate>

@property (strong, nonatomic) FMDatabase *db;

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UILabel *deviceIDLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginButton;

@property (strong, nonatomic) NSArray *employees;


@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.db = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobileDatabasePath]];
    
    [self.db open];

    
    [MobileHelper AddSystemTablesIfNecessary:self.db];
    
    [MobileHelper AddPayloadTablesIfNecessary:self.db];
    
    [MobileHelper populatePayloadTables:self.db];
    

   
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.employees = [MobileHelper  getEmployees:self.db];
    
    self.deviceIDLabel.text = [MobileHelper getDomainID:self.db];
    
    
    [self.tableview reloadData];
    
    if([self AmILoggedIn]){
        self.loginButton.title = @"Logout";
    }
    else{
        self.loginButton.title = @"Login";
    }
}
#pragma marj table view delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    //customize cell before showing it
    
   NSDictionary* entry = self.employees[indexPath.row];
    
    
    cell.textLabel.text = entry[@"email_address"];
   
    
    NSString* manager_guid = entry[@"manager_guid"];
    if(manager_guid.length > 0){
        NSString* manager_email_address = [MobileHelper manager_email_address:self.db manager_guid:manager_guid];
        cell.detailTextLabel.text = manager_email_address;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.employees.count ;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSDictionary* entry = self.employees[indexPath.row];
        
        
        NSMutableArray* tempArray = [self.employees mutableCopy];
        [tempArray removeObject:entry];
        self.employees = tempArray;
        
        [MobileHelper logicallyDeleteEmployee:self.db  email_address:entry[@"email_address"]];
        
        [tableView reloadData];
            
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        
        
    }
    
    
    
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(1==0){
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditEmployeeViewController *vc = [sb instantiateViewControllerWithIdentifier:@"EditEmployeeID"];
    vc.db = self.db;
    
    NSDictionary* entry = self.employees[indexPath.row];
    NSString* row_guid = entry[@"row_guid"];
    vc.employee_guid = row_guid;
    
    [self presentViewController:vc animated:YES completion:NULL];
    
}
#pragma mark Button Events
- (IBAction)addButtonPressed:(id)sender {
    
    
     AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    int employee_number = mainDelegate.employeeCounter;
    
    
    [MobileHelper INSERTEmployee:self.db first_name:@"employee" last_name:[NSString stringWithFormat:@"%i",employee_number] manager_id:@"" ];
    mainDelegate.employeeCounter +=1;
    
    self.employees = [MobileHelper  getEmployees:self.db];
    
    [self.tableview reloadData];
   
    
}
- (IBAction)editButtonPressed:(id)sender {
   
    
    if(self.tableview.editing)
        self.tableview.editing = NO;
    else
        self.tableview.editing = YES;
    
}
- (IBAction)refreshButtonPressed:(id)sender {
    
    [self refreshFromServer];
    
    // [self.tableview reloadData];
}
- (IBAction)sendButtonPressed:(id)sender {
    
    [self sendToServerDirtyRows];
    
}
- (IBAction)loginButtonPressed:(id)sender {
    
    if([self AmILoggedIn])
    {
        [self logoutOfServer];
    }
    else
    {
        [self loginToServer];
    }

}
-(void)loginToServer
{
    
    AccountHandlingWebservice* ws = [[AccountHandlingWebservice alloc] init];
    ws.delegate = self;
    
    NSString* domain_guid = [MobileHelper getDomainID:self.db];
    NSString* device_guid = [OpenUDID value]; //Unique to this device - same on each call
    device_guid  = [NSString stringWithFormat:@"%@_%@",device_guid,[[[self.db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
    
    
    [ws CallLogin:domain_guid device_guid:device_guid login_id:USER_LOGIN_ID];
    
    
}
-(void)logoutOfServer
{
    
    NSString* domain_guid = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant;
    
    [MobileHelper updateLogin:self.db login_id:@"" domain_guid:domain_guid];
    
    [MobileHelper RemoveAllData:self.db];
    
    
    self.employees = [MobileHelper getEmployees:self.db];
    [self.tableview reloadData];
    
    self.deviceIDLabel.text = [MobileHelper getDomainID:self.db];
    self.loginButton.title = @"Login";
    
    
}
#pragma mark Webservice Calls
-(void)sendToServerDirtyRows
{
    
    
    NSString* domain_guid = [MobileHelper getDomainID:self.db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* device_guid = [OpenUDID value]; //Unique to this device - same on each call
    device_guid  = [NSString stringWithFormat:@"%@_%@",device_guid,[[[self.db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
 
    
    SendToServerWebservice* ws = [[SendToServerWebservice alloc] init];
    ws.delegate = self;
    
    NSArray* employeeRows = [MobileHelper getDirtyEmployeesFromDB:self.db];
    NSArray* managerRows = [MobileHelper getDirtyManagersFromDB:self.db];
    NSArray* domainRow = [MobileHelper getDirtyDomainFromDB:self.db];

    
    NSDictionary* employee_table = @{@"table_name":@"employees",@"auto_increment_col":@"id",@"rows":employeeRows};
    NSDictionary* manager_table = @{@"table_name":@"managers",@"auto_increment_col":@"id",@"rows":managerRows};
    NSDictionary* domain_table = @{@"table_name":@"domain",@"auto_increment_col":@"id",@"rows":domainRow};
    
    NSArray* tables = @[employee_table,manager_table,domain_table];
    
    if(tables.count > 0){//Do we have anything to send?
        
        SendToServerWebservice* ws = [[SendToServerWebservice alloc] init];
        ws.delegate = self;
        
        [ws call:domain_guid client_timestamp:client_timestamp device_guid:device_guid   tables:tables];
    }
    
    
}
-(void)sendToServerDirtyRowsGoogleDocs
{
    
    
    NSString* domain_guid = [MobileHelper getDomainID:self.db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* device_guid = [OpenUDID value]; //Unique to this device - same on each call
    device_guid  = [NSString stringWithFormat:@"%@_%@",device_guid,[[[self.db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
   
    
    SendToServerWebservice* ws = [[SendToServerWebservice alloc] init];
    ws.delegate = self;
    
    NSArray* employeeRows = [MobileHelper getDirtyEmployeesFromDB:self.db];
    NSArray* managerRows = [MobileHelper getDirtyManagersFromDB:self.db];
    NSArray* domainRow = [MobileHelper getDirtyDomainFromDB:self.db];
    
    
    NSDictionary* employee_table = @{@"table_name":@"employees",@"auto_increment_col":@"id",@"rows":employeeRows};
    NSDictionary* manager_table = @{@"table_name":@"managers",@"auto_increment_col":@"id",@"rows":managerRows};
    NSDictionary* domain_table = @{@"table_name":@"domain",@"auto_increment_col":@"id",@"rows":domainRow};
    
    NSArray* tables = @[employee_table,manager_table,domain_table]; //combine all tables
    
    if(tables.count > 0){//Do we have anything to send?
        
        SendToServerWebservice* ws = [[SendToServerWebservice alloc] init];
        ws.delegate = self;
        
        [ws call:domain_guid client_timestamp:client_timestamp device_guid:device_guid   tables:tables];
    }
    
    
}
-(void)refreshFromServer{
    
    GetRowsFromServerWebservice* ws = [[GetRowsFromServerWebservice alloc] init];
    ws.delegate = self;
    
    NSString* domain_guid = [MobileHelper getDomainID:self.db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    
    NSString* time_stamp_employee = [MobileHelper getLastEmployee_time:self.db];
    NSString* time_stamp_manager= [MobileHelper getLastManager_time:self.db];
    
    
    NSDictionary* d = @{@"table_name":@"employees",@"timestamp":time_stamp_employee};
    NSDictionary* d2 = @{@"table_name":@"managers",@"timestamp":time_stamp_manager};
    
    NSArray* time_stamps = [NSArray arrayWithObjects:d,d2,nil];
    
    [ws refresh:domain_guid client_timestamp:client_timestamp tableTimeStamps:time_stamps];
    
    
}
-(BOOL)AmILoggedIn{
    
   return [MobileHelper isUserLoggedIn:self.db];
    
}
#pragma mark webservice delegates
-(void)SendToServerWebserviceResponse:(NSArray *)tables withResponse:(NSDictionary *)response
{
    
    NSString* error = response[@"error"];
    
    
    if(!error)
    {
        [MobileHelper updateSentToServerOKDB:self.db tables:tables]; //TODO: rows is the old data format
    }
    else{
        
        

        NSArray*  clashed_tables = response[@"clashed_tables"];
        NSArray*  new_tables = response[@"new_tables"];
        
        BOOL ok = [MobileHelper UpdateAndReinsertRows:self.db  clashed_rows:clashed_tables new_rows:new_tables];
        
        if(ok){
            [self sendToServerDirtyRows]; //send the 1 row not yet updated
        }
        else{
            //Message not sucessfull - nothing sent to server
            NSLog(@"ERROR TRYING TO RESOLVE CLASH");
        }
        
        
        
    }
    
    
    
    
}
-(void)SendToServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response{
    
}
-(void)GetRowsFromServerWebserviceResponse:(NSDictionary*)package
{
   
    NSArray*  rows = package[@"rows"];
    
    for (NSDictionary* row in rows) {
        
        NSString* table_name = row[@"table"];
        
        if([table_name isEqualToString:@"employees"])
        {
            
            
            NSString* row_guid = row[@"row_guid"];
            NSString* row_timestamp = row[@"row_timestamp"];
            NSString* email_address = row[@"email_address"];
            NSString* first_name = row[@"first_name"];
            NSString* last_name = row[@"last_name"];
            
            //sentToServer set to ON as we have refreshed from server
            NSString* sql = [NSString stringWithFormat:@"REPLACE INTO employees(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name) VALUES('%@','%@',1,'%@','%@','%@')",row_guid,row_timestamp,email_address,first_name,last_name];
            
            [self.db executeUpdate:sql];
            
        }else  if([table_name isEqualToString:@"managers"])
        {
            NSString* row_guid = row[@"row_guid"];
            NSString* row_timestamp = row[@"row_timestamp"];
            NSString* email_address = row[@"email_address"];
            NSString* first_name = row[@"first_name"];
            NSString* last_name = row[@"last_name"];
            
            //sentToServer set to ON as we have refreshed from server
            NSString* sql = [NSString stringWithFormat:@"REPLACE INTO managers(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name) VALUES('%@','%@',1,'%@','%@','%@')",row_guid,row_timestamp,email_address,first_name,last_name];
            
            [self.db executeUpdate:sql];
        }
        
        
    }
    
    
    
    
    
    self.employees = [MobileHelper  getEmployees:self.db];
    
    self.deviceIDLabel.text = [MobileHelper getDomainID:self.db];
    
    [self.tableview reloadData];
    
}
-(void)GetRowsFromServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response
{
    
}
-(void)AccountHandlingWebserviceResponse:(NSString*)server_time domain_id:(NSString*)domain_id{
    
    
    //A if domain id is the same as sent up then logged in to existing account or first login for this domain
    //B if the domain id is different then 'logged' in to already existing account - change local DB to reflect login
    
    
    
    
    NSString* local_domain_guid = [MobileHelper getDomainID:self.db];
    
    //A.
    if([local_domain_guid isEqualToString:domain_id])
    {
        //already logged in or transition from logged out to logged in
        [MobileHelper updateLogin:self.db login_id:USER_LOGIN_ID];
    }
    else //B.
    {
        //new login - to anothers domain
        [MobileHelper updateLogin:self.db login_id:USER_LOGIN_ID domain_guid:domain_id];
        
        [MobileHelper RemoveAllData:self.db];
        
        [self refreshFromServer];
        
        self.loginButton.title = @"Logout";
        
        self.employees = [MobileHelper  getEmployees:self.db];
        
        self.deviceIDLabel.text = [MobileHelper getDomainID:self.db];
        
        [self.tableview reloadData];

    }
    
}
-(void)AccountHandlingWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response{
    
}

@end
