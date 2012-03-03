#import <EBVKAPI/EBVKAPIRequest.h>
#import <EBVKAPI/EBVKAPIResponse.h>
#import <EBVKAPI/EBVKAPIToken.h>

#define EBVKAPIWaitUntilAsyncsDone(request) do {} while ([(request) operationsQuantity] > 0)
