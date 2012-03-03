
//
//  common_utils.h
//

#ifndef common_utils_h
	#define common_utils_h


#define EBNULL [NSNull null]
/* @about: Checks a list of params (obj-c objects only) for equals to nil. 
   @parameters:  list of objects completed by [NSNull null] (aka EBNULL). 
   @return: [1] if non of parguments is equal to nil
            [0] in other case;
*/
int check_for_nil(id first, ...);

#endif
