//
//  main.m
//  ebvkapi_testapp
//
//  Created by eric_bro on 11.12.11.

#import <Foundation/Foundation.h>
#import <EBVKAPI/EBVKAPI.h>

#define APP_ID        @"2714525"
#define USER_EMAIL    @""
#define USER_PASSWORD @""

int main (int argc, const char * argv[])
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    EBVKAPIToken *token = [[EBVKAPIToken alloc] initWithEmail: USER_EMAIL 
                                                     password: USER_PASSWORD 
                                                applicationID: APP_ID 
                                                       rights: 0  
                                                        error: &error];
    if (!token) {
        NSLog(@"Unable to logon. Reason:");
        NSLog(@"%@", [error localizedDescription]);
        [pool drain];
        return -1;
    }
    
    EBVKAPIRequest *request = [[EBVKAPIRequest alloc] initWithMethodName: @"getUserInfo" 
                                                              parameters: nil	 
                                                          responseFormat: EBJSONFormat];
    BOOL everythingisok = NO;
    NSLog(@"Request using a callback block");
    everythingisok =  [request sendRequestWithToken: token 
                                       asynchronous: NO 
                                   andCallbackBlock:^(NSDictionary *server_response, NSError *error) {
                                       if (server_response) {
                                           NSLog(@"Username is:%@\n", 
                                                 [server_response objectForKey: @"user_name"]);
                                       } else {
                                           NSLog(@"Request error:%@\n", [error localizedDescription]);
                                       }
                                   }];
    if (!everythingisok) {
        /* Do some stuff we can't doing in a block 
         (e.g. use `goto`, some memory management and so on);
         */
    } 
    everythingisok = NO;
    NSLog(@"Request using the EBVKAPIResponse");
    EBVKAPIResponse *response = [[EBVKAPIResponse alloc] init];
    response = [request sendRequestWithToken: token];
    if (response) {
        if (response.response) {
            NSLog(@"Username is:%@\n", [response.response objectForKey: @"user_name"]);
        } else {
            NSLog(@"Request error:%@\n", [response.error localizedDescription]);
        }
    }
    
    [token release];
    [pool drain];
    return 0;
}
