/*-------------------------------------------------------------------------
 * wrap.c
 *
 * Implementation of wrap() and unwrap().
 *
 *   While the obfuscation method used by Wrap is
 *   intentionally not Oracle-compatible, it would require the same amount of
 *   effort to reverse-engineer and unwrap the wrapped code.
 *
 *   The intent of this utility is to make the reverse-engineering of wrapped
 *   compilation-units difficult, not impossible!  This must *not* be
 *   marketed as completely secure, and should contain a message in the
 *   documentation regarding the security of storing passwords or other
 *   secure information.  Remember, this is obfuscation, not encryption.
 *
 *     CAUTION: One must ensure that any change to the methods employed by
 *              this utility remain platform-independent and that the unwrap
 *              functionality remains backward-compatible.
 *
 * The obfuscation method employed is:
 *
 * 0. Strip comments from compilation unit (not implemented, but would be wise)
 *
 *	  <source>
 *
 * 1. Compress the source
 *
 *	  <compressed source>
 *
 * 2. MD5 the compressed source. Append MD5 to compressed source.
 *
 *	  <MD5><compressed source>
 *
 * 3. Generate a random key. Obfuscate the compressed source with the key
 *	  Prepend the buffer with a WRAP_MAGIC (to identify algorithm version)
 *	  and the generated key.
 *
 *	  <magic><key><obfuscated string>
 *
 * 4. Base-64 encode the buffer
 *
 *	  <base64 encoded string>
 *
 * 5. Prepend with the encoding
 *	  <encoding> <base64 encoded string>
 *
 * To unwrap, the reverse is performed:
 *
 * 1. Extract the encoding from the beginning of the string.
 * 2. Base-64 decode the buffer
 * 3. Check magic byte at front. Grab the key that follows.
 * 4. Deobfuscate the rest of the buffer with the key
 * 5. Verify the stored MD5.
 * 6. Decompress the buffer
 *
 * SECURITY CONSIDERATIONS
 *
 *   - Symbols should *ALWAYS* be stripped during compile.
 *     Use -O2 and *don't* use -g (or use -g0 to disable it)
 *
 * Copyright (c) 2000-2009, PostgreSQL Global Development Group
 * Portions Copyright (c) 2004-2010, EnterpriseDB Corporation.
 *
 * IDENTIFICATION
 *	  $PostgreSQL$
 *
 *-------------------------------------------------------------------------
 */
#ifdef FRONTEND
#include "postgres_fe.h"

#else
#include "postgres.h"
#include "utils/builtins.h"
#include "mb/pg_wchar.h"
#endif
#include "wrap.h"

#include "md5.h"

#include <zlib.h>


/*
 * Enable this to get more descriptive error messages when wrapping or 
 * unwrapping fails. Should be disabled in production to make reverse
 * engineering a little bit harder.
 */
/* #define WRAP_DEBUG */

#ifdef FRONTEND

#ifdef WRAP_DEBUG
#define wrap_error(str) do { \
	fprintf(stderr, "%s\n", (str)); \
	exit(1); \
} while(0);
#else
#define wrap_error(str) do { \
	fprintf(stderr, "invalid wrapped string\n"); \
	exit(1); \
} while(0);
#endif

/* Frontend replacements for palloc and pfree  */
#undef palloc
#define palloc fe_palloc
#undef pfree
#define pfree free
#undef pstrdup

void *fe_palloc(int size);

#else

#ifdef WRAP_DEBUG
#define wrap_error(str)  ereport(ERROR, \
								 (errcode(ERRCODE_INTERNAL_ERROR), \
								 errmsg(str)))
#else
#define wrap_error(str)  ereport(ERROR, \
								 (errcode(ERRCODE_INTERNAL_ERROR), \
								 errmsg("invalid wrapped string")))
#endif

#endif

#define WRAP_MAGIC_BYTE 0x77

/*
 * A work buffer used to obfuscate/deobfuscate data. On obfuscation, 
 * fields are filled from end to front at different phases of the
 * operation.
 *
 * Note that all the data types used are chars, to avoid padding.
 */
typedef struct
{
	char 	magic;		/* WRAP_MAGIC_BYTE */
	char	key[16];	/* MD5 of data */
	unsigned char	md5[16];	/* MD5 of len + data */
	char	len[4];		/* Uncompressed length of following data, in network byte order */
	unsigned char data[1];	/* Compressed and/or obfuscated source, variable length */
} wrap_buffer;

/* ------------------------------------------------------------------------- */

/*
 * generate_key - Generate a random 128-bit key.
 *
 * The key is stored in *keybuf. The old contents of *keybuf are used as
 * seed.
 */
static void
generate_key(char *keybuf)
{
	MD5_CTX		 	ctxt;
	/*
	 * XOR the key with some static garbage, to make it a little less obvious
	 * that the key is the MD5 of the MD5 of the source.
	 */
	keybuf[0] ^= 0xb4; keybuf[1] ^= 0x15; keybuf[2] ^= 0x86; keybuf[3] ^= 0x31;
	keybuf[4] ^= 0x8a; keybuf[5] ^= 0x20; keybuf[6] ^= 0x04; keybuf[7] ^= 0xfd;
	keybuf[8] ^= 0x55; keybuf[9] ^= 0xd2; keybuf[10]^= 0xf7; keybuf[11]^= 0x62;
	keybuf[12]^= 0xb7; keybuf[13]^= 0x0a; keybuf[14]^= 0x20; keybuf[15]^= 0x8e;

	/* Generate key */
	MD5Init(&ctxt);
	MD5Update(&ctxt, (unsigned char *) keybuf, 16);
	MD5Final((unsigned char *) keybuf, &ctxt);
}

/*
 * obfuscate_buffer - Encrypt the the input buffer using a key.
 *
 * The encryption algorithm used is weak, hence we call it obfuscation
 * rather than encryption.
 *
 * Parameters
 *   buffer(IN/OUT) - The buffer we're obfuscating.
 *   buflen(IN)     - The size of the buffer
 *   key(IN)        - The key to use (128 bits)
 */
static void
obfuscate_buffer(unsigned char *buffer, int buflen, char *key)
{
	int				k,
					v;
	MD5_CTX		 	ctxt;
	unsigned char	keybuf[16];

	memcpy(keybuf, key, 16);

	k = 16;
	for (v = 0; v < buflen; v++)
	{
		if (k == 16)
		{
			/* Generate more key data */
			MD5Init(&ctxt);
			MD5Update(&ctxt, keybuf, 16);
			MD5Final(keybuf, &ctxt);
			k = 0;
		}
		buffer[v] = buffer[v]^keybuf[k++];
	}
}

/* The deobfuscation algorithm is the same as the obfuscation algorithm. */
#define deobfuscate_buffer obfuscate_buffer

static char *
wrap_internal(const char *buf, const char *encoding)
{
#ifdef HAVE_LIBZ
	MD5_CTX			ctxt;
	wrap_buffer	   *buffer;
	uLongf			comprLen;
	char		   *b64_txt;
	uint32			nlen;
	int				len = strlen(buf) + 1;
	char		   *result;

	/* Get an upper bound for the length of compressed data */
	comprLen = compressBound(len);

	/*
	 * Allocate space to compress it. Add an extra 16 bytes to make room
	 * for MD5 checksum, + 1 byte for the magic byte
	 */
	buffer = (wrap_buffer *) palloc(sizeof(wrap_buffer) + comprLen);

	/* Compress it */
	if (compress(buffer->data, &comprLen, (unsigned char *) buf, len) != Z_OK)
		wrap_error("error during compression");

	/* MD5 the compressed data */
	MD5Init(&ctxt);
	MD5Update(&ctxt, buffer->data, comprLen);
	MD5Final(buffer->md5, &ctxt);

#if 0
	{
		int i;
		printf("digest = [");
		for (i = 0; i < 16; i++)
			printf("%02x", buffer->md5[i]);
		printf("]\n");
	}
#endif

	/*
	 * Generate key. We seed the key generation using the MD5 of the source,
	 * so that any changes in the source are propagated to all bits of the
	 * output
	 */
	memcpy(buffer->key, buffer->md5, 16);
	generate_key(buffer->key);
	
	/*
	 * Fill in length. Must use memcpy because the len field in the buffer is
	 * not aligned, and unaligned access cause a segfault on some platforms.
	 */
	nlen = htonl(len);
	memcpy(buffer->len, &nlen, 4);

	/* Obfuscate */
	obfuscate_buffer(buffer->md5,
					 /* md5 + len + compressed data */
					 16 + 4 + comprLen,
					 buffer->key);

	/* Base-64 encode it */

	buffer->magic = WRAP_MAGIC_BYTE;

	b64_txt = encode_base64((char *) buffer,
							offsetof(wrap_buffer, data) + comprLen);

	/* calculate length of the output buffer */
	len = strlen(WRAP_DELIM "\n")
		+ strlen(encoding)
		+ strlen("\n")
		+ strlen(b64_txt)
		+ strlen("\n" WRAP_DELIM)
		+ 1;					/* null terminator */
	result = palloc(len);

	/* prepend the encoding string as is */
	snprintf(result, len,
			 WRAP_DELIM "\n%s\n%s\n" WRAP_DELIM,
			 encoding, b64_txt);

	pfree(buffer);
	pfree(b64_txt);

	return result;
#else
	elog(ERROR, "compiled without zlib");
	return NULL;
#endif
}


/* ------------------------------------------------------------------------- */


/*
 * Remove whitespace from beginning of a string.
 */
static const char *
trim(const char *str)
{
	/* We use the same definition of whitespace as base64_decode(). */
	while(*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r')
		str++;
	return str;
}


/*
 * unwrap_internal - unwraps wrapped data
 *
 *   This function can be used to unwrap code which has been lost due to 
 *   wrapping.  Additionally, a server-side version of this code is required 
 *   to create and execute the compilation units themselves.
 *
 * This function accepts the wrapped code with or without the
 * WRAP_DELIM delimiter which is defined in wrap.h.
 *
 * Parameters
 *   buffer(IN)		- A C-string containing the wrapped code
 *   len(OUT)		- length of returned string
 *   encoding(OUT)	- name of the encoding the plaintext string is in.
 *
 * Returns unwrapped plaintext string.
 */
static char *
unwrap_internal(const char *wrapped, int *len, char **encoding_ptr)
{
#ifdef HAVE_LIBZ
	wrap_buffer	   *buffer;

	/* Variables used for MD5 verification */
	MD5_CTX			ctxt;
	unsigned char   digest[16];

	int				sz;

	uLongf			uncompressed_len;
	uint32			expected_len;
	char		   *result;
	char		   *b64;
	bool			copied_input = false;

	/* Trim whitespace from beginning. */
	wrapped = trim(wrapped);

	/*
	 * If the string still has delimiters, strip them. 
	 */
	if (strncmp(wrapped, WRAP_DELIM, strlen(WRAP_DELIM)) == 0)
	{
		int len;
		char *wrapped_new;

		/* Strip delimiter at the beginning and any following whitespace. */
		wrapped += strlen(WRAP_DELIM);
		wrapped = trim(wrapped);

		/*
		 * Check and strip the delimiter at the end. We have to make a
		 * copy of the string, because we don't want to modify the passed
		 * in string.
		 */
		len = strlen(wrapped) - strlen(WRAP_DELIM);
		if (len < 0 ||	strcmp(wrapped + len, WRAP_DELIM) != 0)
			wrap_error("invalid wrap end delimiter");

		wrapped_new = palloc(len + 1);
		memcpy(wrapped_new, wrapped, len);
		wrapped_new[len] = '\0';

		wrapped = wrapped_new;
		copied_input = true;
	}

	/* 1. Extract encoding from the beginning */

	b64 = strpbrk(wrapped, " \t\n\r");

	if (b64 == NULL)
		wrap_error("space not found");

	if (encoding_ptr)
	{
		int encoding_len = b64 - wrapped;

		*encoding_ptr = palloc(encoding_len + 1);
		memcpy(*encoding_ptr, wrapped, encoding_len);
		(*encoding_ptr)[encoding_len] = '\0';
	}

	/* 2. Base-64 decode the rest of the string */
	buffer = (wrap_buffer *) decode_base64(b64, &sz);
	if(sz < sizeof(wrap_buffer))
		wrap_error("wrapped string too small");

	/*
	 * 3. Check magic byte.
	 *
	 * If we supported different versions of wrapping, this is where
	 * we would determine the version by looking at the magic byte
	 */
	if (buffer->magic != WRAP_MAGIC_BYTE)
		wrap_error("magic byte mismatch");

	/* 4. Deobfuscate the buffer */

	deobfuscate_buffer(buffer->md5, sz - offsetof(wrap_buffer, md5),
					   buffer->key);

	/* 5. Verify MD5 checksum */

	/* calculate MD5 of the compressed data */
	MD5Init(&ctxt);
	MD5Update(&ctxt, buffer->data, sz - offsetof(wrap_buffer, data));
	MD5Final(digest, &ctxt);

	/* compare it with the stored checksum */
	if (memcmp(digest, buffer->md5, 16) != 0)
		wrap_error("checksum failed");

	/* 6. Decompress the buffer */

	/*
	 * Extract length from the buffer. Use memcpy because len field is not
	 * aligned.
	 */
	memcpy(&expected_len, buffer->len, 4);
	expected_len = ntohl(expected_len);
	uncompressed_len = expected_len;

	result = palloc(uncompressed_len);

	if (uncompress((unsigned char *) result, &uncompressed_len, buffer->data,
				   sz - offsetof(wrap_buffer, data)) != Z_OK)
		wrap_error("error during uncomression");

	if (uncompressed_len != expected_len)
		wrap_error("uncompressed length mismatch");

	/* Check that the string was null-terminated */
	if (result[uncompressed_len - 1] != '\0')
		wrap_error("string not terminated");

	/* Clean up */

	pfree(buffer);
	if (copied_input)
		pfree((char *) wrapped);

	if (len)
		*len = uncompressed_len - 1;
	return result;
#else
	elog(ERROR, "compiled without zlib");
	return NULL;
#endif
}


/*
 * Is the given string a wrapped block?
 */
bool
is_wrapped(const char *source)
{
	source = trim(source);
	if (strncmp(source, WRAP_DELIM, strlen(WRAP_DELIM)) == 0)
		return true;
	else
		return false;
}

#ifndef FRONTEND

/* -------------------------------------------------------------------------
 * Backend wrap and unwrap functions. The wrap function uses the database
 * encoding as the encoding name, and unwrap converts to the database
 * encoding if necessary.
 * -------------------------------------------------------------------------
 */

char *
wrap(const char *buf)
{
	return wrap_internal(buf, GetDatabaseEncodingName());
}

char *
unwrap(const char *wrapped)
{
	char   *converted;
	char   *str;
	char   *encoding;
	int		len;
	int		encoding_id;

	str = unwrap_internal(wrapped, &len, &encoding);

	encoding_id = pg_char_to_encoding(encoding);
	if (encoding_id == -1)
		elog(ERROR, "unknown encoding \"%s\" in wrapped string", encoding);

	pfree(encoding);

	/*
	 * Convert the string to database encoding. If no conversion is
	 * required, we still need to check that the string is valid.
	 */
	converted = (char *) pg_do_encoding_conversion((unsigned char *) str,
												   len,
												   encoding_id,
												   GetDatabaseEncoding());
	if (converted != str)
	{
		/*
		 * Conversion was performed. Assume the converter can't produce
		 * invalid strings.
		 */
		pfree(str);
	}
	else
		pg_verifymbstr(converted, len, false);

	return converted;
}

bool
can_wrap(const char *langname, Oid langid)
{
	if (!strcmp(langname, "plpgsqlo"))
		return true;
	else
		return false;
}

#else

/* -------------------------------------------------------------------------
 * Frontend wrap and unwrap functions. These versions take/return the
 * encoding name as argument.
 * -------------------------------------------------------------------------
 */

char *
wrap_enc(const char *buf, const char *encoding)
{
	return wrap_internal(buf, encoding);
}

char *
unwrap_enc(const char *buf, char **encoding)
{
	return unwrap_internal(buf, NULL, encoding);
}

/* Simple frontend replacement of palloc() */
void *
fe_palloc(int size)
{
	void *p = malloc(size);

	if (!p)
	{
		wrap_error("memory allocation failure");
		return NULL;
	}

	return p;
}

#endif /* FRONTEND */

