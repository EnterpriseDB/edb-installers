// PostgreSQL server 'get locales' proglet for Windows
// Dave Page, EnterpriseDB

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

/* List of all locales supported by the system */
static char **locale_list = NULL;
size_t num_locales = 0;
size_t locale_len = 1024 * sizeof(char);

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
    char tmp[512] = "";

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
                strcat_s(tmp, sizeof(tmp), "xxATxx");
                break;
            case '-':
                strcat_s(tmp, sizeof(tmp), "xxDASHxx");
                break;
            case '_':
                strcat_s(tmp, sizeof(tmp), "xxUSxx");
                break;
            case '.':
                strcat_s(tmp, sizeof(tmp), "xxDOTxx");
                break;
            case ' ':
                strcat_s(tmp, sizeof(tmp), "xxSPxx");
                break;
            case '(':
                strcat_s(tmp, sizeof(tmp), "xxOBxx");
                break;
            case ')':
                strcat_s(tmp, sizeof(tmp), "xxCBxx");
                break;
            default:
                strncat_s(tmp, sizeof(tmp), language + x, 1);
        }
    }

    strcat_s(tmp, sizeof(tmp), "xxCOMMAxxxxSPxx");

    for (unsigned int x=0; x < strlen(country); x++)
    {
        switch (country[x])
        {
            case '@':
                strcat_s(tmp, sizeof(tmp), "xxATxx");
                break;
            case '-':
                strcat_s(tmp, sizeof(tmp), "xxDASHxx");
                break;
            case '_':
                strcat_s(tmp, sizeof(tmp), "xxUSxx");
                break;
            case '.':
                strcat_s(tmp, sizeof(tmp), "xxDOTxx");
                break;
            case ' ':
                strcat_s(tmp, sizeof(tmp), "xxSPxx");
                break;
            case '(':
                strcat_s(tmp, sizeof(tmp), "xxOBxx");
                break;
            case ')':
                strcat_s(tmp, sizeof(tmp), "xxCBxx");
                break;
            default:
                strncat_s(tmp, sizeof(tmp), country + x, 1);
        }
    }
    
    // Skip locales with ' in the name - we can't use these anyway.
    if (!strstr(tmp, "'"))
    {
        locale_list[num_locales] = (char *)malloc(locale_len);
        ZeroMemory(locale_list[num_locales], locale_len);
        sprintf_s(locale_list[num_locales], locale_len, "%s=%s, %s", tmp, language, country);

        // Add another element to the locale list
        num_locales++;
        locale_list = (char **)realloc(locale_list, (num_locales + 1) * sizeof(*locale_list));
        if (!locale_list)
            return FALSE;
    }

    free(language);
    free(country);
    
    return TRUE;
}

// String comparison function for qsort
int cstring_cmp(const void *a, const void *b)
{
    const char **ia = (const char **)a;
    const char **ib = (const char **)b;

    return strcmp(*ia, *ib);
}

int main(int argc, char *argv[])
{
    // Check the command line
    if (argc != 1)
    {
        fprintf(stderr, "Usage: %s\n", argv[0]);
        return 127;
    }
    
    // Setup the array
    locale_list = (char **)malloc((num_locales + 1) * sizeof(*locale_list));
    if (!locale_list)
    {
        fprintf(stderr, "Failed to allocate memory for the locale list\n");
        return 3;
    }

    if (!EnumSystemLocales(&process_installed_locales, LCID_INSTALLED))
            return 2;

    // If we see a NULL locale_list here, it's because the realloc failed.
    if (!locale_list)
    {
        fprintf(stderr, "Failed to allocate memory for the locale list\n");
        return 3;
    }

    // Sort the array
    qsort(locale_list, num_locales, sizeof(char *), cstring_cmp);

    // Print the output array
    for (unsigned int x=0; x < num_locales; x++)
        fprintf(stdout, "%s\n", locale_list[x]);

    return 0;
}


