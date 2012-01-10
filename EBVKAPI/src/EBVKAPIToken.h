//
//  EBVKAPIToken.h
//


#import <Foundation/Foundation.h>

#import "EBVKAPIRequest.h" /* For cookies work */

enum EBVKAPITokenStatus {
    EBVKAPITokenSuccess,
    EBVKAPITokenWrongCredentials,
    EBVKAPITokenConnectionError,
    EBVKAPITokenParsingError,
    EBVKAPITokenUnknowingError,
}EBVKAPITokenStatus;

enum EBVKAPIApplicationSettingsFlags {
    /* The user allows receiving notifications. */
    EBSettingsAllowNotifications   = 1 << 0,
    EBSettingsFriendsAccess        = 1 << 1,
    EBSettingsPhotosAccess         = 1 << 2,
    EBSettingsAudioAccess          = 1 << 3,
    EBSettingsVideosAccess         = 1 << 4,
    EBSettingsProposalsAccess      = 1 << 5,
    EBSettingsQuestionsAccess      = 1 << 6,
    EBSettingsWikiAccess           = 1 << 7, 
    /* Adding an application link to the left menu */
    EBSettingsAddAppToLeftPanel    = 1 << 8, 
    /* Adding an application link for quick wall posts on users' walls*/
    EBSettingsFastSharing          = 1 << 9,
    EBSettingsStatusAccess         = 1 << 10,
    EBSettingsNotesAccess          = 1 << 11,
    /* Access to advanced methods for working with messages */
    EBSettingsMessagesAccess       = 1 << 12,

    EBSettingsWallAccess           = 1 << 13, 
    /* Access to advertising tools (http://vk.com/developers.php?oid=-17680044&p=Ads_API)*/
    EBSettingsAdvertisementAccess  = 1 << 14,
    EBSettingsDocumentsAccess      = 1 << 15,
    EBSettingsGroupsAccess         = 1 << 16,
    /* Allows sending alerts to user about smth */
    EBSettingsAllowAlerts          = 1 << 17
}EBVKAPIApplicationSettingsFlags;

@interface EBVKAPIToken : NSObject
{
@protected
    NSString *_appid;
    NSInteger _stat;
@public
    NSString *_sid;
    NSString *_mid;
    NSString *_secret;
    NSString *_expire;
    NSArray *_cookies;
}
@property (readonly) NSString *appID;
@property (readonly) NSString *sid;
@property (readonly) NSString *mid;
@property (readonly) NSString *secret;
@property (readonly) NSString *expire;
@property (readonly) NSInteger status;
@property (readonly) NSArray *cookies;

-  (id)initWithEmail:(NSString *)email password:(NSString *)password applicationID:(NSString *)app_id settings:(NSInteger)settings error:(NSError **)error;
+ (id)tokenWithEmail:(NSString *)email password:(NSString *)password applicationID:(NSString *)app_id settings:(NSInteger)settings error:(NSError **)error;
@end
