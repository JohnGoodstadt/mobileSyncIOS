//
//  LoginToServerWebservice.h
//  MobileSync
//
//  Created by john goodstadt on 16/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AccountHandlingWebserviceDelegate <NSObject>
-(void)AccountHandlingWebserviceResponse:(NSString*)server_time domain_id:(NSString*)domain_id;
-(void)AccountHandlingWebserviceFailWithError:(NSError *)error andResponse:(NSHTTPURLResponse*)response;
@end


/*
 
 Use this class to Logout and Login of the back end server
 
 */
@interface AccountHandlingWebservice : NSObject


@property(strong,nonatomic) id<AccountHandlingWebserviceDelegate> delegate;

/**
 
 CallLogin
 
 @param domain_guid      Main identifier for the hardware device
 @param device_guid Unique guid for the device
 @param login_id    Any string defined by the application that represents the user
 
 */
- (void)CallLogin:(NSString*)domain_guid device_guid:(NSString*)device_guid login_id:(NSString*)login_id;
/**
 
 CallLogin
 
 @param domain_guid      Main identifier for the hardware device
 @param device_guid Unique guid for the device
 @param login_id    Any string defined by the application that represents the user
 
 */
- (void)CallLogout:(NSString*)domain;
@end
