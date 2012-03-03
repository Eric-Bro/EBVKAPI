//
//
//
#include "common_utils.h"

int check_for_nil(id first, ...)
{
    va_list args;
    id tmp = first;
    va_start(args, first);
    while (tmp != [NSNull null]) {
        if (!tmp) {
            va_end(args);
            return (0);
        }
        tmp = va_arg(args, id);
    }
    va_end(args);
    return (1);
}
	