//
//  LoginToServerWebservice.m
//  MobileSync
//
//  Created by john goodstadt on 16/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "AccountHandlingWebservice.h"
#import "MobileHelper.h"
#import "ServerHelper.h"

/**
 
 @class AccountHandlingWebservice 888
 
 
 @discussion Use this class to Logout and Login of the back end server
 
 */
@implementation AccountHandlingWebservice


- (void)CallLogin:(NSString*)domain_guid  device_guid:(NSString*)device_guid login_id:(NSString*)login_id
{
    if(_delegate){
        
        if ([_delegate respondsToSelector:@selector(AccountHandlingWebserviceResponse:domain_id:)]) {
            
            NSDictionary* d = @{@"domain_guid":domain_guid,@"device_guid":device_guid,@"login_id":login_id};
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d
                                                               options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                                 error:&error];
            
            if (! jsonData)
            {
                NSLog(@"Got an error: %@", error);
                [_delegate AccountHandlingWebserviceFailWithError:error andResponse:nil];
            }
            else
            {
                
                
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                NSLog(@"%@",jsonString);
                //BACK END DB CALLS
                
                /*
                 Start - Call Backend Here
                 */
                
                //Instead of calling backend server just update local proxy
                ServerHelper* serverLibrary = [[ServerHelper alloc] init];
                NSString* domain_guid = [serverLibrary LoginToBackEnd:jsonString];
                
                
                NSString* server_time = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                /*
                 End  - Call Backend Here
                 */
                
                
                
                
                [_delegate AccountHandlingWebserviceResponse:server_time domain_id:domain_guid];
            }
            
            
        }
        
        
    }

}
- (void)CallLogout:(NSString*)domain_guid{
    if(_delegate){
        
        if ([_delegate respondsToSelector:@selector(AccountHandlingWebserviceResponse:domain_id:)]) {
            
            NSDictionary* d = @{@"domain_guid":domain_guid};
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d
                                                               options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                                 error:&error];
            
            if (! jsonData)
            {
                NSLog(@"Got an error: %@", error);
                [_delegate AccountHandlingWebserviceFailWithError:error andResponse:nil];
            }
            else
            {
                
                
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                NSLog(@"%@",jsonString);
                //BACK END DB CALLS
                
                /*
                 Start - Call Backend Here
                 */
                
                //Instead of calling backend server just update local proxy
                ServerHelper* serverLibrary = [[ServerHelper alloc] init];
                NSString* domain_id = [serverLibrary LoginToBackEnd:jsonString];
                
                
                NSString* server_time = [MobileHelper stringFromDate:[NSDate date] andFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                /*
                 End  - Call Backend Here
                 */
                
                
                
                
                [_delegate AccountHandlingWebserviceResponse:server_time domain_id:domain_id];
            }
            
            
        }
        
        
    }

}
@end
