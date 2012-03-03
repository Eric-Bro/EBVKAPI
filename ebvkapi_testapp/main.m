//
//  main.m
//  ebvkapi_testapp
//
//  Created by eric_bro on 11.12.11.

#import <Foundation/Foundation.h>
#import <EBVKAPI/EBVKAPI.h>

#define kEBStringSize 255
const NSString *APP_ID = @"2719681";
const NSString *USER_EMAIL = nil;
const NSString *USER_PASSWORD = nil;

void parse_vars(void);

int main (int argc, const char * argv[])
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
    
    parse_vars();

    int settings = EBSettingsStatusAccess | EBSettingsAllowNotifications;
    
    EBVKAPIToken *token = [[EBVKAPIToken alloc] initWithEmail: (NSString *)USER_EMAIL 
                                                     password: (NSString *)USER_PASSWORD 
                                                applicationID: (NSString *)APP_ID 
                                                     settings: settings
                                                     getError: &error];
    if (!token) {
        NSLog(@"Unable to log on: ");
        NSLog(@"%@", [error localizedDescription]);
        [pool drain];
        return (-1);
    }
    
    EBVKAPIRequest *request =[[EBVKAPIRequest alloc] init];
    [request setMethodName: @"audio.search"];
    [request setParameterValue: @"monomate" forKey: @"q"];
    [request setParameterValue: @"20"       forKey: @"count"];
    BOOL ok = [request sendRequestWithToken: token asynchronous: NO callbackBlock:^(EBVKAPIResponse *response) {
        if (response.error) {
            NSLog(@"Error!!\n%@", response.error.description);
        } else {
            NSLog(@"[OK]:\n%@", response.values);
        }
    }];
    if (!ok) {
        NSLog(@"Request '%@' was fail. Sorry, bro.\n(sid = %@)", request.methodName, token.sid);
    }
    [request release];
    [token release];
    
    /* Prevents an app to exit before !async! requests will be completed yet.
       You should use this macro in console applications only.
       --- --- --- --- --- --- --- --- --- --- --- ---
    EBVKAPIWaitUntilAsyncsDone(request);
    */
    
    [pool drain];
    return 0;
}


void parse_vars(void)
{
    char *string = malloc(sizeof(*string) * kEBStringSize);
    printf("Please, enter your VK accaunt's credentials");
    printf("Email: ");
    scanf("%s", string);
    USER_EMAIL = [NSString stringWithUTF8String: string];
    memset(string, '\0', kEBStringSize);
    printf("Password: ");
    scanf("%s", string);
    USER_PASSWORD = [NSString stringWithUTF8String: string];
    free(string);
    /* Yes, it will not work in a XCode's console view, but in the Terminal app it will. */
    system("clear");
}