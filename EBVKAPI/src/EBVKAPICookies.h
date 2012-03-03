//
//  EBVKAPICookies.h
//  EBVKAPI
//
//  Created by Eric Broska on 03.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EBVKAPICookies : NSObject

/* At this case, $domain always will be equals to the @".vk.com" */
+ (NSArray *)dumpAllCookiesForDomain:(NSString *)domain;
+ (void)setCookies:(NSArray *)new_cookies forDomain:(NSString *)domain;
+ (void)cleanUpAllCookiesForDomain: (NSString *)domain;

@end
