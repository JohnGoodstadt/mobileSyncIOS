//
//  MobileHelper.h
//  MobileSync
//
//  Created by john goodstadt on 09/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>


#define USER_LOGIN_ID @"user@hotmail.com"


@class FMDatabase;
@interface MobileHelper : NSObject

+ (NSString*)stringFromDate:(NSDate*)Date andFormat:(NSString*)format;
+ (NSString *)applicationDocumentsDirectory;
+(NSDictionary*)convertJSONToDictionary:(NSString*)json;
+(BOOL)fileExistsInDocuments:(NSString*)filename;

#pragma mark SQL Routines
+ (void)AddSystemTablesIfNecessary:(FMDatabase*)db;
+ (void)AddPayloadTablesIfNecessary:(FMDatabase*)db;
+ (void)populatePayloadTables:(FMDatabase*)db;
+ (NSString*)getDomainID:(FMDatabase*)db;
+ (NSArray*)getDirtyDomainFromDB:(FMDatabase*)db;
+ (void)logicallyDeleteEmployee:(FMDatabase*)db email_address:(NSString*)email_address;
+(void)logicallyDeleteManager:(FMDatabase*)db row_guid:(NSString*)row_guid;
+ (NSArray*)getDirtyEmployeesFromDB:(FMDatabase*)db;
+ (NSArray*)getDirtyManagersFromDB:(FMDatabase*)db;
+ (void)updateSentToServerOKDB:(FMDatabase*)db rows:(NSArray *)rows;
+(void)updateSentToServerOKDB:(FMDatabase*)db tables:(NSArray *)tables;
//+ (void)updateServerTimeStamp:(FMDatabase*)db time_stamp:(NSString *)time_stamp;
+ (NSArray*)getEmployees:(FMDatabase*)db;
+ (NSString*)getServer_timeObsolete:(FMDatabase*)db;
+(void)INSERTEmployee:(FMDatabase*)db first_name:(NSString*)first_name last_name:(NSString*)last_name manager_id:(NSString*)manager_id;
+(void)INSERTManager:(FMDatabase*)db first_name:(NSString*)first_name last_name:(NSString*)last_name;
+(void)updateLogin:(FMDatabase*)db login_id:(NSString*)login_id;
+(void)updateLogin:(FMDatabase*)db login_id:(NSString*)login_id domain_guid:(NSString*)domain_guid;
+(void)RemoveAllData:(FMDatabase*)db;
+(void)ChangeDomains:(FMDatabase*)db withDomain:(NSString*)domain_id;
+(BOOL)isUserLoggedIn:(FMDatabase*)db;
+(NSString*)getLastEmployee_time:(FMDatabase*)db;
+(NSArray*)getManagers:(FMDatabase*)db;
+(void)assignManagerToEmployee:(FMDatabase*)db employee_row_guid:(NSString*)employee_row_guid manager_row_guid:(NSString*)manager_row_guid;
+(NSDictionary*)getManager:(FMDatabase*)db row_guid:(NSString*)row_guid;
+(NSString*)getLastManager_time:(FMDatabase*)db;
+(NSString*)manager_email_address:(FMDatabase*)db  manager_guid:(NSString*)manager_guid;
+(void)addNewManager:(FMDatabase*)db;
+(NSDate*)DateFromDB:(NSString*)dbdate;
+(BOOL)areDBsIdentical:(FMDatabase*)db1 secondDB:(FMDatabase*)db2;
+(BOOL)UpdateOrInsertEmployeeByRow_id:(FMDatabase*)db sentTOServerOK:(int)sentTOServerOK row:(NSDictionary*) row;
+(BOOL)UpdateAndReinsertRows:(FMDatabase*)db  clashed_rows:(NSArray*)clashed_rows new_rows:(NSArray*) new_rows;
+(BOOL)UpdateOrInsertManagerByRow_id:(FMDatabase*)db sentTOServerOK:(int)sentTOServerOK  row:(NSDictionary*) row;
+(NSMutableDictionary*)getEmployee:(FMDatabase*)db row_guid:(NSString*)row_guid;
+(void)saveEmployee:(FMDatabase*)db row_guid:(NSString*)row_guid   firstName:(NSString*)firstName last_name:(NSString*)last_name email_address:(NSString*)email_address;
@end
