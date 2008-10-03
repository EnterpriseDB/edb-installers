// PostgreSQL server 'get locales' proglet for Windows
// Dave Page, EnterpriseDB

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

/* List of all locales supported by the system */
static 
char **locales_list = NULL;

/*
 * translates received lpLocaleString to a proper locale name and appends it
 * at the end of locales_list if it is not yet a member of the list
 */
static
BOOL CALLBACK process_installed_locales(LPTSTR lpLocaleString)
{
	unsigned long locale_id;
	int len_language;
	int len_country;
	char *language;
	char *country;
	char output[512] = "";

	locale_id = strtoul(lpLocaleString, NULL, 16);

	len_language = GetLocaleInfo(locale_id, LOCALE_SENGLANGUAGE, NULL, 0);
	len_country = GetLocaleInfo(locale_id, LOCALE_SENGCOUNTRY, NULL, 0);

	language = (char *)malloc((len_language + 1) * sizeof(char));
	country  = (char *)malloc((len_country + 1) * sizeof(char));

	if (!language || !country)
	{
            fprintf(stderr, "Failed to allocate memory for the locale data.");
	    return FALSE;
	}

	ZeroMemory(language, (len_language+1) * sizeof(char));
	ZeroMemory(country, (len_country+1) * sizeof(char));
    
	GetLocaleInfo(locale_id, LOCALE_SENGCOUNTRY, country, len_country);
	GetLocaleInfo(locale_id, LOCALE_SENGLANGUAGE, language, len_language);

	for (unsigned int x=0; x < strlen(language); x++)
	{
		switch (language[x])
		{
			case '@':
				strcat_s(output, sizeof(output), "xxATxx");
				break;
			case '-':
				strcat_s(output, sizeof(output), "xxDASHxx");
				break;
			case '_':
				strcat_s(output, sizeof(output), "xxUSxx");
				break;
			case '.':
				strcat_s(output, sizeof(output), "xxDOTxx");
				break;
			case ' ':
				strcat_s(output, sizeof(output), "xxSPxx");
				break;
			case '(':
				strcat_s(output, sizeof(output), "xxOBxx");
				break;
			case ')':
				strcat_s(output, sizeof(output), "xxCBxx");
				break;
			default:
				strncat_s(output, sizeof(output), language + x, 1);
		}
	}

	strcat_s(output, sizeof(output), "xxCOMMAxxxxSPxx");

	for (unsigned int x=0; x < strlen(country); x++)
	{
		switch (country[x])
		{
			case '@':
				strcat_s(output, sizeof(output), "xxATxx");
				break;
			case '-':
				strcat_s(output, sizeof(output), "xxDASHxx");
				break;
			case '_':
				strcat_s(output, sizeof(output), "xxUSxx");
				break;
			case '.':
				strcat_s(output, sizeof(output), "xxDOTxx");
				break;
			case ' ':
				strcat_s(output, sizeof(output), "xxSPxx");
				break;
			case '(':
				strcat_s(output, sizeof(output), "xxOBxx");
				break;
			case ')':
				strcat_s(output, sizeof(output), "xxCBxx");
				break;
			default:
				strncat_s(output, sizeof(output), country + x, 1);
		}
	}
	
	// Skip locales with ' in the name - we can't use these anyway.
	if (!strstr(output, "'"))
	    sprintf_s(output, sizeof(output), "%s=%s, %s", output, language, country);

	printf("%s\n", output);

	free(language);
	free(country);
    
	return TRUE;
}

int main(int argc, char *argv[])
{
	// Check the command line
	if (argc != 1)
	{
		fprintf(stderr, "Usage: %s\n", argv[0]);
		return 127;
	}
	
	if (!EnumSystemLocales(&process_installed_locales, LCID_INSTALLED))
            return 2;

	fprintf(stdout, "%s ran to completion\n", argv[0]);
	return 0;
}


