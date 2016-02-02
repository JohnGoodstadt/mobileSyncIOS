//
//  MobileHelper.m
//  MobileSync
//
//  Created by john goodstadt on 09/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "MobileHelper.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#include "OpenUDID.h"
#include "AppDelegate.h"


#define USE_TIME_ZONE_OFFSET NO // high level flag to switch on/off time zone testing for Unit Tests
#define TIME_ZONE_OFFSET -18000 //seconds e.g. 3600 is device 1 hour ahead of server ; -18000 = 5 hours behind


@implementation MobileHelper
/*
 NOTE: all routines are Static functions (Class methods)
 */
+ (NSString*)stringFromDate:(NSDate*)Date andFormat:(NSString*)format
{
    
    
    //If necessary use TIME_ZONE_OFFSET to siumulate mobiles on different time zones
    if(USE_TIME_ZONE_OFFSET){
       Date = [Date dateByAddingTimeInterval:TIME_ZONE_OFFSET];
    }
    
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc]init];
    [outputDateFormatter setDateFormat:format];
    
    return [outputDateFormatter stringFromDate:Date];
    
}
+ (NSString*)stringFromStringDate:(NSDate*)Date andFormat:(NSString*)format
{
    
    
    //If necessary use TIME_ZONE_OFFSET to siumulate mobiles on different time zones
    if(USE_TIME_ZONE_OFFSET){
        Date = [Date dateByAddingTimeInterval:TIME_ZONE_OFFSET];
    }
    
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc]init];
    [outputDateFormatter setDateFormat:format];
    
    return [outputDateFormatter stringFromDate:Date];
    
}
+ (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
+(NSDictionary*)convertJSONToDictionary:(NSString*)json{
    
    NSError *error;
    NSData *objectData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:objectData
                                                            options:0
                                                              error:&error];

    return package;
}
+(BOOL)fileExistsInDocuments:(NSString*)filename
{
    BOOL returnValue = NO;
    
    NSString *fullPath = [[MobileHelper applicationDocumentsDirectory]   stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
        returnValue = YES;
    
    
    return returnValue;
}
+ (void)AddSystemTablesIfNecessary:(FMDatabase*)db
{
    //Section A Setup Local DB
    
    if(![db tableExists:@"domain"]){
        
        
        [db executeUpdate:@"create table domain (id integer not null primary key autoincrement,row_guid text not null, row_timestamp text not null,domain_guid text not null,device_guid text not null,login_id text default '',deleted integer default 0,sentToServerOK integer default 0)"];
        
        
        NSString* udid = [OpenUDID value]; //Unique to this device - same on each call
        udid  = [NSString stringWithFormat:@"%@_%@",udid,[[[db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
        
        
        
//        NSString* GUID = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant
        NSString* GUID = [NSString stringWithFormat:@"%@_%@",[[NSProcessInfo processInfo] globallyUniqueString],[[[db databasePath] lastPathComponent] stringByDeletingPathExtension]]; //NOTE: special adjustment for these Unit Tests only - each device should have unique UDID
        
       
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        

        
        //int seconds = [self adjustTimeZoneIfNecessary];
        
        
        
        [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO domain(row_guid,row_timestamp,domain_guid,device_guid) VALUES('%@','%@','%@','%@')",GUID,time_stamp,GUID,udid]];
        
       
        
    }
    
}
+ (void)AddPayloadTablesIfNecessary:(FMDatabase*)db {
    
    
  
    if(![db tableExists:@"employees"]){
        
        [db executeUpdate:@"create table employees (id integer not null primary key autoincrement, row_guid text not null, row_timestamp text not null,sentToServerOK integer default 0,email_address text default '',first_name text default '',last_name text default '',manager_guid text default '',deleted integer default 0)"];
        
        [db executeUpdate:@"CREATE UNIQUE INDEX employees_row_guid on employees (row_guid)"];
        

        
        
        
    }
    
    if(![db tableExists:@"managers"]){
        
        [db executeUpdate:@"create table managers (id integer not null primary key autoincrement,row_guid text not null, row_timestamp text not null,sentToServerOK integer default 0,email_address text default '',first_name text default '',last_name text default '',deleted integer default 0)"];
        
        [db executeUpdate:@"CREATE UNIQUE INDEX managers_row_guid on managers (row_guid)"];
        
        
    }
    
    
        
        
        
    
}
+ (void)populatePayloadTables:(FMDatabase*)db {
    
    
    
    if([db tableExists:@"employees"]){
        
        int count = [db intForQuery:@"SELECT COUNT(*) FROM employees"];
        
        if(count == 0){
           
            
            NSString* nowDate = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
            
            //Not needed on real device
           // NSDate* dt = [MobileHelper DateFromDB:nowDate];
           //SString* ts = [MobileHelper stringFromDate:nowDate andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
            
            
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,email_address,first_name,last_name) VALUES('%@','%@','employee_1@company.com','employee','1')",[[NSProcessInfo processInfo] globallyUniqueString],nowDate]];
            
            
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,email_address,first_name,last_name) VALUES('%@','%@','employee_2@company.com','employee','2')",[[NSProcessInfo processInfo] globallyUniqueString],nowDate]];
            
            
            AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            
            mainDelegate.employeeCounter = 3;
        }
        
        
    }
    
    
    
    
    
}

+(void)logicallyDeleteEmployee:(FMDatabase*)db email_address:(NSString*)email_address{
    
    NSString* row_guid = @"";
    
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT row_guid FROM employees WHERE email_address = '%@' LIMIT 1",email_address]]; // should be only 1 match
    
    if ([rs next])
    {
        row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        
    }
    
    
    if(row_guid && row_guid.length > 0) {
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE employees SET deleted = 1 ,row_timestamp = '%@', sentToServerOK = 0 WHERE row_guid = '%@'",time_stamp,row_guid]];
        
    }
    
    
}
+(void)logicallyDeleteManager:(FMDatabase*)db row_guid:(NSString*)row_guid{
    
    
    if(row_guid && row_guid.length > 0) {
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE managers SET deleted = 1 ,row_timestamp = '%@', sentToServerOK = 0 WHERE row_guid = '%@'",time_stamp,row_guid]];
        
    }
    
    
}
+ (NSArray*)getDirtyEmployeesFromDB:(FMDatabase*)db
{
    int count = [db intForQuery:@"SELECT COUNT(*) FROM employees WHERE sentToServerOK = 0"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid,deleted FROM employees WHERE sentToServerOK = 0"];
    FMResultSet *rs = [db executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
        int deleted = [rs intForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table_name"] = @"employees";
        row[@"auto_increment_col"] = @"id";
        row[@"id"] = ID;
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

+ (NSArray*)getDirtyManagersFromDB:(FMDatabase*)db
{
    int count = [db intForQuery:@"SELECT COUNT(*) FROM managers WHERE sentToServerOK = 0"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,deleted FROM managers WHERE sentToServerOK = 0"];
    FMResultSet *rs = [db executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *deleted = [rs stringForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table_name"] = @"managers";
        row[@"id"] = ID;
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
/**
 * get main user identifier - used over multiple devices - here called domain
 *
 * @param db - pointer to an open FMDatabase connection
 * @return void
 */
+(NSString*)getDomainID:(FMDatabase*)db
{
    //todo; jit create table?
    NSString* returnValue = @"INVALID";
    
    FMResultSet *rs = [db executeQuery:@"SELECT domain_guid FROM domain LIMIT 1"]; // should be only 1 domain row on any 1 device
    
    if ([rs next])
    {
        returnValue = [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]];
        
    }
    
    return returnValue;
    
}
+(void)updateSentToServerOKDB:(FMDatabase*)db rows:(NSArray *)rows
{

    for (NSDictionary* row in rows) {
        
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET sentToServerOK = 1 WHERE row_guid = '%@'",row[@"table_name"],row[@"row_guid"]]];
    }
    
}

+(void)updateSentToServerOKDB:(FMDatabase*)db tables:(NSArray *)tables
{
    
    for (NSDictionary* table in tables) {
        
        
        NSString* table_name = table[@"table_name"];
        for (NSDictionary* row in table[@"rows"])
        {
            [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET sentToServerOK = 1 WHERE row_guid = '%@'",table_name,row[@"row_guid"]]];
            
            
            
            
        }
        
        
        
        
        
    }
    
}

+(NSArray*)getDirtyDomainFromDB:(FMDatabase*)db
{
    int count = [db intForQuery:@"SELECT COUNT(*) FROM domain WHERE sentToServerOK = 0"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,domain_guid,device_guid,deleted,login_id FROM domain WHERE sentToServerOK = 0"];
    FMResultSet *rs = [db executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *domain_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]];
        NSString *device_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"device_guid"]];
        int deleted = [rs intForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        NSString *login_id = [rs stringForColumnIndex:[rs columnIndexForName:@"login_id"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table_name"] = @"domain";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"domain_guid"] = domain_guid;
        row[@"device_guid"] = device_guid;
        
        row[@"login_id"] = login_id;
        
        row[@"deleted"] = [NSString stringWithFormat:@"%i",deleted];
        
        [rows addObject:row];
        
        
    }
    
    return  [rows copy];
}
+(NSArray*)getEmployees:(FMDatabase*)db{
    
    int count = [db intForQuery:@"SELECT COUNT(*) FROM employees"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = @"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid FROM employees WHERE deleted = 0 ORDER BY row_timestamp asc";
    
    
    FMResultSet *rs = [db executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table"] = @"employees";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        row[@"manager_guid"] = manager_guid;
        
        [rows addObject:row];
        
        
    }
    
    return [rows copy];
}
+(NSMutableDictionary*)getEmployee:(FMDatabase*)db row_guid:(NSString*)row_guid
{
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid FROM employees WHERE row_guid = '%@'",row_guid ];
    
    
    FMResultSet *rs = [db executeQuery:sql];
    
    NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
       
        row[@"table"] = @"employees";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        row[@"manager_guid"] = manager_guid;
        
        
        break; // 1 row
    }
    
    return row;
}
+(void)saveEmployee:(FMDatabase*)db row_guid:(NSString*)row_guid   firstName:(NSString*)firstName last_name:(NSString*)last_name email_address:(NSString*)email_address
{
 
    NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *sql = [NSString stringWithFormat:@"UPDATE employees SET row_timestamp='%@',email_address='%@',first_name='%@',last_name='%@',sentToServerOK=0 WHERE row_guid = '%@'",time_stamp,email_address,firstName,last_name, row_guid ];
    
    [db executeUpdate:sql];
   
    
   
}
+(NSArray*)getManagers:(FMDatabase*)db{
    
    int count = [db intForQuery:@"SELECT COUNT(*) FROM managers"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = @"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM managers WHERE deleted = 0 ";
    
    
    FMResultSet *rs = [db executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table"] = @"managers";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        
        [rows addObject:row];
        
        
    }
    
    return [rows copy];
}
+(NSDictionary*)getManager:(FMDatabase*)db row_guid:(NSString*)row_guid
{
    NSDictionary* entry = nil;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM managers WHERE row_guid = '%@' AND deleted = 0 ",row_guid];
    
    FMResultSet *rs = [db executeQuery:sql];
    
    if ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table"] = @"managers";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        
        
        entry = row;
        
    }
    
    return entry;
}

+(NSString*)getServer_timeObsolete:(FMDatabase*)db{
    
    NSString* returnValue = @"INVALID";
    
    FMResultSet *rs = [db executeQuery:@"SELECT server_timestamp FROM domain LIMIT 1"]; // should be only 1 domain row
    
    if ([rs next])
    {
        returnValue = [rs stringForColumnIndex:[rs columnIndexForName:@"server_timestamp"]];
        
    }
    
    
    
    
    return returnValue;
    
}
+(NSString*)getLastEmployee_time:(FMDatabase*)db{
    
    NSString* returnValue = @"1970-01-01 00:00:00.000";
    
    FMResultSet *rs = [db executeQuery:@"SELECT row_timestamp FROM employees ORDER BY row_timestamp DESC LIMIT 1"];
    
    if ([rs next])
    {
        returnValue = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        
#warning WHY DO I NEED THIS ?
        //returnValue = [self calcEarliestTimStamp:db date:returnValue];
        
    }
    
    
    return returnValue;
    
}
+(NSString*)calcEarliestTimStampObsolete:(FMDatabase*)db date:(NSString*)date1_timestamp
{
    
    NSString* returnValue = @"1970-01-01 00:00:00.000";
    
    FMResultSet *rs = [db executeQuery:@"SELECT last_refresh_timestamp FROM domain LIMIT 1"]; // should be only 1 domain row
    
    if ([rs next])
    {
        NSString* last_refresh_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"last_refresh_timestamp"]];
        
        if(last_refresh_timestamp.length > 0)
        {
            NSDate* date1 = [self DateFromDB:date1_timestamp];
            NSDate* date2 = [self DateFromDB:last_refresh_timestamp];
            
            switch ([date1 compare:date2]){
                case NSOrderedAscending:
                    NSLog(@"NSOrderedAscending");
                    returnValue = date1_timestamp;
                    break;
                case NSOrderedSame:
                    NSLog(@"NSOrderedSame");
                    returnValue = date1_timestamp;
                    break;
                case NSOrderedDescending:
                    NSLog(@"NSOrderedDescending");
                    returnValue= [MobileHelper stringFromDate:date2 andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    break;
            }
        }

    }
    else{
        //use early date
    }
   
    
    
    return returnValue;
    
}

+(NSString*)getLastManager_time:(FMDatabase*)db{
    
    NSString* returnValue = @"1970-01-01 00:00:00.000";
    
    FMResultSet *rs = [db executeQuery:@"SELECT row_timestamp FROM managers ORDER BY row_timestamp DESC LIMIT 1"]; // should be only 1 domain row
    
    if ([rs next])
    {
        returnValue = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        
    }
    
    return returnValue;
    
}
+(void)INSERTEmployee:(FMDatabase*)db first_name:(NSString*)first_name last_name:(NSString*)last_name manager_id:(NSString*)manager_id
{
    
    NSString* ts  = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    //Not needed on real device
//    NSDate* dt = [MobileHelper DateFromDB:nowDate];
//    NSString* ts = [MobileHelper stringFromDate:dt andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

     [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,email_address,first_name,last_name,manager_guid) VALUES('%@','%@','%@_%@@company.com','%@','%@','%@')",[[NSProcessInfo processInfo] globallyUniqueString],ts,first_name,last_name,first_name,last_name,manager_id]];

}
+(void)INSERTManager:(FMDatabase*)db first_name:(NSString*)first_name last_name:(NSString*)last_name
{
    
    
    
    [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO managers(row_guid,row_timestamp,email_address,first_name,last_name) VALUES('%@','%@','%@_%@@company.com','%@','%@')",[[NSProcessInfo processInfo] globallyUniqueString],[MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],first_name,last_name,first_name,last_name]];
    
    NSLog(@"Inserted into Manager");
    
}
+(void)updateLogin:(FMDatabase*)db login_id:(NSString*)login_id
{
    
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE domain SET login_id = '%@', sentToServerOk = 0",login_id]];
    
    
}
+(void)updateLogin:(FMDatabase*)db login_id:(NSString*)login_id domain_guid:(NSString*)domain_guid
{
    
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE domain SET login_id = '%@', domain_guid = '%@', sentToServerOk = 0",login_id,domain_guid]]; //transition to other user
    
    
}
//When logging in to another domain clear out old data
+(void)RemoveAllData:(FMDatabase*)db
{
    
    //NOTE: not logical delete
    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM employees"]];

    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM managers"]];
    
}
+(void)ChangeDomains:(FMDatabase*)db withDomain:(NSString*)domain_id
{
    
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE domain SET domain_guid = '%@'",domain_id]];
    
    
}
+(BOOL)isUserLoggedIn:(FMDatabase*)db
{
    int count = [db intForQuery:@"SELECT COUNT(*) FROM domain WHERE login_id = ''"];
    
    return count == 0;
}
+(void)assignManagerToEmployee:(FMDatabase*)db employee_row_guid:(NSString*)employee_row_guid manager_row_guid:(NSString*)manager_row_guid
{
    
   
    if(employee_row_guid && employee_row_guid > 0 && manager_row_guid && manager_row_guid > 0) {
        
        NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE employees SET manager_guid = '%@', row_timestamp = '%@', sentToServerOK = 0 WHERE row_guid = '%@'",manager_row_guid,time_stamp,employee_row_guid]];
        
    }
    
    
}
+(NSString*)manager_email_address:(FMDatabase*)db  manager_guid:(NSString*)manager_guid
{
    
    NSString* returnValue = @"";
    
    NSDictionary* entry = [MobileHelper getManager:db row_guid:manager_guid];
    
    if(entry){
        returnValue = entry[@"email_address"];
    }
    
    return returnValue;
}
+(void)addNewManager:(FMDatabase*)db{
    
    
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    int manager_number = mainDelegate.managerCounter+1;
    
    
    [MobileHelper INSERTManager:db first_name:@"manager" last_name:[NSString stringWithFormat:@"%i",manager_number] ];
    mainDelegate.managerCounter = manager_number;

}
+(NSDate*)DateFromDB:(NSString*)dbdate
{
    
    if(!dbdate)
        return nil;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss.SSS"];
    
    
    
    return [dateFormatter dateFromString: dbdate];
    
}
+ (int)adjustTimeZoneIfNecessary
{
    int seconds=0;
    if(USE_TIME_ZONE_OFFSET){
        seconds = TIME_ZONE_OFFSET; //simulate device being 1 hour ahead of server e.g. CET (device) v GMT (server)  //[dd timeIntervalSinceDate:[NSDate date]];
    }
    return seconds;
}
+ (int)adjustTimeByTimeZoneIfNecessary:(NSDate*)date
{
    int seconds=0;
    if(USE_TIME_ZONE_OFFSET){
        seconds = TIME_ZONE_OFFSET; //simulate device being 1 hour ahead of server e.g. CET (device) v GMT (server)  //[dd timeIntervalSinceDate:[NSDate date]];
    }
    return seconds;
}
+(BOOL)areDBsIdentical:(FMDatabase*)db1 secondDB:(FMDatabase*)db2{
    
    BOOL returnValue = NO;
    
    int count1 = [db1 intForQuery:@"SELECT COUNT(*) FROM employees"];
    int count2 = [db2 intForQuery:@"SELECT COUNT(*) FROM employees"];
    
    
    if(count1 != count2){
        return returnValue;
    }
    
    count1 = [db1 intForQuery:@"SELECT COUNT(*) FROM managers"];
    count2 = [db2 intForQuery:@"SELECT COUNT(*) FROM managers"];
    
    
    if(count1 != count2){
        return returnValue;
    }
    
    
    count1 = [db1 intForQuery:@"SELECT min(id) FROM employees"];
    count2 = [db2 intForQuery:@"SELECT min(id) FROM employees"];
    
    if(count1 != count2){
        return returnValue;
    }

    
    count1 = [db1 intForQuery:@"SELECT max(id) FROM employees"];
    count2 = [db2 intForQuery:@"SELECT max(id) FROM employees"];
    
    if(count1 != count2){
        return returnValue;
    }

    count1 = [db1 intForQuery:@"SELECT sum(sentToServerOK) FROM employees"];
    count2 = [db2 intForQuery:@"SELECT sum(sentToServerOK) FROM employees"];
    
    if(count1 == 0 || count2 == 0 || count1 != count2) // sentToServerOK should be all set to zero
    {
        return returnValue;
    }

    count1 = [db1 intForQuery:@"SELECT min(id) FROM managers"];
    count2 = [db2 intForQuery:@"SELECT min(id) FROM managers"];
    
    if(count1 != count2){
        return returnValue;
    }
    
    
    count1 = [db1 intForQuery:@"SELECT max(id) FROM managers"];
    count2 = [db2 intForQuery:@"SELECT max(id) FROM managers"];
    
    if(count1 != count2){
        return returnValue;
    }
    
    count1 = [db1 intForQuery:@"SELECT sum(sentToServerOK) FROM managers"];
    count2 = [db2 intForQuery:@"SELECT sum(sentToServerOK) FROM managers"];
    
    if(count1 == 0 || count2 == 0 || count1 != count2) // sentToServerOK should be all set to zero
    {
        return returnValue;
    }
    
    NSString* email_address1 = [db1 stringForQuery:@"SELECT email_address FROM employees where id = (select max(id) FROM employees )"];
    NSString* email_address2 = [db2 stringForQuery:@"SELECT email_address FROM employees where id = (select max(id) FROM employees )"];
    
    
    if(![email_address1 isEqualToString:email_address2]){
        return returnValue;
    }

    email_address1 = [db1 stringForQuery:@"SELECT email_address FROM employees where id = (select max(id) FROM managers )"];
    email_address2 = [db2 stringForQuery:@"SELECT email_address FROM employees where id = (select max(id) FROM managers )"];
    
    
    if(![email_address1 isEqualToString:email_address2]){
        return returnValue;
    }

    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid,deleted FROM employees"];
    FMResultSet *rs = [db1 executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        
        
        returnValue = [self isDBRowIdentical:db2 ID:[ID intValue] row_guid:row_guid  email_address:email_address table_name:@"employees"];
        
        
        if(!returnValue)
            return returnValue;
        
        
    }

    sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address FROM managers"];
    rs = [db1 executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        
        
        returnValue = [self isDBRowIdentical:db2 ID:[ID intValue] row_guid:row_guid  email_address:email_address table_name:@"managers"];
        
        
        if(!returnValue)
            return returnValue;
        
        
    }

    
    
    returnValue = YES;
    
    return returnValue;
}
+(BOOL)isDBRowIdentical:(FMDatabase*)db ID:(int)ID row_guid:(NSString*)row_guid email_address:(NSString*)email_address table_name:(NSString*)table_name{

    BOOL returnValue = NO;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT row_guid,email_address FROM %@ WHERE ID = %i",table_name,ID];
    
    
    
    FMResultSet *rs = [db executeQuery:sql];

    while ([rs next])
    {
        NSString *row_guid2 = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *email_address2 = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        
        if(![row_guid isEqualToString:row_guid2]){
            break;
        }
        else if(![email_address isEqualToString:email_address2])
        {
            break;
        }
        else
        {
            returnValue = YES;
        }
    }
    
    
    return returnValue;

}
+(BOOL)UpdateOrInsertEmployeeByRow_id:(FMDatabase*)db sentTOServerOK:(int)sentTOServerOK  row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* ID = row[@"id"];
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
    NSString* email_address = row[@"email_address"];
    NSString* first_name = row[@"first_name"];
    NSString* last_name = row[@"last_name"];
    NSString* manager_guid = row[@"manager_guid"];
    
    //sentToServerOK=0 if local 1 if from server
    NSString* sql = [NSString stringWithFormat:@"UPDATE employees set row_timestamp = '%@',sentToServerOK=%i,email_address='%@',first_name='%@',last_name='%@',manager_guid='%@' WHERE row_guid='%@' ",row_timestamp,sentTOServerOK,email_address,first_name,last_name,manager_guid,row_guid];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0){
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name,manager_guid) VALUES('%@','%@',%i,'%@','%@','%@','%@')",row_guid,row_timestamp,sentTOServerOK,email_address,first_name,last_name,manager_guid];
        
        [db executeUpdate:sqlINSERT];
        
        NSLog(@"new rowid %lli",[db lastInsertRowId]);
    }
    else{
         NSLog(@"updated row_id %@", row[@"id"]);
    }
    
   returnValue = [db commit];
    

    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertManagerByRow_id:(FMDatabase*)db sentTOServerOK:(int)sentTOServerOK  row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    //NSString* ID = row[@"id"];
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
    NSString* email_address = row[@"email_address"];
    NSString* first_name = row[@"first_name"];
    NSString* last_name = row[@"last_name"];
   
    
    //sentToServerOK=0 if local 1 if from server
    NSString* sql = [NSString stringWithFormat:@"UPDATE managers set row_timestamp = '%@',sentToServerOK=%i,email_address='%@',first_name='%@',last_name='%@' WHERE row_guid='%@' ",row_timestamp,sentTOServerOK,email_address,first_name,last_name,row_guid];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0){
//        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name,manager_guid) VALUES('%@','%@',%i,'%@','%@','%@','%@')",row_guid,row_timestamp,sentTOServerOK,email_address,first_name,last_name,manager_guid];
        
         NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO managers(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name) VALUES('%@','%@',%i,'%@','%@','%@')",row_guid,row_timestamp,sentTOServerOK,email_address,first_name,last_name];
        
        [db executeUpdate:sqlINSERT];
        
        NSLog(@"new rowid %lli",[db lastInsertRowId]);
    }
    else{
        NSLog(@"updated row_id %@", row[@"id"]);
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}

+(BOOL)UpdateAndReinsertRows:(FMDatabase*)db  clashed_rows:(NSArray*)clashed_tables new_rows:(NSArray*) new_tables
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
   
    
   // [db beginTransaction];
    
        for (NSDictionary* table in new_tables) {
        
            
            NSString* table_name = table[@"table_name"];
            
            if([table_name isEqualToString:@"employees"])
            {
                NSArray* rows = table[@"rows"];
            
                if(rows)
                {
                
                    for (NSDictionary* row in rows) {
                        
                        
                        [self UpdateOrInsertEmployeeByID:db row:row]; // dirty flag NOT set because come from backend
                        
                    }
                }
            }
            else if([table_name isEqualToString:@"managers"])
            {
                NSArray* rows = table[@"rows"];
                
                if(rows)
                {
                    
                    for (NSDictionary* row in rows) {
                        
                        
                        [self UpdateOrInsertManagersByID:db row:row]; // dirty flag NOT set because come from backend
                        
                    }
                }
            }
{
                
            }
        }
    
    

    //3. Finally re Insert the deleted row from above
    for (NSDictionary* table in clashed_tables) {
        
        
        NSString* table_name = table[@"table_name"];
        
        if([table_name isEqualToString:@"employees"])
        {
            NSArray* rows = table[@"rows"];
            
            if(rows)
            {
                
                for (NSDictionary* row in rows)
                {
                    
                    [self UpdateOrInsertEmployeeByRow_id:db sentTOServerOK:0 row:row]; // NOT the same function as above! dirtyFlag should be 0
                    
                }
            }
        }
        else if([table_name isEqualToString:@"managers"])
        {
            NSArray* rows = table[@"rows"];
            
            if(rows)
            {
                
                for (NSDictionary* row in rows)
                {
                    
                    [self UpdateOrInsertManagerByRow_id:db sentTOServerOK:0 row:row]; // NOT the same function as above! dirtyFlag should be 0
                    
                }
            }
            
            
        }

    }

    
    
    returnValue = YES;//[db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateAndReinsertRowsOriginal:(FMDatabase*)db  clashed_rows:(NSArray*)clashed_rows new_rows:(NSArray*) new_rows
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    
    
    // [db beginTransaction];
    
    
    //get ID to update
    //if(clashed_rows.count == 1 && new_rows.count == 1 ){
    //        NSDictionary* clashed_row = clashed_rows[0];
    //        NSString* ID = clashed_row[@"id"];
    //
    
    //NSDictionary* new_row = new_rows[0];
    
    for (NSDictionary* row in new_rows) {
        
        
        [self UpdateOrInsertEmployeeByID:db row:row]; // dirty flag NOT set because come from backend
        
    }
    
    
    
    //3. Finally re Insert the deleted row from above
    for (NSDictionary* row in clashed_rows) {
        
        [self UpdateOrInsertEmployeeByRow_id:db sentTOServerOK:0 row:row]; // NOT the same function as above! dirtyFlag should be 0
        
    }
    
    
    
    returnValue = YES;//[db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertEmployeeByID:(FMDatabase*)db  row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* ID = row[@"id"];
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
    NSString* email_address = row[@"email_address"];
    NSString* first_name = row[@"first_name"];
    NSString* last_name = row[@"last_name"];
    NSString* manager_guid = row[@"manager_guid"];
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE employees set row_timestamp = '%@',sentToServerOK=1,email_address='%@',first_name='%@',last_name='%@',manager_guid='%@',row_guid='%@' WHERE id=%@ ",row_timestamp,email_address,first_name,last_name,manager_guid,row_guid,ID];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    NSLog(@"%@",[db lastErrorMessage]);
    NSLog(@"%i",[db lastErrorCode]);
    if([db lastErrorCode] != 0 ){
        [db rollback];
        return returnValue;
    }

    if(i == 0){
        
        //NSString* GUID = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant
        
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO employees(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name,manager_guid) VALUES('%@','%@',1,'%@','%@','%@','%@')",row_guid,row_timestamp,email_address,first_name,last_name,manager_guid];
        
        [db executeUpdate:sqlINSERT];
        NSLog(@"%@",[db lastErrorMessage]);
        NSLog(@"%i",[db lastErrorCode]);
        if([db lastErrorCode] != 0 ){
            [db rollback];
            return returnValue;
        }
        
         NSLog(@"new rowid %lli",[db lastInsertRowId]);

    }else{
        NSLog(@"updated row_id %@", row[@"id"]);
    }

    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertManagersByID:(FMDatabase*)db  row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* ID = row[@"id"];
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
    NSString* email_address = row[@"email_address"];
    NSString* first_name = row[@"first_name"];
    NSString* last_name = row[@"last_name"];
   
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE managers set row_timestamp = '%@',sentToServerOK=1,email_address='%@',first_name='%@',last_name='%@',row_guid='%@' WHERE id=%@ ",row_timestamp,email_address,first_name,last_name,row_guid,ID];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    NSLog(@"%@",[db lastErrorMessage]);
    NSLog(@"%i",[db lastErrorCode]);
    if([db lastErrorCode] != 0 ){
        [db rollback];
        return returnValue;
    }
    
    if(i == 0){
        
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO managers(row_guid,row_timestamp,sentToServerOK,email_address,first_name,last_name) VALUES('%@','%@',1,'%@','%@','%@')",row_guid,row_timestamp,email_address,first_name,last_name];
        
        [db executeUpdate:sqlINSERT];
        NSLog(@"%@",[db lastErrorMessage]);
        NSLog(@"%i",[db lastErrorCode]);
        if([db lastErrorCode] != 0 ){
            [db rollback];
            return returnValue;
        }
        
        NSLog(@"new rowid %lli",[db lastInsertRowId]);
        
    }else{
        NSLog(@"updated row_id %@", row[@"id"]);
    }
    
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}

@end

