//
//  ServerLibrary.m
//  MobileSync
//
//  Created by john goodstadt on 10/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "ServerHelper.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MobileHelper.h"
#include "OpenUDID.h"

static NSString *const serverDatabasePath = @"/server.db";


@interface customStruct : NSObject
@property (assign, nonatomic) int row_id;
@property (strong, nonatomic) NSString* row_guid;
@end



@interface ServerHelper ()
@property FMDatabase *serverDB; //only local access.
@end

/*
 For a server that is on a web server this file would be written in an appropriate labguage e.g. PHP, Jave etc.
 */

@implementation ServerHelper
- (id)init {
   
    [self createDBIfNecessary];
    
    return self;
}
-(void)createDB
{
    [self deleteDB]; //clear down previous DB
    
    self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
    [self.serverDB open];
    
    [self addServerDomainTablesIfNecessary];
    
}
-(void)attachDB
{
    self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
    [self.serverDB open];
    
    [self addServerDomainTablesIfNecessary];
    
}
-(BOOL)existsDB
{

    return [MobileHelper fileExistsInDocuments:[ServerHelper databasePath]];
    
}
+ (NSString *)databasePath
{
    return serverDatabasePath;
}
- (void)addServerDomainTablesIfNecessary
{
    
    
    //Section A Setup Server DB Tables
    
    if(![self.serverDB tableExists:@"domains"]){
        
        //email_address used here as 'unique' user identifier
        [self.serverDB executeUpdate:@"create table domains (id_server integer not null primary key autoincrement, row_guid text not null, row_timestamp text not null,domain_guid text not null,login_id text default '',deleted integer default 0)"];
        
        [self.serverDB executeUpdate:@"CREATE UNIQUE INDEX domain_guid_unique_index on domains (domain_guid)"]; //only 1 row per 'user'
        
    }
 
    //Optional table tracking remotes and domains
    if(![self.serverDB tableExists:@"device_domain"]){
        
        //email_address used here as 'unique' user identifier
        [self.serverDB executeUpdate:@"create table devices_domain (id integer not null primary key autoincrement, device_guid text not null, row_timestamp text not null,domain_guid text not null)"];
        
        [self.serverDB executeUpdate:@"CREATE UNIQUE INDEX devices_domain_devices_guid on devices_domain (device_guid)"]; //only 1 row per 'device'
        
        
        
        
    }
    
           
    [self AddServerPayloadTablesIfNecessary];
    
}
/**
 Add empty payload ( here employees ) table to hold rows populated from mobile devices
 */
- (void)AddServerPayloadTablesIfNecessary {
    
    
    
    //Add Payload Cols to domains server table - Unique values for this domain
    
    if(![self.serverDB tableExists:@"employees"]){
        
        [self.serverDB executeUpdate:@"create table employees (id_server integer not null primary key autoincrement,domain_guid text not null,row_guid text not null, row_timestamp text not null,id integer default 0,email_address text default '',first_name text default '',last_name text default '',manager_guid text default '',deleted integer default 0)"];
        
        [self.serverDB executeUpdate:@"CREATE UNIQUE INDEX employees_row_guid on employees (row_guid)"];
        
        
    }
    
    if(![self.serverDB tableExists:@"managers"]){
        
        [self.serverDB executeUpdate:@"create table managers (id_server integer not null primary key autoincrement,domain_guid text not null,row_guid text not null, row_timestamp text not null,id integer default 0,email_address text default '',first_name text default '',last_name text default '',deleted integer default 0)"];
        
        [self.serverDB executeUpdate:@"CREATE UNIQUE INDEX managers_row_guid on managers (row_guid)"];
        
        
    }
    
    
}
- (void)deleteDB
{
    @try {
        
        NSError* error;
        NSString* serverPath = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:serverDatabasePath];
        [[NSFileManager defaultManager] removeItemAtPath: serverPath error:&error];
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@ %@",exception.name,exception.reason);
    }

}
- (void)dealloc
{
    [self.serverDB close];
}
#pragma mark Server Backend Routines - PHP/JAVA etc
- (int)timezoneAdjustmentToServerTime:(NSString *)client_timestamp
{

    int returnValue = 0;
    
    
    NSDate* dt = [ServerHelper DateFromDB:client_timestamp];
   
    
    float diff_seconds = [[NSDate date] timeIntervalSinceDate:dt]; //if minus
    
    if(diff_seconds >= 1800 && diff_seconds < 1800) //minimum time zone difference is 30 minutes (1800 seconds)  -so use 0  i.e. 3.0 would mean netork latency is 3 seconds - so use no same timezone
    {
        returnValue = diff_seconds;
    }
    
    return returnValue ;
}
- (int)timezoneAdjustmentToClientTime:(NSString *)client_timestamp
{
    
    int returnValue = 0;
    
    
    NSDate* dt = [ServerHelper DateFromDB:client_timestamp];
    
    
    float diff_seconds = [dt timeIntervalSinceDate:[NSDate date]];
    
    if(diff_seconds >= 1800 && diff_seconds < 1800) //minimum time zone difference is 30 minutes (1800 seconds)  -so use 0  i.e. 3.0 would mean netork latency is 3 seconds - so use not same timezone
    {
        returnValue = diff_seconds;
    }
    
    return returnValue ;
}
- (NSString*)dateByAddingTimezoneOffset:(NSString *)row_timestamp timezoneAdjustment:(int)timezoneAdjustment
{
    
    NSString* returnVaue = row_timestamp;
 
    
    @try {
        NSDate* dt = [ServerHelper DateFromDB:row_timestamp];
        NSDate* newDate = [dt dateByAddingTimeInterval:timezoneAdjustment];
        
        returnVaue = [ServerHelper stringFromDate:newDate andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
   
    
    
    
    
    return returnVaue;
}

//Only local to this routine
-(NSString*)UPDATEServer:(NSString*)json{
    
    NSError *error;
    NSData *objectData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:0
                                                           error:&error];
    
    
    //2. Insert all rows
    
    //If no Domain entry add it
    NSString* domain_guid = jsonDictionary[@"domain"];
    NSString* client_timestamp = jsonDictionary[@"client_timestamp"];
    NSString* device_guid = jsonDictionary[@"device_guid"];

    NSString*jsonResponse = @"{}";
    
    
    int timezoneAdjustment = [self timezoneAdjustmentToServerTime:client_timestamp];
    
    if(!self.serverDB)
    {
        if([self existsDB])
        {
            self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
            [self.serverDB open]; // will attach existing DB here
        }
        else
        {
            [self createDB]; //will create DB here and add domains table
        }
     
    }
    
    //Optional Table - log which devices are in which domains
    if(device_guid && device_guid.length > 0 && domain_guid && domain_guid.length> 0){
        [ServerHelper UpdateOrInsertDomainDevice:self.serverDB domain_guid:domain_guid device_guid:device_guid row_timestamp:client_timestamp];
    }
    
    
   
    
    //1. json to Array of dictionaries
    
    
    NSArray* tables = jsonDictionary[@"tables"];
    NSDictionary* package =  @{};
    BOOL haveIAnyClashes = [self checkIfClashWithAnyTables:domain_guid tables:tables];

    if(haveIAnyClashes){
        
        for (NSDictionary* table in tables)
        {
            NSString* table_name = table[@"table_name"];
            
            if([table_name isEqualToString:@"domain"]) // system table will never clash
            {
                continue;
            }
            
            NSArray* rows = rows = table[@"rows"];
            
            if (rows) //TODO:  table[@"rows"] ???
            {
                rows = table[@"rows"];
                int minRow_id = [self minIDOfClashWithTable:domain_guid table_name:table_name rows:rows table:table];
                if(minRow_id > 0)
                {
                    
                    NSArray* newRows = [self getRowsAddedByAnotherID:minRow_id table_name:table_name domain_guid:domain_guid client_timestamp:client_timestamp];
                    
                    NSDictionary* table = @{@"table_name":table_name,@"rows":newRows};
                    NSArray* new_tables = @[table];
                    
                    package = @{@"error":@"clash",@"clashed_tables":tables,@"new_tables":new_tables};
                    break;
                }
            }
        }
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:package
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        jsonResponse = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        return jsonResponse; //early 1 row exit - must change??

    }
    else{
        //2. rows
        for (NSDictionary* table in tables)
        {
            NSString* table_name = table[@"table_name"];

            NSArray* rows = rows = table[@"rows"];
            for (NSDictionary* row in rows)
            {
                
                if([table_name isEqualToString:@"employees"])
                {

                    NSString* row_timestamp = row[@"row_timestamp"];
                    
                    if(timezoneAdjustment != 0){
                        row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
                    }
                    
                    [ServerHelper UpdateOrInsertEmployee:self.serverDB domain_guid:domain_guid row:row];
                    
                    
                }
                else  if([table_name isEqualToString:@"managers"])
                {
                    NSString* row_timestamp = row[@"row_timestamp"];
                    
                    if(timezoneAdjustment != 0){
                        row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
                    }

                    [ServerHelper UpdateOrInsertManager:self.serverDB domain_guid:domain_guid row:row];
                    
                    
                }
                else if([table_name isEqualToString:@"domain"])
                {
                    
                    NSString* row_timestamp = row[@"row_timestamp"];
                    NSString *domain_guid =  row[@"domain_guid"];
                    
                    if(timezoneAdjustment != 0){
                        row_timestamp=[self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
                    }

                    [ServerHelper UpdateOrInsertDomain:self.serverDB domain_guid:domain_guid row:row];
                    
                }
            }
        }
    }
    
    return jsonResponse;
    
}



/**
 */

-(NSString*)LoginToBackEnd:(NSString*)json
{

    NSString* returnValue = @""; //error
    
    NSError *error;
    NSData *objectData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:objectData
                                                                   options:0
                                                                     error:&error];
    
    
    //2. Insert all rows
    
    //If no Domain entry add it
    NSString* domain_guid = jsonDictionary[@"domain_guid"];
    NSString* login_id = jsonDictionary[@"login_id"];

    NSString* row_guid = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant
    NSString* time_stamp = [ServerHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* device_guid = jsonDictionary[@"device_guid"];
    
    /*
     A. if existing matching login id - then use it - return existing but different domain id
     B.if new domain (user) then add - including login id - return passed in domain id
     C.if not new but logging in (transition from logged out to logged in) add login id to row - return passed in domain id
     D.if not new but logging in to another devices data - return different domain id
     */
    
    
    int count_loginid_exists = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT count(*) FROM domains WHERE login_id = '%@'",login_id]];
    
    if(count_loginid_exists > 0)
    {
        //A.
        NSString *sql = [NSString stringWithFormat:@"SELECT domain_guid FROM domains WHERE login_id = '%@'",login_id];
        FMResultSet *rs = [self.serverDB executeQuery:sql];

        if([rs next])
        {
            returnValue =  [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]]; //domain unique id for this login_id
        }
        
        //if old domain_id has non logged in rows they could be cleaned up (deleted) here as they are now orphened
    }
    else
    {
        
        int count_domain_exists = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT count(*) FROM domains WHERE domain_guid = '%@'",domain_guid]];
        
        if(count_domain_exists == 0)
        {
            //B.
            [self.serverDB  executeUpdate:[NSString stringWithFormat:@"INSERT INTO domains(row_guid,row_timestamp,domain_guid,login_id) VALUES('%@','%@','%@','%@')",row_guid,time_stamp,domain_guid,login_id]];

            returnValue = domain_guid; //Use existing domain
        }
        else
        {
            NSString *sql = [NSString stringWithFormat:@"SELECT domain_guid FROM domains WHERE login_id = '%@'",login_id];
            FMResultSet *rs = [self.serverDB executeQuery:sql];
            
            
            if([rs next])
            {
                //C.
                returnValue =  [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]]; //domain unique id for this login_id
            }
            else
            {
                //D.
                //first login to this ID so update login id and return the domain id to the client
                
                [ServerHelper UpdateOrInsertDomainAlternative:self.serverDB domain_guid:domain_guid row_guid:row_guid row_timestamp:time_stamp login_id:login_id];
//                
//                [self.serverDB  executeUpdate:[NSString stringWithFormat:@"REPLACE INTO domains(row_guid,row_timestamp,domain_guid,login_id) VALUES('%@','%@','%@','%@')",row_guid,time_stamp,domain_guid,login_id]];
                
                returnValue = domain_guid; //Use existing domain
                
            }

        }
    
       
    
    }

    
    //Optional Table - log which devices are in which domains
    if(device_guid && device_guid.length > 0 && domain_guid && domain_guid.length> 0){
         [ServerHelper UpdateOrInsertDomainDevice:self.serverDB domain_guid:domain_guid device_guid:device_guid row_timestamp:time_stamp];
    }
    
    
     return returnValue;
}

    
-(NSString*)refreshByDomain:(NSString*)domain  client_timestamp:(NSString*)client_timestamp tableTimeStamps:(NSArray*)table_time_stamps
{
    if(!self.serverDB)
    {
        self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
        
        [self.serverDB open];
        
    }
    
    int timezoneAdjustmentServer = [self timezoneAdjustmentToServerTime:client_timestamp];
    int timezoneAdjustmentToClient = [self timezoneAdjustmentToClientTime:client_timestamp];
    
    
    NSMutableArray*allRows = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray*allTables = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (NSDictionary* d in table_time_stamps) {
        
        NSString* table_name = d[@"table_name"];
        
        if([table_name isEqualToString:@"employees"])
        {
            NSString* QueryTimestamp = d[@"timestamp"];
            
            if(timezoneAdjustmentServer != 0){
                QueryTimestamp = [self dateByAddingTimezoneOffset:QueryTimestamp timezoneAdjustment:timezoneAdjustmentServer];
            }
            
            
            
            
            //1. read data for 1 domain
            int count = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM employees WHERE domain_guid = '%@' AND row_timestamp > '%@'",domain,QueryTimestamp]];
            
            NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
            
            NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid,deleted FROM employees WHERE domain_guid = '%@' AND row_timestamp > '%@'",domain,QueryTimestamp];
            FMResultSet *rs = [self.serverDB executeQuery:sql];
            
            while ([rs next])
            {
                NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
                NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
                NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
                NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
                NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
                NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
                NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
                NSString *deleted = [rs stringForColumnIndex:[rs columnIndexForName:@"deleted"]];
                
                if(timezoneAdjustmentToClient != 0){
                    row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustmentToClient];
                }
                
                NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
                row[@"table"] = @"employees";
                row[@"id"] = ID;
                row[@"row_guid"] = row_guid;
                row[@"row_timestamp"] = row_timestamp;
                row[@"email_address"] = email_address;
                row[@"first_name"] = first_name;
                row[@"last_name"] = last_name;
                row[@"manager_guid"] = manager_guid;
                row[@"deleted"] = deleted;
                
                [rows addObject:row];
                
                
            }
            
            if(count > 0){
                allRows = [[allRows arrayByAddingObjectsFromArray:rows] mutableCopy];
                
                
               NSDictionary* table = @{@"table_name":table_name,@"rows":rows};
               [allTables addObject:table];
            }

        }
        else if([table_name isEqualToString:@"managers"])
        {
            NSString* QueryTimestamp = d[@"timestamp"];
            if(timezoneAdjustmentServer != 0){
                QueryTimestamp = [self dateByAddingTimezoneOffset:QueryTimestamp timezoneAdjustment:timezoneAdjustmentServer];
            }
            
            
            int count = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM managers WHERE domain_guid = '%@' AND row_timestamp > '%@'",domain,QueryTimestamp]];
            
            NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
            
            NSString *sql = [NSString stringWithFormat:@"SELECT row_guid,row_timestamp,email_address,first_name,last_name,deleted FROM managers WHERE domain_guid = '%@' AND row_timestamp > '%@'",domain,QueryTimestamp];
            FMResultSet* rs = [self.serverDB executeQuery:sql];
            
            while ([rs next])
            {
                NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
                NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
                NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
                NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
                NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
                NSString *deleted = [rs stringForColumnIndex:[rs columnIndexForName:@"deleted"]];
                
                if(timezoneAdjustmentToClient != 0){
                    row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustmentToClient];
                }
                
                NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
                row[@"table"] = @"managers";
                row[@"row_guid"] = row_guid;
                row[@"row_timestamp"] = row_timestamp;
                row[@"email_address"] = email_address;
                row[@"first_name"] = first_name;
                row[@"last_name"] = last_name;
                row[@"deleted"] = deleted;
                
                [rows addObject:row];
                
                
            }

            if(count > 0){
                allRows = [[allRows arrayByAddingObjectsFromArray:rows] mutableCopy];
                
                NSDictionary* table = @{@"table_name":table_name,@"rows":rows};
                [allTables addObject:table];
            }
        }
        else if([table_name isEqualToString:@"domains"])
        {
            
        }

        
    }
    
   
    
   
    
    //2. convert to json for sending back to device
    NSString* time_stamp = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSDictionary* package = @{@"domain":domain,@"server_time":time_stamp,@"rows":allRows,@"tables":allTables};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:package
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    return jsonString;
    
}
-(void)addOneEmployee:(NSString*)useDomain
{
    if(!self.serverDB)
    {
        self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
        
        [self.serverDB open];
        
    }
    
    
    NSString* GUID = [[NSProcessInfo processInfo] globallyUniqueString]; //unique in the world - at this instant
    
    NSString* row_guid = GUID;
    NSString* row_timestamp =  [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* email_address = @"sarah@cooper.com";
    NSString* first_name = @"sarah";
    NSString* last_name = @"cooper";
    
    
    
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO employees (domain_guid,row_guid,row_timestamp,email_address,first_name,last_name) VALUES('%@','%@','%@','%@','%@','%@')",useDomain,row_guid,row_timestamp,email_address,first_name,last_name];
    
    [self.serverDB executeUpdate:sql];

    
    
    
    
}
//Go Direct to DB for this Tab
-(NSArray*)getEmployees
{
    
    int count = [self.serverDB intForQuery:@"SELECT COUNT(*) FROM employees"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = @"SELECT domain_guid,row_guid,row_timestamp,email_address,first_name,last_name,manager_guid,deleted FROM employees";
    
    FMResultSet *rs = [self.serverDB executeQuery:sql];
    
    while ([rs next])
    {
        NSString *domain_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        NSString *manager_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"manager_guid"]];
        NSString *deleted = [rs stringForColumnIndex:[rs columnIndexForName:@"deleted"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:count];
        row[@"table"] = @"employees";
        row[@"domain_guid"] = domain_guid;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        row[@"manager_guid"] = manager_guid ? manager_guid : @"";
        row[@"deleted"] = deleted;
        
        
        [rows addObject:row];
        
        
    }
    
    return [rows copy];
}
-(NSArray*)getDomains
{
    
    int count = [self.serverDB  intForQuery:@"SELECT COUNT(*) FROM domains"];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = @"SELECT row_guid,row_timestamp,login_id,domain_guid FROM domains";
    
    FMResultSet *rs = [self.serverDB  executeQuery:sql];
    
    while ([rs next])
    {
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *login_id = [rs stringForColumnIndex:[rs columnIndexForName:@"login_id"]];
        NSString *domain_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"domain_guid"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table"] = @"domains";
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"login_id"] = login_id;
        row[@"domain_guid"] = domain_guid;
        
        [rows addObject:row];
        
        
    }
    
    return [rows copy];
}
-(void)createDBIfNecessary
{
    
    if(!self.serverDB)
    {
        if([self existsDB])
        {
            self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
            [self.serverDB open]; // will attach existing DB here
        }
        else
        {
            
            [self createDB]; //will create DB here and add domains table
            
        }
        
    }

}
-(void)getServerTime{
    
}
+ (NSString*)stringFromDate:(NSDate*)Date andFormat:(NSString*)format
{
    
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc]init];
    [outputDateFormatter setDateFormat:format];
    
    return [outputDateFormatter stringFromDate:Date];
    
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
-(int)getHighestEmployeeNumber
{
    int returnValue = 0;
    
    if(!self.serverDB)
    {
        self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
        
        [self.serverDB open];
        
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT last_name FROM employees ORDER BY  last_name desc LIMIT 1 "];
    FMResultSet *rs = [self.serverDB executeQuery:sql];
    
    while ([rs next])
    {
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        returnValue = [last_name intValue];
        
        break;
        
    }
    
    return returnValue;
}
-(int)getHighestManagerNumber
{
    int returnValue = 0;
    
    if(!self.serverDB)
    {
        self.serverDB = [FMDatabase databaseWithPath:[[MobileHelper applicationDocumentsDirectory]  stringByAppendingPathComponent:[ServerHelper databasePath]]];
        
        [self.serverDB open];
        
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT last_name FROM managers ORDER BY  last_name desc LIMIT 1 "];
    FMResultSet *rs = [self.serverDB executeQuery:sql];
    
    while ([rs next])
    {
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        returnValue = [last_name intValue];
        
        break;
        
    }
    
    return returnValue;
}
-(BOOL)checkIfClashWithID:(int)ID table_name:(NSString*)table_name  col_name:(NSString*)col_name  domain_guid:(NSString*)domain_guid row_guid:(NSString*)row_guid
{
    
    BOOL returnValue = NO;
    
    int count = [self.serverDB  intForQuery:[NSString stringWithFormat:@"SELECT count(*) FROM %@ WHERE domain_guid = '%@' AND %@ = %i AND  row_guid != '%@'",table_name,domain_guid,col_name,ID,row_guid]];
    
    if(count > 0){
        returnValue = YES;
    }
    
    
    return returnValue;
}
-(int)checkIfClashWithRowsObsolete:(NSString*)domain_guid rows:(NSArray*)rows
{
    
    //TODO: JUST FOR TABLE EMPLOYEES
    
    int returnValue = 0; //default exit value
    
    if(rows.count == 0){
        return returnValue;
    }
    else if(rows.count > 0){
        
        NSDictionary* row = rows[0];
        NSString* auto_increment_col = row[@"auto_increment_col"];
        if(auto_increment_col == nil){ //is there an auto col present
            return returnValue;
        }else{
            if(row[auto_increment_col] == nil){ //check if auto row is actually in row (mis spelt?)
                return returnValue;
            }
        }
    }
    
    //1. get min ID for each table
    int minID = INT_MAX; // high number
    NSString* min_row_guid = @"";
     NSString* auto_increment_col = @"";
    for (NSDictionary* row in rows)
    {
        
        NSString* table_name = row[@"table_name"];
        auto_increment_col = row[@"auto_increment_col"];
        
        if([table_name isEqualToString:@"employees"])
        {
            
            NSString* ID = row[auto_increment_col];
            
            if([ID intValue] <  minID){
                minID = [ID intValue];
                min_row_guid = row[@"row_guid"] ;
            }
            
        }
        
    }
    
    //2. do any rows clash with this ID
    BOOL clashed = [self checkIfClashWithID:minID table_name:@"employees" col_name:auto_increment_col domain_guid:domain_guid row_guid:min_row_guid];
    
    

    if(clashed){
        returnValue = minID;
    }
    
    
    
    return returnValue;
}
-(int)minIDOfClashWithTable:(NSString*)domain_guid table_name:(NSString*)table_name rows:(NSArray*)rows table:(NSDictionary*)table
{
    
    //TODO: JUST FOR TABLE EMPLOYEES
    
    int returnValue = 0; //default exit value - no clash
   
    NSString* auto_increment_col = table[@"auto_increment_col"];
    
    if(rows.count == 0){
        return returnValue;
    }
    else if(rows.count > 0) //auto_increment_col must be defined and point to valid column_name to continue
    {
        
        NSDictionary* row = rows[0];
        
        if(auto_increment_col == nil){ //is there an auto col present
            return returnValue;
        }else{
            if(row[auto_increment_col] == nil){ //check if auto row is actually in row (mis spelt?)
                return returnValue;
            }
        }
    }
    
    
    
    //1. get min ID for each table
    int minID = INT_MAX; // high number
    NSString* min_row_guid = @"";
    //NSString* auto_increment_col = @"";
    for (NSDictionary* row in rows)
    {
        NSString* ID = row[auto_increment_col];
            
            if([ID intValue] <  minID){
                minID = [ID intValue];
                min_row_guid = row[@"row_guid"] ;
            }
            

        
    }
    
    //2. do any rows clash with this ID
    BOOL clashed = [self checkIfClashWithID:minID table_name:table_name col_name:auto_increment_col domain_guid:domain_guid row_guid:min_row_guid];
    
    if(clashed){
        returnValue = minID;
    }
    
    
    
    return returnValue;
}

//Called for each table
-(BOOL)checkIfClashWithAnyTables:(NSString*)domain_guid tables:(NSArray*)tables
{
    
    //TODO: JUST FOR TABLE EMPLOYEES
    
    BOOL returnValue = NO; //default exit value
    
     NSArray*rows;
    
    for (NSDictionary* table in tables) //dont need to do domain table
    {

            rows = table[@"rows"];
            NSString* auto_increment_col = table[@"auto_increment_col"];
            NSString* table_name = table[@"table_name"];
        
            if([table_name isEqualToString:@"domain"]) // system table will never clash
            {
                continue;
            }
            
            if(!rows){
                continue;
            }

            
            if(rows.count == 0){
                continue;
            }
            else if(rows.count > 0){
                
                NSDictionary* row = rows[0];
                if(auto_increment_col == nil){ //is there an auto col present
                    continue;
                }else{
                    if(row[auto_increment_col] == nil){ //check if auto row is actually in row (mis spelt?)
                        continue;
                    }
                }
            }
            
            
            //1. get min ID for each table
            int minID = INT_MAX; // high number
            NSString* min_row_guid = @"";
            for (NSDictionary* row in rows)
            {
                    NSString* ID = row[auto_increment_col];
                    
                    if([ID intValue] <  minID){
                        minID = [ID intValue];
                        
                        min_row_guid = [NSMutableString stringWithString:row[@"row_guid"] ] ;
                    }
                
            }

            
            
           // customStruct* returnedValues =  [self getMinAutoIncrementIDfromRows:rows];
            
            //2. do any rows clash with this ID
            returnValue = [self checkIfClashWithID:minID table_name:table_name col_name:auto_increment_col domain_guid:domain_guid row_guid:min_row_guid];

            if(returnValue){
                break; // if any 1 table is clashed then we can return YES for all
            }
            

    }
    
    return returnValue;
}

-(BOOL)checkIfClashWithAnyTablesOriginal:(NSString*)domain_guid tables:(NSArray*)tables
{
    
    //TODO: JUST FOR TABLE EMPLOYEES
    
    BOOL returnValue = NO; //default exit value
    
    NSArray*rows;
    
    for (NSDictionary* table in tables)
    {
        if ([table[@"table_name" ] isEqualToString:@"employees"])//TODO: just for now
        {
            rows = table[@"rows"];
            
            if(!rows){
                break;
            }
            
            
            break;
        }
    }
    
    
        if(!rows){
            return returnValue;
        }
    
    
    
    
        if(rows.count == 0){
            return returnValue;
        }
        else if(rows.count > 0){
    
            NSDictionary* row = rows[0];
            NSString* auto_increment_col = row[@"auto_increment_col"];
            if(auto_increment_col == nil){ //is there an auto col present
                return returnValue;
            }else{
                if(row[auto_increment_col] == nil){ //check if auto row is actually in row (mis spelt?)
                    return returnValue;
                }
            }
        }
    
    
    
    
    //1. get min ID for each table
        int minID = INT_MAX; // high number
        NSString* min_row_guid = @"";
        NSString* auto_increment_col = @"";
        for (NSDictionary* row in rows)
        {

            NSString* table_name = row[@"table_name"];
            auto_increment_col = row[@"auto_increment_col"];

            if([table_name isEqualToString:@"employees"])
            {

                NSString* ID = row[auto_increment_col];

                if([ID intValue] <  minID){
                    minID = [ID intValue];
                    min_row_guid = row[@"row_guid"] ;
                }

            }

        }
    
    
    //int minID =  [self getMinAutoIncrementIDfromRows:rows];
    
    //2. do any rows clash with this ID
    returnValue = [self checkIfClashWithID:minID table_name:@"employees" col_name:auto_increment_col domain_guid:domain_guid row_guid:min_row_guid];
    
    return returnValue;
}

-(NSArray*)getRowsAddedByAnotherID:(int)ID table_name:(NSString*)table_name  domain_guid:(NSString*)domain_guid  client_timestamp:(NSString*)client_timestamp
{
    //TODO:Assumes each table has the same rows
    
    int timezoneAdjustment = [self timezoneAdjustmentToClientTime:client_timestamp];
    //1. read data for 1 domain
    
   
    NSMutableArray*rows;
    
    if([table_name isEqualToString:@"employees"]){
        
        
        int count = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM employees WHERE domain_guid = '%@' AND id >= %i ",domain_guid,ID]];
        
        rows = [[NSMutableArray alloc] initWithCapacity:count];
        
        NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM employees WHERE domain_guid = '%@' AND id >= %i ",domain_guid,ID];
        FMResultSet *rs = [self.serverDB executeQuery:sql];
        
        while ([rs next])
        {
            NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
            NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
            NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
            NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
            NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
            NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
            
            
            if(timezoneAdjustment != 0){
                row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
            }
            
            
            
            NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
            row[@"table"] = @"employees";
            row[@"id"] = ID;
            row[@"row_guid"] = row_guid;
            row[@"row_timestamp"] = row_timestamp;
            row[@"email_address"] = email_address;
            row[@"first_name"] = first_name;
            row[@"last_name"] = last_name;
            
            [rows addObject:row];
        }
        
        
    }else  if([table_name isEqualToString:@"managers"])
    {
    
        int count = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE domain_guid = '%@' AND id >= %i ",table_name,domain_guid,ID]];
        
        rows = [[NSMutableArray alloc] initWithCapacity:count];
        
        NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM %@ WHERE domain_guid = '%@' AND id >= %i ",table_name,domain_guid,ID];
        FMResultSet *rs = [self.serverDB executeQuery:sql];
        
        while ([rs next])
        {
            NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
            NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
            NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
            NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
            NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
            NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
            
            
            if(timezoneAdjustment != 0){
                row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
            }
            
            
            
            NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
            row[@"table"] = @"employees";
            row[@"id"] = ID;
            row[@"row_guid"] = row_guid;
            row[@"row_timestamp"] = row_timestamp;
            row[@"email_address"] = email_address;
            row[@"first_name"] = first_name;
            row[@"last_name"] = last_name;
            
            [rows addObject:row];

        }
    
    }

    
                 
   return rows;
    
    
   
}
-(NSArray*)getTablesAddedByAnotherID:(int)ID table_name:(NSString*)table_name  domain_guid:(NSString*)domain_guid  client_timestamp:(NSString*)client_timestamp
{
    
    
    int timezoneAdjustment = [self timezoneAdjustmentToClientTime:client_timestamp];
    //1. read data for 1 domain
    int count = [self.serverDB intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE domain_guid = '%@' AND id >= %i ",table_name,domain_guid,ID]];
    
    NSMutableArray*rows = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM %@ WHERE domain_guid = '%@' AND id >= %i ",table_name,domain_guid,ID];
    FMResultSet *rs = [self.serverDB executeQuery:sql];
    
    while ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        
        
        if(timezoneAdjustment != 0){
            row_timestamp = [self dateByAddingTimezoneOffset:row_timestamp timezoneAdjustment:timezoneAdjustment];
        }
        
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:6];
        row[@"table"] = @"employees";
        row[@"id"] = ID;
        row[@"row_guid"] = row_guid;
        row[@"row_timestamp"] = row_timestamp;
        row[@"email_address"] = email_address;
        row[@"first_name"] = first_name;
        row[@"last_name"] = last_name;
        
        [rows addObject:row];
        
        
    }
    
    
    return rows;
    
    
    
}

+(BOOL)UpdateOrInsertEmployee:(FMDatabase*)db domain_guid:(NSString*)domain_guid row:(NSDictionary*) row
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
    NSString* deletedString = row[@"deleted"];
    
    


    
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE employees set row_timestamp = '%@',id=%i,email_address='%@',first_name='%@',last_name='%@',manager_guid='%@' WHERE domain_guid = '%@' AND row_guid='%@' ",row_timestamp,[ID intValue],email_address,first_name,last_name,manager_guid,domain_guid,row_guid];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0)
    {
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO employees (domain_guid,row_guid,row_timestamp,id,email_address,first_name,last_name,manager_guid,deleted) VALUES('%@','%@','%@',%i,'%@','%@','%@','%@',%i)",domain_guid,row_guid,row_timestamp,[ID intValue],email_address,first_name,last_name,manager_guid,[deletedString intValue]];
        
        [db executeUpdate:sqlINSERT];
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertManager:(FMDatabase*)db domain_guid:(NSString*)domain_guid row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* ID = row[@"id"];
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
    NSString* email_address = row[@"email_address"];
    NSString* first_name = row[@"first_name"];
    NSString* last_name = row[@"last_name"];
    NSString* deletedString = row[@"deleted"];
    
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE managers set row_timestamp = '%@',id=%i,email_address='%@',first_name='%@',last_name='%@'WHERE domain_guid = '%@' AND row_guid='%@' ",row_timestamp,[ID intValue],email_address,first_name,last_name,domain_guid,row_guid];
    
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0)
    {
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO managers (domain_guid,row_guid,row_timestamp,id,email_address,first_name,last_name,deleted) VALUES('%@','%@','%@',%i,'%@','%@','%@',%i)",domain_guid,row_guid,row_timestamp,[ID intValue],email_address,first_name,last_name,[deletedString intValue]];
        
        [db executeUpdate:sqlINSERT];
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertDomainAlternative:(FMDatabase*)db domain_guid:(NSString*)domain_guid row_guid:(NSString*)row_guid row_timestamp:(NSString*)row_timestamp login_id:(NSString*)login_id
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE domains set row_timestamp = '%@',login_id='%@', row_guid='%@'  WHERE domain_guid = '%@' ",row_timestamp,login_id,row_guid,domain_guid];
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0)
    {
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO domains (domain_guid,row_guid,row_timestamp,login_id) VALUES('%@','%@','%@','%@')",domain_guid,row_guid,row_timestamp,login_id];
        
        [db executeUpdate:sqlINSERT];
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertDomainDevice:(FMDatabase*)db domain_guid:(NSString*)domain_guid device_guid:(NSString*)device_guid row_timestamp:(NSString*)row_timestamp
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    BOOL returnValue = NO;
    
    NSString* sql = [NSString stringWithFormat:@"UPDATE devices_domain set row_timestamp = '%@' WHERE domain_guid = '%@' ",row_timestamp,domain_guid];
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0)
    {
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO devices_domain (domain_guid,device_guid,row_timestamp) VALUES('%@','%@','%@')",domain_guid,device_guid,row_timestamp];
        
        [db executeUpdate:sqlINSERT];
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
+(BOOL)UpdateOrInsertDomain:(FMDatabase*)db domain_guid:(NSString*)domain_guid row:(NSDictionary*) row
{
    
    //taken from http://stackoverflow.com/questions/418898/sqlite-upsert-not-insert-or-replace answer 4
    
    
    //


    
    BOOL returnValue = NO;
    
    NSString* row_guid = row[@"row_guid"];
    NSString* row_timestamp = row[@"row_timestamp"];
   // NSString* deleted = row[@"deleted"]; //p
    NSString* login_id = row[@"login_id"];

    
    
//    NSString* sql = [NSString stringWithFormat:@"UPDATE domains set row_timestamp = '%@',login_id='%@' WHERE domain_guid = '%@' AND row_guid='%@' ",row_timestamp,domain_guid,login_id,row_guid];
    NSString* sql = [NSString stringWithFormat:@"UPDATE domains set row_timestamp = '%@',login_id='%@', row_guid='%@'  WHERE domain_guid = '%@' ",row_timestamp,login_id,row_guid,domain_guid];
    
    [db beginTransaction];
    
    [db executeUpdate:sql];
    int i = [db changes];
    if(i == 0)
    {
        NSString* sqlINSERT = [NSString stringWithFormat:@"INSERT INTO domains (domain_guid,row_guid,row_timestamp,login_id) VALUES('%@','%@','%@','%@')",domain_guid,row_guid,row_timestamp,login_id];
        
        [db executeUpdate:sqlINSERT];
    }
    
    returnValue = [db commit];
    
    
    
    
    return returnValue;
    
}
-(NSDictionary*)getManager:(NSString*)row_guid
{
    NSDictionary* entry = nil;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id,row_guid,row_timestamp,email_address,first_name,last_name FROM managers WHERE row_guid = '%@' AND deleted = 0  LIMIT 1",row_guid];
    
    FMResultSet *rs = [self.serverDB executeQuery:sql];
    
    if ([rs next])
    {
        NSString *ID = [rs stringForColumnIndex:[rs columnIndexForName:@"id"]];
        NSString *row_guid = [rs stringForColumnIndex:[rs columnIndexForName:@"row_guid"]];
        NSString *row_timestamp = [rs stringForColumnIndex:[rs columnIndexForName:@"row_timestamp"]];
        NSString *email_address = [rs stringForColumnIndex:[rs columnIndexForName:@"email_address"]];
        NSString *first_name = [rs stringForColumnIndex:[rs columnIndexForName:@"first_name"]];
        NSString *last_name = [rs stringForColumnIndex:[rs columnIndexForName:@"last_name"]];
        
        
        NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:1];
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
@end
