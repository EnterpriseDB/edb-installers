/*
 * getlocales --- Return a list of PostgreSQL supported backend locales to
 * be used by bitrock based installer.
 *
 * The code for locale verification is adopted from PostgreSQL source code.
 *
 * Author: Usman Saleem, EnterpriseDB  - usman@enterprisedb.com
 */

#include <stdio.h>
#include <locale.h>
#include <langinfo.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#define HIGHBIT					(0x80)
#define IS_HIGHBIT_SET(ch)		((unsigned char)(ch) & HIGHBIT)

typedef enum pg_enc
{
  PG_SQL_ASCII = 0,		/* SQL/ASCII */
  PG_EUC_JP,			/* EUC for Japanese */
  PG_EUC_CN,			/* EUC for Chinese */
  PG_EUC_KR,			/* EUC for Korean */
  PG_EUC_TW,			/* EUC for Taiwan */
  PG_EUC_JIS_2004,		/* EUC-JIS-2004 */
  PG_UTF8,			/* Unicode UTF8 */
  PG_MULE_INTERNAL,		/* Mule internal code */
  PG_LATIN1,			/* ISO-8859-1 Latin 1 */
  PG_LATIN2,			/* ISO-8859-2 Latin 2 */
  PG_LATIN3,			/* ISO-8859-3 Latin 3 */
  PG_LATIN4,			/* ISO-8859-4 Latin 4 */
  PG_LATIN5,			/* ISO-8859-9 Latin 5 */
  PG_LATIN6,			/* ISO-8859-10 Latin6 */
  PG_LATIN7,			/* ISO-8859-13 Latin7 */
  PG_LATIN8,			/* ISO-8859-14 Latin8 */
  PG_LATIN9,			/* ISO-8859-15 Latin9 */
  PG_LATIN10,			/* ISO-8859-16 Latin10 */
  PG_WIN1256,			/* windows-1256 */
  PG_WIN1258,			/* Windows-1258 */
  PG_WIN866,			/* (MS-DOS CP866) */
  PG_WIN874,			/* windows-874 */
  PG_KOI8R,			/* KOI8-R */
  PG_WIN1251,			/* windows-1251 */
  PG_WIN1252,			/* windows-1252 */
  PG_ISO_8859_5,		/* ISO-8859-5 */
  PG_ISO_8859_6,		/* ISO-8859-6 */
  PG_ISO_8859_7,		/* ISO-8859-7 */
  PG_ISO_8859_8,		/* ISO-8859-8 */
  PG_WIN1250,			/* windows-1250 */
  PG_WIN1253,			/* windows-1253 */
  PG_WIN1254,			/* windows-1254 */
  PG_WIN1255,			/* windows-1255 */
  PG_WIN1257,			/* windows-1257 */
  PG_KOI8U,			/* KOI8-U */
  /* PG_ENCODING_BE_LAST points to the above entry */

  /* followings are for client encoding only */
  PG_SJIS,			/* Shift JIS (Winindows-932) */
  PG_BIG5,			/* Big5 (Windows-950) */
  PG_GBK,			/* GBK (Windows-936) */
  PG_UHC,			/* UHC (Windows-949) */
  PG_GB18030,			/* GB18030 */
  PG_JOHAB,			/* EUC for Korean JOHAB */
  PG_SHIFT_JIS_2004,		/* Shift-JIS-2004 */
  _PG_LAST_ENCODING_		/* mark only */
} pg_enc;

/*
 * Copied from chklocales.c
 */
struct encoding_match
{
  enum pg_enc pg_enc_code;
  const char *system_enc_name;
};

static const struct encoding_match encoding_match_list[] = {
  {PG_EUC_JP, "EUC-JP"},
  {PG_EUC_JP, "eucJP"},
  {PG_EUC_JP, "IBM-eucJP"},
  {PG_EUC_JP, "sdeckanji"},
  {PG_EUC_JP, "CP20932"},

  {PG_EUC_CN, "EUC-CN"},
  {PG_EUC_CN, "eucCN"},
  {PG_EUC_CN, "IBM-eucCN"},
  {PG_EUC_CN, "GB2312"},
  {PG_EUC_CN, "dechanzi"},
  {PG_EUC_CN, "CP20936"},

  {PG_EUC_KR, "EUC-KR"},
  {PG_EUC_KR, "eucKR"},
  {PG_EUC_KR, "IBM-eucKR"},
  {PG_EUC_KR, "deckorean"},
  {PG_EUC_KR, "5601"},
  {PG_EUC_KR, "CP51949"},	/* or 20949 ? */

  {PG_EUC_TW, "EUC-TW"},
  {PG_EUC_TW, "eucTW"},
  {PG_EUC_TW, "IBM-eucTW"},
  {PG_EUC_TW, "cns11643"},
  /* No codepage for EUC-TW ? */

  {PG_UTF8, "UTF-8"},
  {PG_UTF8, "utf8"},
  {PG_UTF8, "CP65001"},

  {PG_LATIN1, "ISO-8859-1"},
  {PG_LATIN1, "ISO8859-1"},
  {PG_LATIN1, "iso88591"},
  {PG_LATIN1, "CP28591"},

  {PG_LATIN2, "ISO-8859-2"},
  {PG_LATIN2, "ISO8859-2"},
  {PG_LATIN2, "iso88592"},
  {PG_LATIN2, "CP28592"},

  {PG_LATIN3, "ISO-8859-3"},
  {PG_LATIN3, "ISO8859-3"},
  {PG_LATIN3, "iso88593"},
  {PG_LATIN3, "CP28593"},

  {PG_LATIN4, "ISO-8859-4"},
  {PG_LATIN4, "ISO8859-4"},
  {PG_LATIN4, "iso88594"},
  {PG_LATIN4, "CP28594"},

  {PG_LATIN5, "ISO-8859-9"},
  {PG_LATIN5, "ISO8859-9"},
  {PG_LATIN5, "iso88599"},
  {PG_LATIN5, "CP28599"},

  {PG_LATIN6, "ISO-8859-10"},
  {PG_LATIN6, "ISO8859-10"},
  {PG_LATIN6, "iso885910"},

  {PG_LATIN7, "ISO-8859-13"},
  {PG_LATIN7, "ISO8859-13"},
  {PG_LATIN7, "iso885913"},

  {PG_LATIN8, "ISO-8859-14"},
  {PG_LATIN8, "ISO8859-14"},
  {PG_LATIN8, "iso885914"},

  {PG_LATIN9, "ISO-8859-15"},
  {PG_LATIN9, "ISO8859-15"},
  {PG_LATIN9, "iso885915"},
  {PG_LATIN9, "CP28605"},

  {PG_LATIN10, "ISO-8859-16"},
  {PG_LATIN10, "ISO8859-16"},
  {PG_LATIN10, "iso885916"},

  {PG_KOI8R, "KOI8-R"},
  {PG_KOI8R, "CP20866"},

  {PG_KOI8U, "KOI8-U"},
  {PG_KOI8U, "CP21866"},

  {PG_WIN866, "CP866"},
  {PG_WIN874, "CP874"},
  {PG_WIN1250, "CP1250"},
  {PG_WIN1251, "CP1251"},
  {PG_WIN1251, "ansi-1251"},
  {PG_WIN1252, "CP1252"},
  {PG_WIN1253, "CP1253"},
  {PG_WIN1254, "CP1254"},
  {PG_WIN1255, "CP1255"},
  {PG_WIN1256, "CP1256"},
  {PG_WIN1257, "CP1257"},
  {PG_WIN1258, "CP1258"},

  {PG_ISO_8859_5, "ISO-8859-5"},
  {PG_ISO_8859_5, "ISO8859-5"},
  {PG_ISO_8859_5, "iso88595"},
  {PG_ISO_8859_5, "CP28595"},

  {PG_ISO_8859_6, "ISO-8859-6"},
  {PG_ISO_8859_6, "ISO8859-6"},
  {PG_ISO_8859_6, "iso88596"},
  {PG_ISO_8859_6, "CP28596"},

  {PG_ISO_8859_7, "ISO-8859-7"},
  {PG_ISO_8859_7, "ISO8859-7"},
  {PG_ISO_8859_7, "iso88597"},
  {PG_ISO_8859_7, "CP28597"},

  {PG_ISO_8859_8, "ISO-8859-8"},
  {PG_ISO_8859_8, "ISO8859-8"},
  {PG_ISO_8859_8, "iso88598"},
  {PG_ISO_8859_8, "CP28598"},
/*
 * Client encoding, not required
	{PG_SJIS, "SJIS"},
	{PG_SJIS, "PCK"},
	{PG_SJIS, "CP932"},

	{PG_BIG5, "BIG5"},
	{PG_BIG5, "BIG5HKSCS"},
	{PG_BIG5, "Big5-HKSCS"},
	{PG_BIG5, "CP950"},

	{PG_GBK, "GBK"},
	{PG_GBK, "CP936"},

	{PG_UHC, "UHC"},
	{PG_UHC, "CP949"},

	{PG_JOHAB, "JOHAB"},
	{PG_JOHAB, "CP1361"},

	{PG_GB18030, "GB18030"},
	{PG_GB18030, "CP54936"},

	{PG_SHIFT_JIS_2004, "SJIS_2004"},
*/
  {PG_SQL_ASCII, NULL}		/* end marker */
};



/*
 * Case-independent comparison of two null-terminated strings.
 * Copied from port/pgstrcasecmp.c
 */
int
pg_strcasecmp (const char *s1, const char *s2)
{
  for (;;)
    {
      unsigned char ch1 = (unsigned char) *s1++;
      unsigned char ch2 = (unsigned char) *s2++;

      if (ch1 != ch2)
	{
	  if (ch1 >= 'A' && ch1 <= 'Z')
	    ch1 += 'a' - 'A';
	  else if (IS_HIGHBIT_SET (ch1) && isupper (ch1))
	    ch1 = tolower (ch1);

	  if (ch2 >= 'A' && ch2 <= 'Z')
	    ch2 += 'a' - 'A';
	  else if (IS_HIGHBIT_SET (ch2) && isupper (ch2))
	    ch2 = tolower (ch2);

	  if (ch1 != ch2)
	    return (int) ch1 - (int) ch2;
	}
      if (ch1 == 0)
	break;
    }
  return 0;
}


static char *
rtrim (char *string, char junk)
{
  char *original = string + strlen (string);
  while (*--original == junk);
  *(original + 1) = '\0';
  return string;
}

/**
 * Modifies passed char * and to strip \r and \n
 */
char *
stripeol (char *str)
{
  return rtrim (rtrim (str, '\r'), '\n');
}

static void *
pg_malloc (size_t size)
{
  void *result;

  result = malloc (size);
  if (!result)
    {
      fprintf (stderr, "Out of Memory\n");
      exit (1);
    }
  return result;
}

/*
 * C search and replace.
 * Returns a copy of char *line with all tokens replaced.
 */
char *
csar (char *line, char *token, char *replacement)
{

  char *result, *finalresult;	/* the return string */
  int token_length;		/* length of token */
  int replacement_length;	/* length of replacement */
  int count;			/* number of replacements */
  char *tmp;			/* for holding temporary pointers */
  char *curr;			/* for holding current position */
  int diff;			/* contains byte difference to calculate next replace */

  /* Basic sanity of arguments */
  if (!line)
    return NULL;
  if (!token || !(token_length = strlen (token)))
    return NULL;
  if (!replacement || !(replacement_length = strlen (replacement)))
    return NULL;
  /*return same line if there is nothing to replace */
  if (!(strstr (line, token)))
    return line;

  curr = line;

  /*determine count of tokens */
  for (count = 0; tmp = strstr (curr, token); count++)
    {
      curr = tmp + token_length;
    }

  /*allocate memory */
  finalresult = result =
    malloc (strlen (line) + (replacement_length * count) + 1 -
	    (token_length * count));
  if (!result)
    {
      return NULL;		/*out of memory? */
    }

  /*move to beginning of line */
  curr = line;
  for (;;)
    {
      /*determine next location of token */
      tmp = strstr (curr, token);
      if (!tmp)
	break;

      diff = tmp - curr;

      strncpy (result, curr, diff);	/*copy the pre-token part */

      strcpy (result + diff, replacement);	/*copy replacement */

      strcpy (result + diff + replacement_length, tmp + token_length);	/*copy rest of stuff */

      /*move to next token position */
      curr = curr + diff + token_length;
      /*update result position to next replace position */
      result = result + diff + replacement_length;
    }

  return finalresult;
}

/**
* Returns bitrock friendly string
*/
static char *
bitrock_friendly_string (char *str)
{
  char *line1;
  char *line2;
  char *line3;
  char *line4;
  char *final;

  line1 = csar (str, ".", "xxDOTxx");
  line2 = csar (line1, "_", "xxUSxx");
  line3 = csar (line2, "@", "xxATxx");
  line4 = csar (line3, "-", "xxDASHxx");
  final = strdup (line4);

  if (line4 != NULL && line4 != line3)
    {
      free (line4);
    }
  if (line3 != NULL && line3 != line2)
    {
      free (line3);
    }
  if (line2 != NULL && line2 != line1)
    {
      free (line2);
    }
  if (line1 != NULL && line1 != str)
    {
      free (line1);
    }

  return final;
}

/**
 * Main entry point
 */
int
main (int a, char **v)
{
  char *name;
  char *enc;
  char *loc;
  int i;
  int debug = 0;

  if (a > 1)
    {
      if (pg_strcasecmp (v[1], "debug") == 0)
	{
	  debug = 1;
	}
    }
  /*invoke "locales -a" and read output */
  FILE *ostream = popen ("locale -a", "r");
  if (ostream)
    {
      char line[128];
      while (fgets (line, sizeof (line), ostream) != NULL)
	{
	  loc = strdup (line);
	  stripeol (loc);
	  /*XXX: This call fails for locale tt_RU@iqtelif.UTF-8
	   */
	  name = setlocale (LC_CTYPE, loc);
	  if (name)
	    {
	      /* If locale is C or POSIX, simply print them */
	      if (pg_strcasecmp (loc, "C") == 0
		  || pg_strcasecmp (loc, "POSIX") == 0)
		{
		  if (debug)
		    printf ("%s\n", loc);
		  else
		    printf ("%s=%s\n", loc, loc);
		}
	      else
		{
		  enc = nl_langinfo (CODESET);
		  if (enc)
		    enc = strdup (enc);
		  if (!enc)
		    return -1;	/*should not happen - out of memory?? */

		  /*iterate through valid encodings in our list */
		  for (i = 0; encoding_match_list[i].system_enc_name; i++)
		    {
		      if (pg_strcasecmp
			  (enc, encoding_match_list[i].system_enc_name) == 0)
			{
			  if (debug)
			    printf ("%s\n", name);
			  else
			    printf ("%s=%s\n", bitrock_friendly_string (name),
				    name);

			  break;
			}
		    }
#ifdef __darwin__

		  /*
		   *Current OS X has many locales that report an empty string for CODESET,
		   * but they all seem to actually use UTF-8.
		   */
		  if (strlen (enc) == 0)
		    {
		      printf ("%sxxDOTxxUTFxxDASHxx8=%s.UTF-8\n",
			      bitrock_friendly_string (name), name);
		    }
#endif
		  free (enc);
		}
	    }
	  else if (debug)
	    {
	      fprintf (stderr, "Problematic Locale: %s\n ", loc);
	    }

	  free (loc);
	}
      pclose (ostream);
    }

  return 0;
}
