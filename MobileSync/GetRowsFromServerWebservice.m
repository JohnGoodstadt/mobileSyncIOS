////
//  WSGetEmployeesFromServer.m
//  MobileSync
//
//  Created by john goodstadt on 09/12/2015.
//  Copyright © 2015 John Goodstadt. All rights reserved.
//

#import "GetRowsFromServerWebservice.h"
#import "MobileHelper.h"
#import "ServerHelper.h"

@implementation GetRowsFromServerWebservice

- (void)refresh:(NSString*)domain  client_timestamp:(NSString*)client_timestamp tableTimeStamps:(NSArray*)table_time_stamps{
    
    
    if(_delegate){
        
        if ([_delegate respondsToSelector:@selector(GetRowsFromServerWebserviceResponse:)]) {
            
            //2. package up and send back
            
            
            /*
             Start - Call Backend Here
             */
            
            //Instead of calling backend server just update local proxy
            ServerHelper* serverLibrary = [[ServerHelper alloc] init];
            NSString* json = [serverLibrary refreshByDomain:domain client_timestamp:client_timestamp tableTimeStamps:table_time_stamps]; //json as a string
            
            
            
            
            /*
             End  - Call Backend Here
             */
            
            

            
            
            if (!json)
            {
                [_delegate GetRowsFromServerWebserviceFailWithError:nil andResponse:nil];
            }
            else
            {
                
                NSDictionary *package = [MobileHelper convertJSONToDictionary:json];
     
                
                [_delegate GetRowsFromServerWebserviceResponse:package];
            }
            
            
        }
        
        
    }
    
}



@end
