//
//  EBVKAPIResponse.m
//  


#import "EBVKAPIResponse.h"

@interface EBVKAPIResponse (Private)
/* */
@end

@implementation EBVKAPIResponse
@synthesize state = _state, values = _values, error = _error;

- (id)init
{
    if ((self = [super init])) {
        _error = nil;
        _raw_text = nil;
    }
    return self;
}
- (id)initWithObject:(id)response
{
    if ( ! response) {
        return (self = nil, self);
    }
    if ((self = [super init])) {
        if ([(NSDictionary *)response objectForKey: @"response"]) {
            _values = [[response objectForKey: @"response"] retain];
            _state = kResponseStateSuccessful;
        } else {
            _error = [[EBVKAPIError alloc] initWithErrorObject: response];
            _state = kResponseStateError;
        }
    } 
    return self;
}

- (id)initWithRawData:(NSData *)data
{
    if ( ! data) {
        return (self=nil, self);
    }
    if ((self = [super init])) {
        _raw_text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        _state = kResponseStateSuccessfulRaw;
    }
    return self;
}

- (id)initWithSDKError:(NSError *)internal_error
{
    if ( ! internal_error) {
        return (self=nil, self);
    }
    if ((self=[super init])) {
        _error = [[EBVKAPIError alloc] initWithNSError: internal_error];
        _state = kResponseStateError;
    }
    return self;
}


+ (id)responseWithObject:(id)response
{
    return [[[[self class] alloc] initWithObject: response] autorelease];
}

+ (id)responseWithRawData:(NSData *)data
{
    return [[[[self class] alloc] initWithRawData: data] autorelease];
}

+ (id)responseWithSDKError:(NSError *)internal_error
{
    return [[[[self class] alloc] initWithSDKError: internal_error] autorelease];
}

- (void)dealloc
{
    switch (_state) {
        case kResponseStateError:
            [_error release];
            break;
        case kResponseStateSuccessful:
            [_values release];
            break;
        case kResponseStateSuccessfulRaw:
        default:
            [_raw_text release];
    }
    [super dealloc];
}

@end