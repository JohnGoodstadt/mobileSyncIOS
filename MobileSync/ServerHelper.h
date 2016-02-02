//
//  ServerLibrary.h
//  MobileSync
//
//  Created by john goodstadt on 10/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@interface ServerHelper : NSObject
#pragma mark helper functions
+ (NSString *)databasePath;
- (void)addServerDomainTablesIfNecessary;
-(void)createDB;
-(void)attachDB;
- (void)deleteDB;

#pragma mark Server Endpoints
-(NSString*)UPDATEServer:(NSString*)json;
-(NSString*)refreshByDomainObsolete:(NSString*)domain client_timestamp:(NSString *)client_timestamp;
-(NSString*)refreshByDomain:(NSString*)domain client_timestamp:(NSString*)client_timestamp tableTimeStamps:(NSArray*)table_time_stamps;
-(void)addOneEmployee:(NSString*)useDomain;

/**
 
 LoginToBackEnd
 
 @param json  JSON encoding device_guid,login_id and domain of the user
 
 */
-(NSString*)LoginToBackEnd:(NSString*)json;

-(NSArray*)getEmployees;
-(NSArray*)getDomains;
-(void)createDBIfNecessary;
-(void)getServerTime;
+ (NSString*)stringFromDate:(NSDate*)Date andFormat:(NSString*)format;
+(NSDate*)DateFromDB:(NSString*)dbdate;
-(int)getHighestEmployeeNumber;
-(int)getHighestManagerNumber;
+(BOOL)UpdateOrInsertEmployee:(FMDatabase*)db domain_guid:(NSString*)domain_guid row:(NSDictionary*) row;
-(NSDictionary*)getManager:(NSString*)row_guid;
@end
