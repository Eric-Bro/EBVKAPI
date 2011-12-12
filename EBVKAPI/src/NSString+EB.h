//
//  NSString+EB.h
//


#import <Foundation/Foundation.h>

@interface NSString (EBUtils)

- (NSString *)stringBetweenString: (NSString *)left_string andString: (NSString *)rigth_string;
- (NSString *)MD5Hash;
+ (NSString *)stringWithMD5Hash: (NSString *)source;
@end
