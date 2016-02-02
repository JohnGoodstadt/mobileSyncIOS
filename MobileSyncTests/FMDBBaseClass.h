//
//  FMDBBaseClass.h
//  MobileSync
//
//  Created by john goodstadt on 07/12/2015.
//  Copyright © 2015 john goodstadt. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@protocol FMDBBaseClass <NSObject>

@optional
+ (void)populateDatabase:(FMDatabase *)database;

@end

@interface FMDBBaseClass : XCTestCase <FMDBBaseClass>

@property (strong, nonatomic)  FMDatabase *db1;
@property (strong, nonatomic)  FMDatabase *db2;
@property (strong, nonatomic)  FMDatabase *db3;
//@property (readonly) NSString *databasePath;

//-(void)insertIntoServer;
@end
