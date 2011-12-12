//
//  common.h
//

#ifndef common_h
	#define common_h


#define EBNULL [NSNull null]
/* Checks a list of params (obj-c objects only) for equals to nil. 
   This list should be completed by [NSNull null] (aka EBNULL). */
static int check_params(id first, ...)
{
    va_list args;
    id tmp = first;
    va_start(args, first);
    while (tmp != [NSNull null]) {
        if (!tmp) {
            va_end(args);
            return 0;
        }
        tmp = va_arg(args, id);
    }
    va_end(args);
    return 1;
}


#endif
