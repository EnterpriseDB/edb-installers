/*-------------------------------------------------------------------------
 *
 * wrap.h
 *	  Declarations for wrapping / unwrapping text
 *
 * Copyright (c) 2004-2010, EnterpriseDB Corporation.
 *
 * $PostgreSQL$
 *
 * This file is in src/backend/utils/wrap, rather than src/include like
 * other header files, so that this isn't installed to share/include with
 * "make install". We don't want this to be distributed, because the below
 * comment is basically a recipe for cracking the obfuscation.
 * 
 *-------------------------------------------------------------------------
 */

#ifndef WRAP_H
#define WRAP_H

#define WRAP_DELIM ""

 /*
  * The functions below are renamed to have less obvious names, so that a user
  * will find it difficult to figure out what exactly is the symbol of the
  * function in the binary that does the actual wrap and unwrap. This is
  * particularly applicable if a user tries his luck by setting a breakpoint
  * in function unwrap(), and spots the unwrapped code in memory. Also, even
  * after stripping out symbols from the binary, the debugger allows to set
  * the breakpoint, so better change the names.
  */
#define wrap_enc _doit_enc_
#define unwrap_enc _undoit_enc_
#define wrap _doit_
#define unwrap _undoit_


extern bool is_wrapped(const char *source);

#ifdef FRONTEND
extern char *wrap_enc(const char *buf, const char *encoding);
extern char *unwrap_enc(const char *str, char **encoding);
#else
#include "catalog/pg_language.h"

extern char *wrap(const char *buf);
extern char *unwrap(const char *str);
bool  can_wrap(const char *langname, Oid langid);
char *encode_base64(char *data, int datalen);
char *decode_base64(char *data, int *resultlen);
#endif
#include "catalog/pg_language.h"

extern char *wrap(const char *buf);
extern char *unwrap(const char *str);
bool  can_wrap(const char *langname, Oid langid);
char *encode_base64(char *data, int datalen);
char *decode_base64(char *data, int *resultlen);
#endif
