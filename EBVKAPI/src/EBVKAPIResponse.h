//
//  EBVKAPIResponse.h
//  


#import <Cocoa/Cocoa.h>
#import "EBVKAPIError.h"

enum {
	kResponseStateSuccessful, 
	kResponseStateError, 
	kResponseStateSuccessfulRaw,
};

@interface EBVKAPIResponse : NSObject
{
 @protected
 	int _state;
	NSDictionary *_values;
	EBVKAPIError *_error;
	NSString *_raw_text;
}
@property (readonly) int state;
@property (nonatomic, readonly) NSDictionary *values;
@property (nonatomic, readonly) EBVKAPIError *error;


- (id)initWithObject:(id)response;
- (id)initWithRawData:(NSData *)data;
- (id)initWithSDKError:(NSError *)internal_error;

+ (id)responseWithObject:(id)response;
+ (id)responseWithRawData:(NSData *)data;
+ (id)responseWithSDKError:(NSError *)internal_error;
@end