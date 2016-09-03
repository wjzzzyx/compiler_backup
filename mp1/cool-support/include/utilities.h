// -*-Mode: C++;-*-
//
// See copyright.h for copyright notice and limitation of liability
// and disclaimer of warranty provisions.
//
#include "copyright.h"

#ifndef _UTILITIES_H_
#define _UTILITIES_H_

#include "cool-io.h"

extern const char *cool_token_to_string(int tok);
extern void print_cool_token(int tok);
extern void fatal_error(char *);
extern void print_escaped_string(ostream& str, const char *s);
extern const char *pad(int);

#endif
