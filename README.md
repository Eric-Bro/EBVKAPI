## About
The EBVKAPI allows you to simplify dealing with the VKontakte social network by sending some requests to an API server.
It's may work in two mods:  

   * block-based  
Supports  callback blocks. Like a:

        [api_request sendRequestWithToken: token   
                                          asynchronous: NO   
                                    andCallbackBlock: ^(NSDictionary *server_response, NSError *error) {  
        if (server_return) {  
            NSLog(@"Step 1. Hello, %@ (id%@)! How you doing?",   
                  [[server_response objectForKey:@"response"]   objectForKey:@"user_name"], token.mid);   
        } else {  
            print_request_error(error, [api_request methodName]);  
        }  
        }];  

   * non-block based (for Mac OS X <  10.6, iOS < 4.0)  
Uses `EBVKAPIResponse` class object to provide a server response. 

version 0.4
2011, eric_bro
eric.broska@me.com

## Examples  
You can take a look at the example application named `ebvkapi_testapp` which just show up a current user's name;
In a header you'll see three `#define`s:
    
    #define APP_ID        @""  
    #define USER_EMAIL    @""  
    #define USER_PASSWORD @""  
Here you have to set your own values. If you haven't got an application ID - don't hesitate to use my `2719681` as well.

## Structure
* __EBVKAPIToken__  
Stores you login information for using with API-requests;    
* __EBVKAPIRequest__
Performs requests to an API server;  
Automatically parse a server response ( in JSON format only, using [`JSONKit`](https://github.com/johnezang/JSONKit)by John Engelhart) to NSDictionary object;  
* __EBVKAPIResponse__  
Simple wrapper-object for a raw server response or error code;    
(using with non-blocks based methods of `EBVKAPIRequest`)    
