//
//	EBVKAPIError.h
//

#import <Foundation/Foundation.h>

enum EBVKAPIErrorCodes {
	
	EBErrorUnknown                      = 1,
	EBErrorDisabledApplication          = 2,
	EBErrorIncorrectSignature           = 4,
	EBErrorAuthorizationFailed          = 5,
	EBErrorToManyRequestsPerSecond      = 6,
	EBErrorPermissionDeniedByUser       = 7,
	EBErrorRequestError                 = 8,  // secure.getBalance
	EBErrorActionDeniedByFloodControl   = 9,  // audio.editAlbum
	EBErrorServerError                  = 10,
	EBErrorCompilationError             = 12,
	EBErrorRuntimeError                 = 13,
	EBErrorCaptchaNeeded                = 14,
	EBErrorGroupAlbumsDisabled          = 15, 
	EBErrorWallPermissionDenied         = 15, // photos.getWallUploadServer
	// EBErrorUsersGroupListAccessDenied = 15 // deprecated;
	EBErrorMissingOrInvalidParameter    = 100,
	EBErrorExceededStorageLimit         = 103,
	EBErrorInvalidKey                   = 110,
	EBErrorInvalidCount                 = 111,
	EBErrorInvalidScore                 = 112,  
	EBErrorUserInvalidID                = 113,
	/* Yeah, it's two [invalidID] codes */
	EBErrorAlbumInvalidID_1             = 114,
	EBErrorCountriesInvalidIDs          = 115,
	EBErrorCitiesInvaildIDs             = 116,
	EBErrorAlbumInvalidID_2             = 117,
	EBErrorServerInvalid                = 118,
	EBErrorAlbumInvalidTitle            = 119,
	EBErrorMessageInvalid               = 120, 
	EBErrorHashInvalid                  = 121,
	EBErrorPhotoInvalid                 = 122, //
	EBErrorPhotosListInvalid            = 122, // 
	EBErorrInvalidPhotosList            = 122, // photo.save method 
	EBErrorAudioInvalid                 = 123,
	EBErrorInvalidAppStatus             = 124,
	EBErrorGroupInvalidID               = 125,
	EBErrorInvalidProfilePhoto          = 129,
	EBErrorQuestionTextIsToShort        = 130,
	EBErrorQuestionNotFound_1           = 131, 
	EBErrorQuestionAccessDenied_1       = 132,
	EBErrorQuestionNotFound_2           = 134,
	EBErrorQuestionAccessDenied_2       = 135,
	EBErrorAnswerDeniedByFloodControl   = 136,
	BEErrorWikiPageNotFound             = 140,
	EBErrorWikiPageAccessDenied         = 141,
	EBErrorAlreadyOccupiedPrefix        = 145,
	EBErrorUnknownMobileNumber          = 146,
	EBErrorAppHasInsufficientFunds      = 147,
	EBErrorUserMenuAccessDenied         = 148,
	EBErrorInvaildVotes                 = 151,
	EBErrorInvaildUsedIDFrom            = 152,
	EBErrorInvaildUsedIDTo              = 153,
	BEErrorInvalidDateFrom              = 154,
	EBErrorInvaildDateTo                = 155,
	EBErrorInvaildLimit                 = 156,
	EBErrorUsersFriendsListAccessDenied = 170,
	EBErrorFriendsListInvalidID         = 170, // friends.editList
	EBErrorFriendsListNameInvalid       = 171,
	EBErrorMaximumOfFriendsListsReachedYet = 172,
	EBErrorTryToAddYourselfToFriends    = 174,
	EBErrorYouInUsersBlacklist          = 175,
	EBErrorCannotAddUserToFriendsDuePrivacySettigns = 176,
	EBErrorNotesNotFound                = 180,
	EBErrorNotesAccessDenied            = 181,
	EBErrorNotesCommentsNotAllowed      = 182,
	EBErrorCommentAccesssDenied         = 183,
	EBErrorCheckinsAccessDenied         = 191,
	EBErrorAccessDenied_1               = 200,
	EBErrorAccessDenied_2               = 201, // aka "Document not found" for docs.xxx
	EBErrorCacheExpired                 = 202, // audio.restore
	EBErrorGroupAccessDenied            = 203,
	EBErrorAccessDenied_3               = 204, // video
	EBErrorWallAccessDenied             = 210,
	EBErrorWallCommentsDenied           = 211,
	EBErrorWallPostCommentsDisabled     = 212,
	EBErrorWallPostAddingActionDenied   = 214,
	EBErrorWallPostHasLikedYet          = 215,
	EBErrorWallPostHasUnlikedYet        = 216,
	EBErrorWallPostHasPublishedYet      = 217,
	EBErrorStatusAccessDenied           = 220,	
	EBErrorObjectAlreadyLiked           = 230,
	EBErrorObjectAlreadyUnliked         = 231,
	EBErrorSubscriptionsOrFollowersListAccessDenied = 240,
	EBErrorUserPrifileAccessDenied      = 241,
	EBErrorMaximumCountOfSubscriptions  = 242,
	EBErrorPollAccessDenied             = 250,
	EBErrorPollInvalidID                = 251,
	EBErrorPollInvalidAnswerID          = 252,
	EBErrorUsersGroupsListAccessDenied  = 260,
	EBErrorAlbumIsFull                  = 300,
	EBErrorFileInvalidName              = 301,
	EBErrorFileInvalidSize              = 302,
	EBErrorAudioAlbumsLimitReached      = 302, // audio.addAlbum
	EBErrorVotesProccessingDisabled     = 500,
	EBErrorNotEnoughVotes               = 502,
	EBErrorWallTooFrequently            = 10005,	
};

#define kEBErrorInternalSDKIssue -71243

@class EBVKAPIRequest;

@interface EBVKAPIError : NSObject
{
 @protected
	NSInteger _error_code;
	NSString *_error_description;
	EBVKAPIRequest *_request;
	/* Captcha */
 @private
	NSString *_captcha_sid;
	NSURL *_captcha_url;
	NSString *_parsed_captcha;
}

@property (nonatomic, retain, readonly) NSString *description;
@property (readonly) NSInteger code;

/* $error_dictionary = API error parsed by JSONKit */
- (id)initWithErrorObject:(id)error_dictionary;
/* Create an error from Cocoa's default NSError object */
- (id)initWithNSError:(NSError *)error;


+ (id)errorWithObject:(id)error_dictionary;
+ (id)errorWithNSError:(NSError *)error;
@end