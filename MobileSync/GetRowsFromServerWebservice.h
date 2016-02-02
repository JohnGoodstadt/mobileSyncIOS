//
//  WSGetEmployeesFromServer.h
//  MobileSync
//
//  Created by john goodstadt on 09/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GetRowsFromServerWebserviceDelegate <NSObject>
-(void)GetRowsFromServerWebserviceResponse:(NSDictionary*)package;
-(void)GetRowsFromServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response;
@end

@interface GetRowsFromServerWebservice : NSObject

@property(strong,nonatomic) id<GetRowsFromServerWebserviceDelegate> delegate;
/**
 
 refresh
 
 @param domain      Main identifier for the hardware device
 @param client_timestamp  Local device time
 @param tableTimeStamps Array of timestamps - one for each table to refresh

 
 */
- (void)refresh:(NSString*)domain  client_timestamp:(NSString*)client_timestamp tableTimeStamps:(NSArray*)table_time_stamps;
@end
