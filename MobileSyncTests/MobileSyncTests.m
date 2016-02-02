//
//  MobileSyncTests.m
//  MobileSyncTests
//
//  Created by john goodstadt on 07/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDBBaseClass.h"
#include "OpenUDID.h"

#import "MobileHelper.h"
#include "SendToServerWebservice.h"
#import "GetRowsFromServerWebservice.h"
#import "ServerHelper.h"
#import "AccountHandlingWebservice.h"
#import "AppDelegate.h"



@interface MobileSyncTests : FMDBBaseClass <SendToServerWebserviceDelegate,GetRowsFromServerWebserviceDelegate,AccountHandlingWebserviceDelegate>

@property (strong, nonatomic)  FMDatabase *lastDBUsed; //used only to simplyfy 3 devices (DBs) testing - returning from webservices to update correct Devices DB

@end

@implementation MobileSyncTests

- (void)setUp {
    [super setUp];
    
    //Create DB in base class
    
    XCTAssertTrue([self.db1 open], @"Wasn't able to open database");
    
}

- (void)tearDown {
    [super tearDown];
    //delete database in base class
}


- (void)testAddDomainTables {
    
    
    if([self.db1 open]){
     
        
        //Section A - System Tables
        [MobileHelper AddSystemTablesIfNecessary:self.db1]; //TODO: Here or From MobileHelper?
        
        
        [MobileHelper AddPayloadTablesIfNecessary:self.db1]; //User tables
        
        [MobileHelper populatePayloadTables:self.db1];
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], 2,@"Invalid employees count'");
        
        //Section B FUNCTIONS

        //Send All New Rows To Server
        [self sendToServerDirtyRows:self.db1];
        
        //Send for all rows
        [self getLatestFromServer:self.db1];
        
         XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], 2,@"Invalid refreshLatestFromServer()'");
        
        [self AddAnotherEmployee:self.db1]; //3 employees
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], 3,@"Invalid Insert 1 into employees'");
        
        
        //Send 1 New Row To Server
        [self sendToServerDirtyRows:self.db1];
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], 3,@"Invalid Refresh - employees'");

        [self sendToServerDirtyRows:self.db1];  //Nothing to send
        
        //XCTAssertEqual([self.db intForQuery:@"SELECT COUNT(*) FROM employees WHERE sentToServerOK = 1"], 4,@"Invalid Insert 1 into employees'");
        
        [MobileHelper logicallyDeleteEmployee:self.db1  email_address:@"james@jones.com"];
        
        [self sendToServerDirtyRows:self.db1];
        
        [MobileHelper addNewManager:self.db1];
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM managers"], 1,@"Invalid Insert 1 into managers'");
        
        [self assignManagerToEmployee:self.db1]; //1 send per table
        //[self update2Tables];
        
        [self sendToServerDirtyRows:self.db1]; //1 send but 2 tables
        
        
        
        //Logon - transition from one device to ability to login to multiple devices with this login
        
        NSString* domainBefore = [MobileHelper getDomainID:self.db1];
        [self login:self.db1];
        
        NSString* domainAfter = [MobileHelper getDomainID:self.db1];
        
        
        XCTAssertEqual([domainBefore isEqualToString:domainAfter], 1,@"Invalid Login'");
        
        //[self sendToServer:self.db1];
        [self sendToServerDirtyRows:self.db1];
        
        
        ////////////////////////////////////////////////////////////////////////////////
        //Device 2
        ////////////////////////////////////////////////////////////////////////////////
        
        //Section A - System Tables
        [MobileHelper AddSystemTablesIfNecessary:self.db2];
        
        [MobileHelper AddPayloadTablesIfNecessary:self.db2]; //User tables
        
        
         [self sendToServerDirtyRows:self.db2];
        
        
        XCTAssertEqual([self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"], 0,@"Invalid employees count'");

        NSString* domainBefore2 = [MobileHelper getDomainID:self.db2];
        [self login:self.db2];
        
        NSString* domainAfter2 = [MobileHelper getDomainID:self.db2];

         XCTAssertNotEqual([domainBefore2 isEqualToString:domainAfter2], 1,@"Invalid Login Device 2'");
        
        [self getLatestFromServer:self.db2]; //bring device 2 in line with device 1
        
        
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");
        
        [self AddAnotherEmployee:self.db2]; //1 employee
        
        XCTAssertEqual([self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"] , [self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"] +1,@"Invalid employees count between DBs'");

        [self sendToServerDirtyRows:self.db2];
        
        [self getLatestFromServer:self.db1]; //bring device 1 in line with device 2
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");
        
        
        
        [self rename_employee:self.db1];
        
       
        ////////////////////////////////////////////////////////////////////////////////
        //Device 3
        ////////////////////////////////////////////////////////////////////////////////

        //Device 3
        //Section A - System Tables
        [MobileHelper AddSystemTablesIfNecessary:self.db3];
        
        [MobileHelper AddPayloadTablesIfNecessary:self.db3]; //User tables
        
        
        
        XCTAssertEqual([self.db3 intForQuery:@"SELECT COUNT(*) FROM employees"], 0,@"Invalid employees count'");

        [self sendToServerDirtyRows:self.db3];
        
        NSString* domainBefore3 = [MobileHelper getDomainID:self.db3];
        [self login:self.db3];
        NSString* domainAfter3 = [MobileHelper getDomainID:self.db3];
        
        XCTAssertNotEqual([domainBefore3 isEqualToString:domainAfter3], 1,@"Invalid Login Device 3'");

        [self getLatestFromServer:self.db3]; //bring device 3 in line with other devices
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db3 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");
        

        [self refreshAllRowsFromServer:self.db3];//TODO: fail managers table id = 2
    
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db3 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");
        
       
        //Avoid bug - Add and send before refresh
        
        [self AddAnotherEmployee:self.db1]; //1 employee, ID = 5 on db1,
        [self sendToServerDirtyRows:self.db1];
        [self getLatestFromServer:self.db2];
        
        [self AddAnotherEmployee:self.db2]; //1 employee, ID = 5 on db2
        [self sendToServerDirtyRows:self.db2];
       
        [self getLatestFromServer:self.db1];
        
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");

        
        /*
         Test subtle case where device A Adds a row (AUTO INCREMENT) ID is incremented - say to 5 and sent to server
         then device B adds a different row (AUTO INCREMENT) ID is incremented - say to 5 and sent to server - then there is a clash on unique auto id on 2 devices
         */

        [self AddAnotherEmployee:self.db1]; //1 employee7, ID = 7 on db1,
        [self AddAnotherEmployee:self.db2]; //1 employee8 ID = 7 on db2
        

        [self sendToServerDirtyRows:self.db1];
        [self sendToServerDirtyRows:self.db2]; //NOTE: CLASH happends HERE
        
        [self getLatestFromServer:self.db1]; //get 8th row on db1
        
        XCTAssertEqual([self.db1 intForQuery:@"SELECT COUNT(*) FROM employees"], [self.db2 intForQuery:@"SELECT COUNT(*) FROM employees"],@"Invalid employees count between DBs'");
        
        BOOL DBsAreAdenticle = [MobileHelper areDBsIdentical:self.db1 secondDB:self.db2];
        
        XCTAssertTrue(DBsAreAdenticle,@"Databases are not identical");
        

        
        //CASE A - more in db1
        //Try again with 2 v 1 rows
        [self AddAnotherEmployee:self.db1]; //1 employee9, ID = 9 on db1,
        [self AddAnotherEmployee:self.db1]; //1 employee10, ID = 10 on db1,
        
        [self AddAnotherEmployee:self.db2]; //1 employee11 ID = 9 on db2
     
        [self sendToServerDirtyRows:self.db1];
        [self sendToServerDirtyRows:self.db2]; //NOTE: CLASH happends HERE - also get automatically employee 9 and 10 from 1
        
        [self getLatestFromServer:self.db1]; //get 11th row on db1
        
        
        XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db2],@"DB1 and db2 are not identical");
        
        
        //If always tdo GET before add does ths work
        //CASE B - more in db2 - reverse DBs
        //Try again - reversed - with 2 v 3 rows

        [self AddAnotherEmployee:self.db1]; //1 employee12  ID = 12 on db1
        [self AddAnotherEmployee:self.db1]; //1 employee13  ID = 13 on db1
        
        [self AddAnotherEmployee:self.db2]; //1 employee14, ID = 12 on db2,
        [self AddAnotherEmployee:self.db2]; //1 employee15, ID = 13 on db2,
        [self AddAnotherEmployee:self.db2]; //1 employee16  ID = 14 on db2

        [self sendToServerDirtyRows:self.db1];  //send ID 23,24
        [self sendToServerDirtyRows:self.db2];  //NOTE: CLASH happends HERE - also get automatically employees 12,13
        
        [self getLatestFromServer:self.db1]; //update db2s rows to db1
        
        
        XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db2],@"DB1 and db2 are not identical");

        
        [self getLatestFromServer:self.db3]; //bring 3 upto date with others
        
        
        XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db3],@"DB1 and DB3 are not identical");
    
        [self AddAnotherEmployee:self.db3]; //1 employee17  ID = 17 on db3
        [self AddAnotherEmployee:self.db3]; //1 employee18  ID = 18 on db3

        [self AddAnotherEmployee:self.db2]; //1 employee19, ID = 17 on db2,
        
        [self AddAnotherEmployee:self.db1]; //1 employee20, ID = 17 on db1,
        [self AddAnotherEmployee:self.db1]; //1 employee21, ID = 18 on db1,
        [self AddAnotherEmployee:self.db1]; //1 employee22, ID = 19 on db1,

        [self sendToServerDirtyRows:self.db3];  //send ID 17,18
        [self sendToServerDirtyRows:self.db2];  //CLASH send emp 19
        [self sendToServerDirtyRows:self.db1];  //CLASH send ID 17,18,19
    
        [self getLatestFromServer:self.db2]; //get 20,21,22
        [self getLatestFromServer:self.db3]; //get 19,20,21,22
        
        
         XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db2],@"DB1 and db2 are not identical");
         XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db3],@"DB1 and DB3 are not identical");
                
        [MobileHelper addNewManager:self.db1];
        [MobileHelper addNewManager:self.db2];
        [MobileHelper addNewManager:self.db3];
        
        [self sendToServerDirtyRows:self.db1];
        [self sendToServerDirtyRows:self.db2]; //Clash on Managers
        [self sendToServerDirtyRows:self.db3];  //Clash on Managers
        
        [self getLatestFromServer:self.db1]; //get latest managers
        [self getLatestFromServer:self.db2]; //get latest managers
        [self getLatestFromServer:self.db3]; //get latest managers

        
        XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db2],@"DB1 and DB2 are not identical");
        XCTAssertTrue([MobileHelper areDBsIdentical:self.db1 secondDB:self.db3],@"DB1 and DB3 are not identical");
        
    }
}
- (void)AddSystemTablesIfNecessary:(FMDatabase*)db {
    //Section A Setup Local DB
    
    XCTAssertFalse([db tableExists:@"domain"]);
    
    if(![db tableExists:@"domain"]){
        
        
        [db executeUpdate:@"create table domain (id integer not null primary key autoincrement, row_guid text not null, row_timestamp text not null,domain_guid text not null,device_guid text not null,login_id text default '',deleted integer default 0,sentToServerOK integer default 0)"];
        
        XCTAssertTrue([db tableExists:@"domain"]);
        
        NSString* udid = [OpenUDID value]; //Unique to this device - same on each call
       
        
        
        
        udid  = [NSString stringWithFormat:@"%@_%@",udid,[[[db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
        
        NSString* GUID = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant
        
        XCTAssertNotNil(udid);
        
       
         NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        
        [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO domain(row_guid,row_timestamp,domain_guid,device_guid) VALUES('%@','%@','%@','%@')",GUID,time_stamp,GUID,udid]];
        
        XCTAssertTrue([db tableExists:@"domain"]);
        
        int count = [db intForQuery:@"SELECT COUNT(*) FROM domain"];
        
        XCTAssertEqual(count, 1,@"Invalid Insert into 'domain'");

        
    }
    
   }


- (void)AddAnotherEmployee:(FMDatabase*)db {
    
    
    if([db open]){
        
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        int employee_number = mainDelegate.employeeCounter;
        
        [MobileHelper INSERTEmployee:db first_name:@"employee" last_name:[NSString stringWithFormat:@"%i",employee_number] manager_id:@"" ];
        mainDelegate.employeeCounter +=1;
        
    }
    
}
-(void)sendToServerDirtyRows:(FMDatabase*)db{
    
    self.lastDBUsed = db; //just used for tests
    
    
    NSString* domain = [MobileHelper getDomainID:db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* device_guid = [OpenUDID value]; //Unique to this device - same on each call
    device_guid  = [NSString stringWithFormat:@"%@_%@",device_guid,[[[db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID


    
    
    NSArray* dirtyEmployeeRows = [MobileHelper getDirtyEmployeesFromDB:db];
    NSArray* dirtyManagerRows = [MobileHelper getDirtyManagersFromDB:db];
    NSArray* dirtyDomainRows = [MobileHelper getDirtyDomainFromDB:db];
    
    NSDictionary* employee_table = @{@"table_name":@"employees",@"auto_increment_col":@"id",@"rows":dirtyEmployeeRows};
    NSDictionary* manager_table = @{@"table_name":@"managers",@"auto_increment_col":@"id",@"rows":dirtyManagerRows};
    NSDictionary* domain_table = @{@"table_name":@"domain",@"auto_increment_col":@"id",@"rows":dirtyDomainRows};
    
    NSArray* tables = @[employee_table,manager_table,domain_table];
    
    if(tables.count > 0){
        
        SendToServerWebservice* ws = [[SendToServerWebservice alloc] init];
        ws.delegate = self;
        
        [ws call:domain client_timestamp:client_timestamp device_guid:device_guid   tables:tables];
    }

    
}
- (NSArray*)getDirtyEmployeesFromDBMoved
{
    int count = [self.db1 intForQuery:@"SELECT COUNT(*) FROM employees WHERE sentToServerOK = 0"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT row_guid,row_timestamp,email_address,first_name,last_name,manager_guid,deleted FROM employees WHERE sentToServerOK = 0"];
    FMResultSet *rs = [self.db1 executeQuery:sql];
    
    while ([rs next])
    {
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
        int deleted = [rs intForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table_name"] = @"employees";
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        row[@"manager_guid"] = manager_guid;
        row[@"deleted"] = [NSString stringWithFormat:@"%i",deleted];
        
        [rows addObject:row];
        
        
    }
    
    return  [rows copy];
}

- (NSArray*)getDirtyManagersFromDBMoved
{
    int count = [self.db1 intForQuery:@"SELECT COUNT(*) FROM managers WHERE sentToServerOK = 0"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT row_guid,row_timestamp,email_address,first_name,last_name,deleted FROM managers WHERE sentToServerOK = 0"];
    FMResultSet *rs = [self.db1 executeQuery:sql];
    
    while ([rs next])
    {
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *deleted = [rs stringForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table_name"] = @"managers";
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        row[@"deleted"] = deleted;
        
        [rows addObject:row];
        
        
    }
    
     return  [rows copy];
}
#pragma mark get from Server Routines
-(void)getLatestFromServer:(FMDatabase*)db{
    
    self.lastDBUsed = db; //just used for tests
    
    GetRowsFromServerWebservice* ws = [[GetRowsFromServerWebservice alloc] init];
    ws.delegate = self;
    
    NSString* domain = [MobileHelper getDomainID:db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    
    NSString* time_stamp_employee = [MobileHelper getLastEmployee_time:db];
    NSString* time_stamp_manager= [MobileHelper getLastManager_time:db];
    
    
    NSDictionary* d = @{@"table_name":@"employees",@"timestamp":time_stamp_employee};
    NSDictionary* d2 = @{@"table_name":@"managers",@"timestamp":time_stamp_manager};
    
    NSArray* time_stamps = [NSArray arrayWithObjects:d,d2,nil];

    
    
    [ws refresh:domain client_timestamp:client_timestamp tableTimeStamps:time_stamps];
    
}
-(void)refreshAllRowsFromServer:(FMDatabase*)db{
    
    self.lastDBUsed = db; //just used for tests
    
    GetRowsFromServerWebservice* ws = [[GetRowsFromServerWebservice alloc] init];
    ws.delegate = self;
    
    NSString* domain = [MobileHelper getDomainID:db];
    NSString* client_timestamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    
    NSString* time_stamp_employee = @"1970-01-01 00:00:00.000";
    NSString* time_stamp_manager=  @"1970-01-01 00:00:00.000";
    
    
    NSDictionary* d = @{@"table_name":@"employees",@"timestamp":time_stamp_employee};
    NSDictionary* d2 = @{@"table_name":@"managers",@"timestamp":time_stamp_manager};
    
    NSArray* time_stamps = [NSArray arrayWithObjects:d,d2,nil];
    
    
    
    [ws refresh:domain client_timestamp:client_timestamp tableTimeStamps:time_stamps];
    
}
-(void)deleteEmployees:(FMDatabase*)db{
   
    [db executeUpdate:@"DELETE FROM employees"];
    
}
#pragma mark webservice delegates

-(void)SendToServerWebserviceResponse:(NSArray *)tables withResponse:(NSDictionary *)response
{
    
    NSString* error = response[@"error"];
    
    
    if(!error)
    {
        //[MobileHelper updateSentToServerOKDB:self.lastDBUsed rows:rows]; //TODO: rows is the old data format
        [MobileHelper updateSentToServerOKDB:self.lastDBUsed tables:tables]; //TODO: rows is the old data format
    }
    else{
        
        
        //NSArray*  clashed_rows = response[@"clashed_rows"];
        //NSArray*  new_rows = response[@"new_rows"];
        NSArray*  clashed_tables = response[@"clashed_tables"];
        NSArray*  new_tables = response[@"new_tables"];
        //Notice that the ID is the same in both sets
        
        
        //        BOOL ok = [MobileHelper UpdateAndReinsertRows:self.lastDBUsed  clashed_rows:clashed_rows new_rows:new_rows];
        BOOL ok = [MobileHelper UpdateAndReinsertRows:self.lastDBUsed  clashed_rows:clashed_tables new_rows:new_tables];
        
        if(ok){
            [self sendToServerDirtyRows:self.lastDBUsed]; //send the 1 row not yet updated
            
        }
        else{
            //Message not sucessfull - nothing sent to server
            NSLog(@"ERROR TRING TO RESOLVE CLASH");
        }
        
        
        
    }
    
    
    
    
}

-(void)SendToServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response{
    
}
-(void)GetRowsFromServerWebserviceResponse:(NSDictionary*)package
{
    
    
    NSArray*tables = package[@"tables"];
    
    for (NSDictionary* table in tables) {
        
        NSString* table_name = table[@"table_name"];
        NSArray*  rows = table[@"rows"];

        for (NSDictionary* row in rows) {
            
            if([table_name isEqualToString:@"employees"])
            {
                [MobileHelper UpdateOrInsertEmployeeByRow_id:self.lastDBUsed sentTOServerOK:1 row:row]; //dirtyFlag should be 1
                
            }
            else  if([table_name isEqualToString:@"managers"])
            {
                [MobileHelper UpdateOrInsertManagerByRow_id:self.lastDBUsed sentTOServerOK:1 row:row]; //dirtyFlag should be 1
                
            }
        }
        
        
        
        
        
    }
    
    //TODO: TRY OUT
#warning deprecated
    //[self updateLastRefreshTimeStamp:self.lastDBUsed];

    
}
-(void)GetRowsFromServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response
{
    
}

-(void)getServerTimeWebserviceResponse:(NSString *)server_time
{
    
    //[MobileHelper updateServerTimeStamp:self.lastDBUsed time_stamp:server_time];
    
    
}
-(void)getServerTimeWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response{
    
}

#pragma mark Helper Routines

-(void)rename_employee:(FMDatabase*)db
{
        FMResultSet *rs = [self.db1 executeQuery:@"SELECT first_name,last_name,email_address,row_guid FROM employees WHERE last_name = '1' order by first_name,last_name asc LIMIT 1 "]; // should be only 1 domain row
    
    if ([rs next])
    {
        NSString* first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString* last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString* email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString* row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        
        last_name = @"A";
        email_address = [NSString stringWithFormat:@"%@_%@@company.com",first_name,last_name];
        
        
        
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE employees SET last_name = '%@',email_address = '%@',row_timestamp = '%@' , sentToServerOK = 0 WHERE row_guid = '%@'",last_name,email_address,time_stamp,row_guid]];
        
    }
    
    
    
    
    
    
}

- (void)assignManagerToEmployee:(FMDatabase*)db
{
    NSString* manager_guid = @"";
    
    FMResultSet *rs = [db executeQuery:@"SELECT row_guid FROM managers LIMIT 1"]; // should be only 1 manager match
    
    if ([rs next])
    {
        manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        
    }
    
    
    if(manager_guid && manager_guid.length > 0) {
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE employees SET manager_guid = '%@',row_timestamp = '%@' , sentToServerOK = 0",manager_guid,time_stamp]];
        
    }
    
    
}


-(void)login:(FMDatabase*)db  {

    self.lastDBUsed = db;
    
    
   // NSString* login_email_address = USER_LOGIN_ID;
    
   
    //Assume all security checking done here (password etc)
    AccountHandlingWebservice* ws = [[AccountHandlingWebservice alloc] init];
    ws.delegate = self;
    
    NSString* domain_guid = [MobileHelper getDomainID:db];
    NSString* device_guid = [OpenUDID value]; //Unique to this device - same on each call
    device_guid  = [NSString stringWithFormat:@"%@_%@",device_guid,[[[db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
    
    
    [ws CallLogin:domain_guid device_guid:device_guid login_id:USER_LOGIN_ID];

    
    
}
-(void)AccountHandlingWebserviceResponse:(NSString*)server_time domain_id:(NSString*)remote_domain_guid_id{
    
    
    //A if domain id is the same as sent up then logged in to existing account or first login for this domain
    //B if the domain id is different then 'logged' in to already existing account - change local DB to reflect login
    
    
    NSString* local_domain_guid = [MobileHelper getDomainID:self.lastDBUsed];
    
    //A.
    if([local_domain_guid isEqualToString:remote_domain_guid_id])
    {
        //already logged in or transition from logged out to logged in
        [MobileHelper updateLogin:self.lastDBUsed login_id:USER_LOGIN_ID];
    }
    else //B.
    {
        //new login - to anothers domain
        [MobileHelper updateLogin:self.lastDBUsed login_id:USER_LOGIN_ID domain_guid:remote_domain_guid_id];
        
        [MobileHelper RemoveAllData:self.lastDBUsed];
        

        

        
    }
    
}
-(void)AccountHandlingWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response{
    
}

@end
