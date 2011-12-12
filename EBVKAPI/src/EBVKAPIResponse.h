//
//  EBVKAPIResponse.h
//  


#import <Cocoa/Cocoa.h>

@interface EBVKAPIResponse : NSObject
{
	@protected
    NSDictionary*_response;
    NSError *_error;
}

@property (readonly) NSDictionary *response;
@property (readonly) NSError *error;

+ (id)responseWithResponse:(NSDictionary *)response andError:(NSError *)error;
- (id)initWithResponse:(NSDictionary *)response andError:(NSError *)error;
@end
