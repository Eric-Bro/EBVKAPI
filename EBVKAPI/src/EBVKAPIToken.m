//
//  EBVKAPIToken.m
//


#import "EBVKAPIToken.h"
#import "EBVKAPICookies.h"
#import "JSONKit.h"
#include "common_utils.h"
#import "NSString+EB.h"

#define SETTINGS_HASH__WRONG_MASK @"var app_settings_hash = \'\';"

#define flag(x,y) (((y) & (x)) == (x))

enum EBVKAPITokenStatus {
    EBVKAPITokenSuccess,
    EBVKAPITokenWrongCredentials,
    EBVKAPITokenConnectionError,
    EBVKAPITokenParsingError,
    EBVKAPITokenUnknowingError,
}EBVKAPITokenStatus;

static void GetNSErrorFromCode(int code, NSError **error);

static void GetNSErrorFromCode(int code, NSError **error)
{
    if (error == NULL) return;
    
    NSString *reason = @"EBVKAPIToken error: unknown error";
    switch (code) {
        case EBVKAPITokenParsingError:
             reason = @"EBVKAPIToken error: parsing error (wrong method's parameters or wrong session vars)";
             break;
        case EBVKAPITokenConnectionError:
             reason = @"EBVKAPIToken error: connection error (error while connecting to an API server)";
             break;
        case EBVKAPITokenWrongCredentials:
             reason = @"EBVKAPIToken error: credentials error (wrong email and/or password)";
             break;
        case EBVKAPITokenSuccess:
             reason = @"EBVKAPIToken error: everything seems to be OK (...)";
             break;
        default:
             reason = @"EBVKAPIToken error: unknown reason";
    }
    NSDictionary *error_details = [NSDictionary dictionaryWithObject: reason forKey: NSLocalizedDescriptionKey];
    *error = [[[NSError alloc] initWithDomain: @"_ebvkapitokendomain" code: code userInfo: error_details] autorelease];
}



@interface EBVKAPIToken (Private)
- (void)parseSessionVarsFromData:(NSData *)data;
@end

@implementation EBVKAPIToken
@synthesize sid = _sid, mid = _mid, secret = _secret, expire = _expire, appID = _appid;
@synthesize status = _stat, cookies = _cookies;


+ (id)tokenWithEmail: (NSString *)email 
            password: (NSString *)password
       applicationID: (NSString *)app_id 
            settings: (NSInteger)settings 
            getError: (NSError **)error
{
    return [[[[self class] alloc] initWithEmail: email password: password applicationID: app_id settings: settings getError: error] autorelease];
}


- (id)initWithEmail: (NSString *)email 
           password: (NSString *)password 
      applicationID: (NSString *)app_id
           settings: (NSInteger)settings 
           getError: (NSError **)error
{
    if ((self = [super init])) {
        if ( ! check_for_nil(email, password, app_id, EBNULL)) {
            GetNSErrorFromCode(EBVKAPITokenParsingError, error);
            goto err_exit;
        }
        NSRange nonDigitsRange = [app_id rangeOfCharacterFromSet:
                                  [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        if (nonDigitsRange.location != NSNotFound || !app_id) {
            /* Wrong app_id */
            GetNSErrorFromCode(EBVKAPITokenParsingError, error);
            goto err_exit;
        }
        if (!settings) settings = 16383; /* Some 'random' number here, haha :-) */
        
        
        NSError *tmp_error = nil;
        NSData  *data  = nil;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

        /* First of all - sending an empty request for some cookies */
        NSURL *api_server_url = [NSURL URLWithString:[NSString stringWithFormat: 
                                  @"http://vk.com/login.php?email=%@&pass=%@&m=1", email, password]];
        [request setURL: api_server_url];
        
        /* Backup old cookies and delete them all */
        NSArray *old_cookies = [EBVKAPICookies dumpAllCookiesForDomain: @".vk.com"];
        [EBVKAPICookies cleanUpAllCookiesForDomain: @".vk.com"]; 

        [request setHTTPShouldHandleCookies: YES];
        
        data = [NSURLConnection sendSynchronousRequest: request
                                     returningResponse: nil /* We don't need for response now */
                                                 error: &tmp_error];
        if (!data) {
            NSLog(@"[Error while NSURLConnection work. Description: %@]", [tmp_error description]);
            GetNSErrorFromCode(EBVKAPITokenConnectionError, error);
            [request release];
            goto err_exit;
        }
        data = nil;
        
        api_server_url = [NSURL URLWithString: 
                          [NSString stringWithFormat:@"http://vk.com/login.php?app=%@&layout=popup&settings=%i&type=browser",
                            app_id, settings]];
        tmp_error = nil;
        [request setURL: api_server_url];
        NSURLResponse *rs = nil;
        data = [NSURLConnection sendSynchronousRequest: request
                                     returningResponse: &rs 
                                                 error: &tmp_error];
        if (!data) {
            NSLog(@"[Error while NSURLConnection work. Description: %@]", [tmp_error description]);
            GetNSErrorFromCode(EBVKAPITokenConnectionError, error);
            [request release];
            goto err_exit;
        }
    
        /* If the app already has a required settings' set - parse session vars from URI link */
        if ([[[rs URL] absoluteString] hasPrefix: @"http://vk.com/api/login_success.html#"]) {
           NSString *raw_values = [[[rs URL] absoluteString] stringByReplacingOccurrencesOfString: @"http://vk.com/api/login_success.html#session=" 
                                                                                       withString: @""];
            raw_values = [raw_values stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
            [self parseSessionVarsFromData: [raw_values dataUsingEncoding: NSUTF8StringEncoding]];
            _appid = app_id;
            if ( ! check_for_nil(_sid, _mid, _secret, _expire, EBNULL)) {
                GetNSErrorFromCode(EBVKAPITokenParsingError, error);
                goto err_exit;
            }

        } else {
            /* else - save new settings */
            
            NSString *login_page_html_code = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
            if ([login_page_html_code rangeOfString: SETTINGS_HASH__WRONG_MASK].location != NSNotFound) {
                /* Wrong password and/or email */
                GetNSErrorFromCode(EBVKAPITokenWrongCredentials, error);

                [request release];
                [login_page_html_code release];
                goto err_exit;   
            }
            
            NSString *auth_hash = [login_page_html_code stringBetweenString: @"var auth_hash = \'" andString: @"\';"];
            NSString *settings_hash = [login_page_html_code stringBetweenString:@"var app_settings_hash = \'" andString:@"\';"];
            [login_page_html_code release];
            
            /* Use $auth_hash to let our app log in */
            tmp_error = nil;
            api_server_url = [NSURL URLWithString: [NSString stringWithFormat: 
                                                    @"http://vk.com/login.php?act=a_auth&app=%@&hash=%@&permanent=1&vk=", app_id, auth_hash]];
            [request setURL: api_server_url];
            NSHTTPURLResponse *response = nil;
            data = [NSURLConnection sendSynchronousRequest: request
                                         returningResponse: &response 
                                                     error: &tmp_error];            
            if (!data) {
                NSLog(@"[Error while NSURLConnection work. Description: %@]", [tmp_error description]);
                GetNSErrorFromCode(EBVKAPITokenConnectionError, error);
                [request release];
                goto err_exit; 
            }
            [self parseSessionVarsFromData: data];
            
            /* Save our custom app's settings */
            NSMutableString *save_settings_body = [[NSMutableString alloc] initWithString: @"http://vk.com/apps.php?act=a_save_settings"];
            [save_settings_body appendFormat: @"&addMember=1"];
            [save_settings_body appendFormat: @"&hash=%@", settings_hash];
            [save_settings_body appendFormat: @"&id=%@", app_id];
            for (int i = 0; i <= 17; i++) {
                if (flag(1 << i, settings)) {
                    [save_settings_body appendFormat:@"&app_settings_%i=1", 1 << i];
                }
            }
            NSURL *save_url = [NSURL URLWithString: save_settings_body];
            [save_settings_body release];
            [request setHTTPMethod: @"POST"];
            [request setURL: save_url];
            NSData *tmpData = [[NSURLConnection sendSynchronousRequest: request
                                           returningResponse: NULL error: NULL] retain];
            [tmpData release];
           
        }
        
        [request release];
        
        _appid = app_id;
                
        /* Save new cookies */
        _cookies = [[EBVKAPICookies dumpAllCookiesForDomain: @".vk.com"] retain];
               
        /* Restore old cookies */
        [EBVKAPICookies cleanUpAllCookiesForDomain: @".vk.com"];
        [EBVKAPICookies setCookies: old_cookies forDomain: @".vk.com"];
        
        if (!_cookies) {
            goto err_exit;
        }
        
        if ( ! check_for_nil(_sid, _mid, _secret, _expire, EBNULL)) {
            GetNSErrorFromCode(EBVKAPITokenParsingError, error);
            goto err_exit;
        }        
    }

    return self;
    
err_exit:
    return (self=nil, self);
}
/* [FIXED]:
   All tokens' values are prevented from leaking now.
*/
- (void)dealloc
{
    [_sid release], _sid = nil;
    [_mid release], _mid = nil;
    [_secret release], _secret = nil;
    [_expire release], _expire = nil;
    [super dealloc];
}


- (void)parseSessionVarsFromData:(NSData *)data
{
    JSONDecoder *json_decoder = [JSONDecoder decoder];
    NSDictionary *tmp_dict = [[NSDictionary alloc] initWithDictionary: [json_decoder parseJSONData: data]];
    /* We have to -retain all token's ivars for prevent them from auto releasing (e.g. in blocks' scope) */
    _sid    = [[tmp_dict objectForKey: @"sid"] retain];
    /* JSONDecoder will parse this value as CFNumber (NSNumber) so we have to convert it to string representation*/
    _mid    = [[[tmp_dict objectForKey: @"mid"] stringValue] retain]; 
    _secret = [[tmp_dict objectForKey: @"secret"] retain];
    _expire = [[tmp_dict objectForKey: @"expire"] retain];
    [tmp_dict release];
}

@end

