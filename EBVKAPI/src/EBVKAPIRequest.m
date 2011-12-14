//
//  EBVKAPIRequest.m
//

#import "EBVKAPIRequest.h"
#include "common.h" /* for check_params() */

#define kVKAPIVersion @"3.0"

@interface EBVKAPIRequest (Private)

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token;
- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret;
- (void)runCallbackBlockWithResponseData:(NSData*)data andError:(NSError*)error;
@end


@implementation EBVKAPIRequest
@synthesize  parameters = _method_params, methodName = _method_name, format = _method_response_format;

- (NSString *)composeSigFromMid:(NSString *)mid parameters:(NSDictionary *)parameters andSecret:(NSString *)secret
{
    if ( ! check_params(mid, parameters, secret, EBNULL)) return nil;
    NSMutableString *sig = [NSMutableString stringWithString: mid];
#if NS_BLOCKS_AVAILABLE    
    [[[parameters allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] 
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         [sig appendFormat:@"%@=%@", obj, [parameters valueForKey: obj]];
     }];
#else    
    NSArray *sorted_params_keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (id obj in sorted_params_keys) {
        [sig appendFormat:@"%@=%@", obj, [parameters valueForKey: obj]];
    }
#endif    
    [sig appendFormat:@"%@", secret];
    sig = [NSMutableString stringWithString: [NSString stringWithMD5Hash: sig]];
    return sig;
}




- (id)init
{
    if ((self=[super init])) {
     	_method_name = nil;
        _method_params = nil;
        _method_response_format = EBJSONFormat;
    } else self = nil;
    
    return self;
}


- (id)initWithMethodName:(NSString *)name parameters:(NSDictionary *)params responseFormat:(enum EBVKAPIResponseFormat)response_format
{    
    if ( ! check_params(name, EBNULL)) {
        return (self = nil, self);
    }
    if ((self = [super init])) {
        _method_name = [name copy];
        _method_params = params ? [[NSMutableDictionary alloc] initWithDictionary: params] : nil;
        _method_response_format = response_format;
        
    } else self = nil;
    
    return self;
}

- (void)dealloc
{
    [_method_params release], _method_params = nil;
    [super dealloc];
}

- (NSURLRequest *)requestForToken:(EBVKAPIToken *)token
{    
    NSMutableString *request_body = [[NSMutableString alloc] init];
    NSString *sig = @"";
    if (!_method_params) _method_params = [[NSMutableDictionary alloc] init];
    [_method_params setValue: token.appID forKey: @"api_id"];
    [_method_params setValue: _method_response_format == EBXMLFormat ? @"XML" : @"JSON" forKey: @"format"];
    [_method_params setValue: kVKAPIVersion forKey: @"v"]; /* VK API version */
    [_method_params setValue: _method_name forKey: @"method"];
    
    sig = [self composeSigFromMid: token.mid parameters: _method_params andSecret: token.secret];
#if NS_BLOCKS_AVAILABLE    
    [_method_params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ( [obj isKindOfClass: NSClassFromString(@"NSNumber")]) {
            [_method_params setObject: [obj stringValue] forKey: key];
            obj = [_method_params objectForKey: key];
        }
        [request_body appendFormat: @"&%@=%@", key, [obj stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];  
    }];   
#else        
    for (id key in [_method_params allKeys]) {
        if ( [[_method_params objectForKey: key] isKindOfClass: NSClassFromString(@"NSNumber")]) {
            [_method_params setObject: [[_method_params objectForKey: key] stringValue] forKey: key];
        }
        [request_body appendFormat: @"&%@=%@", key, 
         [[_method_params objectForKey: key] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    }
#endif
    /* Delete first '&' character */
    [request_body deleteCharactersInRange: NSMakeRange(0, 1)]; 
    
    [request_body appendFormat: @"&sid=%@&sig=%@", token.sid, sig];
    NSURL *request_url = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.vk.com/api.php?%@", request_body]];
    [request_body release], request_body = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: request_url];
    [request setHTTPShouldHandleCookies: NO]; 
    NSString *custom_user_agent = kVKAPIUserAgentString;
    [request setValue: custom_user_agent  forHTTPHeaderField: @"User-Agent"];
    [request setAllHTTPHeaderFields: [NSHTTPCookie requestHeaderFieldsWithCookies: [token cookies]]];
    
    return [(NSURLRequest*)request autorelease];
}


- (void)runCallbackBlockWithResponseData:(NSData*)data andError:(NSError*)error
{
    if (!_callback_block) {
        @throw [NSException exceptionWithName:@"There isn't a callback block" reason:@"" userInfo: nil]; 
        return;
    }
    if (!data) {
        _callback_block(nil, error);
    } else {
        switch (_method_response_format) {
            case EBXMLFormat: {
                TBXML *tbxml = [TBXML tbxmlWithXMLData: data];
                _callback_block([tbxml dictionaryRepresentation], nil);
            }
                break;
            case EBJSONFormat: {
                _callback_block([[[JSONDecoder decoder] parseJSONData: data] objectForKey: @"response"], nil);
            }
                break;
                /* EBSimpleTextFormat */
            default:
                _callback_block([NSDictionary dictionaryWithObject: 
                                [[[NSString alloc] initWithData: data 
                                                       encoding: NSUTF8StringEncoding] autorelease] 
                                                           forKey: @"response"], nil);
                break;
        }
    }
    Block_release(_callback_block);
}

- (BOOL)sendRequestWithToken: (EBVKAPIToken *)token asynchronous: (BOOL)asynchronous andCallbackBlock: (EBVKAPICallbackBlock)a_callback_block
{
    if ( ! check_params(token.secret, token.mid, token.sid, EBNULL)) {
        goto err_exit;
    }
    _callback_block = Block_copy(a_callback_block);
    
    if (asynchronous) {
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: [self requestForToken: token] 
                                                                      delegate: self 
                                                              startImmediately: NO];
        if (connection) {
            [connection start];
            return YES; 
        } else {
            Block_release(_callback_block);
           return NO; 
        }
    } else {
        NSError *tmp_error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                             returningResponse: nil 
                                                         error: &tmp_error];
        [self runCallbackBlockWithResponseData: data andError: tmp_error];
        return (data != nil);
    }
    
    
err_exit:
    a_callback_block(nil, [NSError errorWithDomain:@"_ebvkapirequestdomain" code: -1 userInfo: nil]);
    return NO;
}

- (EBVKAPIResponse *)sendRequestWithToken:(EBVKAPIToken *)token
{
    if ( ! check_params(token.secret, token.mid, token.sid, EBNULL)) {
        goto err_exit;
    }
    
    NSError *tmp_error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest: [self requestForToken: token] 
                                         returningResponse: nil 
                                                     error: &tmp_error];
    if (!data) {
        return [EBVKAPIResponse responseWithResponse: nil andError: tmp_error];
    } else {
        switch (_method_response_format) {
            case EBXMLFormat: {
                TBXML *tbxml = [TBXML tbxmlWithXMLData: data];
                return  [EBVKAPIResponse responseWithResponse: [tbxml dictionaryRepresentation] 
                                                     andError: nil];  
            }
            case EBJSONFormat: {
                return [EBVKAPIResponse responseWithResponse: [[[JSONDecoder decoder] parseJSONData: data] objectForKey:@"response"] 
                                                    andError: nil];
            }
            /* EBSimpleTextFormat */
            default:
                return [EBVKAPIResponse responseWithResponse: 
                    [NSDictionary dictionaryWithObject: [[[NSString alloc] initWithData: data 
                                                                               encoding: NSUTF8StringEncoding] 
                                                         autorelease] 
                                                forKey: @"response"] 
                                                    andError: nil];
        }
    }
err_exit:
    return nil;
}


#pragma mark NSURLConnection delegate's
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!_connection_data) {
        _connection_data = [[NSMutableData alloc] initWithData: data];
        return;
    }
    [_connection_data appendData: data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!_connection_data) {
        NSError *error = [NSError errorWithDomain: @"_ebvkapidomain" code:1 userInfo:
                          [NSDictionary dictionaryWithObject: @"No data has been received from an API server. Try again." 
                                                      forKey: NSLocalizedDescriptionKey]];
        [self runCallbackBlockWithResponseData: nil andError: error];
    } 
    [self runCallbackBlockWithResponseData: _connection_data andError: nil];
    [_connection_data release];
    [connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_connection_data release];
    [self runCallbackBlockWithResponseData: nil andError: error];
}



#pragma mark Cookies work

+ (NSArray *)dumpAllCookiesForDomain:(NSString *)domain
{    
    NSArray *all_cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
#if NS_BLOCKS_AVAILABLE
    return  [all_cookies objectsAtIndexes: [all_cookies indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(NSHTTPCookie*)obj domain] isEqualToString: domain]) {
            return YES;
        } else return NO;
    }]];
#else
    NSMutableIndexSet *indexses = [[[NSMutableIndexSet alloc] init] autorelease];
    NSUInteger idx = 0;
    for (id obj in all_cookies) {
        if ([[(NSHTTPCookie*)obj domain] isEqualToString: domain]) {
        	[indexses addIndex: idx];
        }
        idx++;
    }
    return ([all_cookies objectsAtIndexes: indexses]);
#endif
    
}

+ (void)setCookies:(NSArray *)new_cookies forDomain:(NSString *)domain
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies: new_cookies 
                                                        /* We have to append the $domain string with "http://", because it'll be an URL */
                                                       forURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://%@", domain]] 
                                              mainDocumentURL: nil];
}


+ (void)cleanUpAllCookiesForDomain:(NSString *)domain
{
    NSHTTPCookieStorage *shared_storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
#if NS_BLOCKS_AVAILABLE
    [[shared_storage cookies] enumerateObjectsUsingBlock:^(NSHTTPCookie *cookie, NSUInteger idx, BOOL *stop) {
        if ([[cookie domain] isEqualToString: domain]) {
            [shared_storage deleteCookie:cookie];
        }
    }];
#else
    for (NSHTTPCookie *cookie in [shared_storage cookies]) {
        if ([[cookie domain] isEqualToString: domain]) {
            [shared_storage deleteCookie:cookie];
        }
	}
#endif
}

@end
