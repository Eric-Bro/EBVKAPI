//
//  main.m
//  ebvkapi_testapp
//
//  Created by eric_bro on 11.12.11.

#import <Foundation/Foundation.h>
#import <EBVKAPI/EBVKAPI.h>

#define APP_ID        @"2719681"
#define USER_EMAIL    @""
#define USER_PASSWORD @""

int main (int argc, const char * argv[])
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    
    int settings = EBSettingsStatusAccess | EBSettingsAllowNotifications;
    EBVKAPIToken *token = [[EBVKAPIToken alloc] initWithEmail: USER_EMAIL 
                                                     password: USER_PASSWORD 
                                                applicationID: APP_ID 
                                                       settings: settings
                                                        error: &error];
    if (!token) {
        NSLog(@"Unable to log on. Reason:");
        NSLog(@"%@", [error localizedDescription]);
        [pool drain];
        return -1;
    }
    [NSThread sleepForTimeInterval: 2];
    
    EBVKAPIRequest *request = [[EBVKAPIRequest alloc] initWithMethodName: @"getUserInfo" 
                                                              parameters: nil	 
                                                          responseFormat: EBJSONFormat];
    BOOL everythingisok = NO;
    everythingisok =  [request sendRequestWithToken: token 
                                       asynchronous: YES 
                                   andCallbackBlock: ^(NSDictionary *server_response, NSError *error) {
                                       if (server_response) {
                                           if ([server_response objectForKey:@"response"]) {
                                               NSLog(@"[FIRST ACYNC] response: %@\n (UserName)", 
                                                     [[server_response objectForKey:@"response"] objectForKey: @"user_name"]);
                                           } else {
                                               NSLog(@"[FIRST ACYNC]: API server error : %@",
                                                     [server_response objectForKey: @"error"]);
                                           }
                                       } else {
                                           NSLog(@"[FIRST ACYNC] internal EBVKAPI error :%@\n", [error description]);
                                       }
                                   }];
    if (!everythingisok) {
        /* Do some stuff we can't doing in a block 
         (e.g. use `goto`, some memory management and so on);
         */
        NSLog(@" :`( ");
    } 
    
    [request setMethodName: @"status.get"];
    [request setParameters: nil];
    everythingisok = [request sendRequestWithToken: token 
                                            asynchronous: YES 
                                        andCallbackBlock: ^(NSDictionary *server_response, NSError *error) {
                                            if (server_response) {
                                                if ([server_response objectForKey:@"response"]) {
                                                    NSLog(@"[SECOND ACYNC] response: %@\n (Status)", 
                                                        [[server_response objectForKey:@"response"] valueForKey: @"text"]);
                                                } else {
                                                    NSLog(@"[SECOND ACYNC]: API server error : %@",
                                                          [[server_response objectForKey: @"error"] valueForKey: @"error_msg"]);
                                                }
                                            } else {
                                                NSLog(@"[SECOND ACYNC] internal EBVKAPI error :%@\n", [error description]);
                                            }
                                        }];   
    

    [request setMethodName: @"getUserInfoEx"];
    EBVKAPIResponse *response = [[EBVKAPIResponse alloc] init];
    response = [request sendRequestWithToken: token];
    if (response) {
        if (response.response) {
            if ([response.response objectForKey:@"response"]) {
                NSLog(@"[SECOND] response: %@ (UserPic)\n", 
                      [[response.response objectForKey:@"response"] objectForKey: @"user_photo"]);
            } else {
                NSLog(@"[SECOND]: API server error : %@",
                      [response.response objectForKey: @"error"]);
            }
        } else {
            NSLog(@"[SECOND] internal EBVKAPI error :%@\n", [response.error localizedDescription]);
        }
    }
    /* Prevents an app to exit before async requests will be completed */
    while (request.operationCount > 0) { /*_*/ }
    
    [token release];
    [pool drain];
    return 0;
}
