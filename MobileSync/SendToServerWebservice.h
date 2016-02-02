//
//  WebServiceCalls.h
//  MyCarCheck
//
//  Created by john goodstadt on 19/06/2014.
//  Copyright (c) 2014 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SendToServerWebserviceDelegate <NSObject>
-(void)SendToServerWebserviceResponse:(NSArray*)tables withResponse:(NSDictionary*)jsonResponse;
-(void)SendToServerWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response;
@end

/*
 Move all server url calls to here for centralizations
 */
@interface SendToServerWebservice : NSObject

@property(strong,nonatomic) id<SendToServerWebserviceDelegate> delegate;

/**
 
 call
 
 @param domain      Main identifier for the hardware device
 @param client_timestamp  Local device time
 @param device_guid Unique guid for the device
 @param tables      Array of tables that have had rows recently added
 
 */
- (void)call:(NSString*)domain client_timestamp:(NSString*)client_timestamp device_guid:(NSString*)device_guid tables:(NSArray*)tables;
@end
