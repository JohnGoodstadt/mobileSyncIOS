//
//  WebServiceCalls.m
//  MyCarCheck
//
//  Created by john goodstadt on 19/06/2014.
//  Copyright (c) 2014 John Goodstadt. All rights reserved.
//

#import "SendToServerWebservice.h"
#import "MobileHelper.h"
#import "ServerHelper.h"
#include "OpenUDID.h"

@interface SendToServerWebservice ()
@end

@implementation SendToServerWebservice

- (void)call:(NSString*)domain client_timestamp:(NSString*)client_timestamp  device_guid:(NSString*)device_guid  tables:(NSArray*)tables
{
    if(_delegate){
        
        if ([_delegate respondsToSelector:@selector(SendToServerWebserviceResponse:withResponse:)]) {
            
            NSDictionary* d = @{@"domain":domain,@"client_timestamp":client_timestamp,@"device_guid":device_guid,@"tables":tables};
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d
                                                               options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                                 error:&error];
            
            if (! jsonData) {
                NSLog(@"Got an error: %@", error);
                [_delegate SendToServerWebserviceFailWithError:error andResponse:nil];
            } else {
                
                
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                NSLog(@"%@",jsonString);
                
                /*
                 Start - Call Backend Here
                 */
                
                //Instead of calling backend server just update local proxy - to test design pattern
                ServerHelper* serverLibrary = [[ServerHelper alloc] init];
                NSString* jsonResponse = [serverLibrary UPDATEServer:jsonString];
                
                /*
                 End  - Call Backend Here
                 */
                
                
                NSDictionary *package = [MobileHelper convertJSONToDictionary:jsonResponse];
                
                [_delegate SendToServerWebserviceResponse:[tables copy] withResponse:package];
            }
            
            
        }
        
        
    }
}
@end
