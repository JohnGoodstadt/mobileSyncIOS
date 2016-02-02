//
//  FMDBBaseClass.m
//  MobileSync
//
//  Created by john goodstadt on 07/12/2015.
//  Copyright © 2015 john goodstadt. All rights reserved.
//

#import "FMDBBaseClass.h"
#import "MobileHelper.h"
#import "ServerHelper.h"

static NSString *const mobileDatabasePath = @"/mobile1.db";
static NSString *const mobile2DatabasePath = @"/mobile2.db";
static NSString *const mobile3DatabasePath = @"/mobile3.db";

@interface FMDBBaseClass ()

//@property (strong, nonatomic) FMDatabase *serverDB; //only local access.
@property (strong, nonatomic) ServerHelper* serverLibrary; //helper library for hiding  backend server


@end

@implementation FMDBBaseClass

- (void)setUp
{
    [super setUp];
    
    self.serverLibrary = [[ServerHelper alloc] init];
    [self.serverLibrary createDB]; //Create remote DB

    [self deleteDB]; //clear down previous DB
    
    NSString* mobilePath = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobileDatabasePath];
    
    self.db1 = [FMDatabase databaseWithPath:mobilePath];

    [self.db1 open];
    
    XCTAssertTrue([self.db1 open], @"Wasn't able to open mobile database");
   
    //second device
    NSString* mobile2Path = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobile2DatabasePath];
    
    self.db2 = [FMDatabase databaseWithPath:mobile2Path];
    
    [self.db2 open];
    
    XCTAssertTrue([self.db2 open], @"Wasn't able to open mobile database");
   
    
    //third device
    NSString* mobile3Path = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobile3DatabasePath];
    
    self.db3 = [FMDatabase databaseWithPath:mobile3Path];
    
    [self.db3 open];
    
    XCTAssertTrue([self.db3 open], @"Wasn't able to open mobile database");

    
    
    
    
   
    
}


- (void)tearDown
{
    [super tearDown];
    
    [self.db1 close];
    [self.db2 close];
    [self.db3 close];
   
    self.serverLibrary = nil;
    
}

- (NSString *)databasePath
{
    return mobileDatabasePath;
}
- (void)deleteDB
{
    @try {
        
        NSError* error;
        NSString* mobilePath = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobileDatabasePath];
        [[NSFileManager defaultManager] removeItemAtPath: mobilePath error:&error];
       
        
        NSString* mobile2Path = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobile2DatabasePath];
        [[NSFileManager defaultManager] removeItemAtPath: mobile2Path error:&error];
       
        NSString* mobile3Path = [[MobileHelper applicationDocumentsDirectory] stringByAppendingPathComponent:mobile3DatabasePath];
        [[NSFileManager defaultManager] removeItemAtPath: mobile3Path error:&error];
        
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@ %@",exception.name,exception.reason);
    }
}

@end
