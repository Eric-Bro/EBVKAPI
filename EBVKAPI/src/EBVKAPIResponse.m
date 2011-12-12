//
//  EBVKAPIResponse.m
//  


#import "EBVKAPIResponse.h"

@implementation EBVKAPIResponse
@synthesize error = _error, response = _response;

- (id)init
{
    if ((self = [super init])) {
        _error = nil;
        _response = nil;
    } else {
        self = nil;
    }
    return self;
}

- (id)initWithResponse:(NSDictionary *)response andError:(NSError *)error
{
    if ((self = [super init])) {
        _error = [error copy];
        _response = [response retain];
    } else {
        self = nil;
    }
    return self;
}

+ (id)responseWithResponse:(NSDictionary *)response andError:(NSError *)error
{
    return [[[[self class] alloc] initWithResponse:response andError: error] autorelease];
}

@end
