#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
	#include <windows.h>
#else
	#include <stdarg.h>
#endif


char* parameters[17][500];
//FILE *stream;

// This the order in which 'parameters' array stores values
// of arguments.
/*
	parameters[0] = autovacuum 
	parameters[1] = autovacuum_naptime 
	parameters[2] = autovacuum_vacuum_threshold 
	parameters[3] = autovacuum_analyze_threshold
	parameters[4] = autovacuum_vacuum_scale_factor
	parameters[5] = autovacuum_analyze_scale_factor
	parameters[6] = checkpoint_segments 
	parameters[7] = effective_cache_size 
	parameters[8] = maintenance_work_mem 
	parameters[9] = max_fsm_pages 
	parameters[10] = max_fsm_relations 
	parameters[11] = random_page_cost 
	parameters[12] = shared_buffers 
	parameters[13] = wal_buffers 
	parameters[14] = work_mem 
	parameters[15] = max_connections
	parameters[16] = stats_row_level
*/


char* autovacuum[] = {"autovacuum = ", "			# Enable autovacuum subprocess?  'on'"};
char* autovacuum_naptime[] = {"autovacuum_naptime = ", "		# time between autovacuum runs"};
char* autovacuum_vacuum_threshold[] = { "autovacuum_vacuum_threshold = ", "	# min number of row updates before"};
char* autovacuum_analyze_threshold[] = { "autovacuum_analyze_threshold = ", "	# min number of row updates before"};
char* autovacuum_vacuum_scale_factor[] = {"autovacuum_vacuum_scale_factor = ", "	# fraction of table size before vacuum"};
char* autovacuum_analyze_scale_factor[] = {"autovacuum_analyze_scale_factor = ", "	# fraction of table size before analyze"};
char* checkpoint_segments []= {"checkpoint_segments = ","		# in logfile segments, min 1, 16MB each"};
char* effective_cache_size[]= {"effective_cache_size = ", " "};
char* maintenance_work_mem[] = {"maintenance_work_mem = ", "		# min 1MB"};
char* max_fsm_pages[] = {"max_fsm_pages = ", "			# min max_fsm_relations*16, 6 bytes each"};
char* max_fsm_relations[] = {"max_fsm_relations = ", "		# min 100, ~70 bytes each"};
char* random_page_cost[] = {"random_page_cost = ","			# same scale as above"};
char* shared_buffers []= {"shared_buffers = ", "			# min 128kB or max_connections*16kB"};
char* wal_buffers[] = {"wal_buffers = ","			# min 32kB"};
char* work_mem []= {"work_mem = ","				# min 64kB"};
char* max_connections []= {"max_connections = ","		# (change requires restart)"};
char* stats_row_level []= {"stats_row_level = "," "};


char* appendString(char* line, char* indicator);



//
// Assigns memory to a buffer of the size of the string 
// passed in str and returns the string.
//
char * make_str(const char *str)
{
	char * res_str = (char *) malloc(strlen(str) + 1);
	strcpy_s(res_str,1000, str);
	return res_str;
}



//
// Returns a FILE pointer to the file specified by 'src_fileName' path.
//
FILE * openFile (char* src_fileName)
{
	FILE * fptr = NULL;
	errno_t err;
	if((err = fopen_s(&fptr,src_fileName, "r+")) !=0)
	{
		printf("File open error\n");
		return NULL;
	}
	return fptr;
}


//
// Returns a FILE pointer to the file specified by 'src_fileName', 
// the file is opened in write mode.
//
FILE * openFileWrite (char* src_fileName)
{
	FILE * fptr = NULL;
	errno_t err;
	if((err = fopen_s(&fptr,src_fileName, "w")) !=0)
	{
		printf("File open error\n");
		return NULL;
	}
	return fptr;
}


/*
 * string concatenation
 */
static char *
cat2_str(char *str1, char *str2)
{
	char * res_str = (char*) malloc(strlen(str1) + strlen(str2) + 2);
	strcpy_s(res_str,1000, str1);
	strcat_s(res_str,1000, str2);
	
	if(str1)
		free(str1);
	if(str2)
		free(str2);
	return(res_str);
}



//
// Concatenate 'count' number of substrings.
//
static char *
cat_str(int count, ...)
{
	va_list		args;
	int			i;
	char		*res_str;

	va_start(args, count);

	res_str = va_arg(args, char *);

	/* now add all other strings */
	for (i = 1; i < count; i++)
		res_str = cat2_str(res_str, va_arg(args, char *));

	va_end(args);

	return(res_str);
}


//
// Scans 'fptr' stream for targetted strings are replace them.
// The result strings are written to 'fptrWrite' stream.
//
int search_String (FILE* fptr, FILE* fptrWrite)
{
	//int resultBytes = 0;
	char* character = NULL;
	char line[1000];
	int error_num = 0;
	char* outputStr = NULL;


	memset(line, '\0', sizeof(line));
	
       
	while(((character = fgets(line, 1000, fptr)) != NULL))
	{
		// max_connections 
		if((character = strstr(line, "max_connections =")) != NULL)
		{
			outputStr = appendString(line, "max_connections");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "autovacuum_naptime =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum_naptime =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "autovacuum_vacuum_threshold =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum_vacuum_threshold =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}

		else if((character = strstr(line, "autovacuum_analyze_threshold =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum_analyze_threshold =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}

		else if((character = strstr(line, "autovacuum_vacuum_scale_factor =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum_vacuum_scale_factor =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}

		else if((character = strstr(line, "autovacuum_analyze_scale_factor =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum_analyze_scale_factor =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "autovacuum =")) != NULL)
		{
			outputStr = appendString(line, "autovacuum =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}

		else if((character = strstr(line, "checkpoint_segments =")) != NULL)
		{
			outputStr = appendString(line, "checkpoint_segments =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "effective_cache_size =")) != NULL)
		{
			outputStr = appendString(line, "effective_cache_size =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "maintenance_work_mem =")) != NULL)
		{
			outputStr = appendString(line, "maintenance_work_mem =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "max_fsm_pages =")) != NULL)
		{
			outputStr = appendString(line, "max_fsm_pages =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "max_fsm_relations =")) != NULL)
		{
			outputStr = appendString(line, "max_fsm_relations =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "random_page_cost =")) != NULL)
		{
			outputStr = appendString(line, "random_page_cost =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "shared_buffers =")) != NULL)
		{
			outputStr = appendString(line, "shared_buffers =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "wal_buffers =")) != NULL)
		{
			outputStr = appendString(line, "wal_buffers =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "work_mem =")) != NULL)
		{
			outputStr = appendString(line, "work_mem =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}
		else if((character = strstr(line, "stats_row_level =")) != NULL)
		{
			outputStr = appendString(line, "stats_row_level =");
			error_num = fputs(outputStr, fptrWrite);

				if ( error_num < 0)
				{
					printf("Error occured while writing to file...\n");
					return -1;
				}
				
				free(outputStr);
				outputStr = NULL;
		}

		// If no matches, then dump the line as it is.
		else
		{
			error_num = fputs(line, fptrWrite);

			if ( error_num < 0)
			{
				printf("Error occured while writing to file...\n");
				return -1;
			}
		}
		
		memset(line, 0, sizeof(line));
	}

	return 1;
}


char*
appendString(char* line, char* indicator)
{
	char* outputStr = NULL;
 const char* n="\n";

	if(strstr(indicator, "max_connections") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)max_connections[0]), make_str((const char*)parameters[15]), make_str((const char*)max_connections[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)max_connections[0]), make_str((const char*)parameters[15]), make_str((const char*)max_connections[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum_naptime") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum_naptime[0]), make_str((const char*)parameters[1]), make_str((const char*)autovacuum_naptime[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)parameters[1]), make_str((const char*)autovacuum_naptime[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum_vacuum_threshold") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum_vacuum_threshold[0]), make_str((const char*)parameters[2]), make_str((const char*)autovacuum_vacuum_threshold[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)autovacuum_vacuum_threshold[0]), make_str((const char*)parameters[2]), make_str((const char*)autovacuum_vacuum_threshold[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum_analyze_threshold") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum_analyze_threshold[0]), make_str((const char*)parameters[3]), make_str((const char*)autovacuum_analyze_threshold[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)autovacuum_analyze_threshold[0]), make_str((const char*)parameters[3]), make_str((const char*)autovacuum_analyze_threshold[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum_vacuum_scale_factor") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum_vacuum_scale_factor[0]), make_str((const char*)parameters[4]), make_str((const char*)autovacuum_vacuum_scale_factor[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)autovacuum_vacuum_scale_factor[0]), make_str((const char*)parameters[4]), make_str((const char*)autovacuum_vacuum_scale_factor[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum_analyze_scale_factor") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum_analyze_scale_factor[0]), make_str((const char*)parameters[5]), make_str((const char*)autovacuum_analyze_scale_factor[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)autovacuum_analyze_scale_factor[0]), make_str((const char*)parameters[5]), make_str((const char*)autovacuum_analyze_scale_factor[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "autovacuum") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)autovacuum[0]), make_str((const char*)parameters[0]), make_str((const char*)autovacuum[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)autovacuum[0]), make_str((const char*)parameters[0]), make_str((const char*)autovacuum[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "checkpoint_segments") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)checkpoint_segments[0]), make_str((const char*)parameters[6]), make_str((const char*)checkpoint_segments[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)checkpoint_segments[0]), make_str((const char*)parameters[6]), make_str((const char*)checkpoint_segments[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "effective_cache_size") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)effective_cache_size[0]), make_str((const char*)parameters[7]), make_str((const char*)effective_cache_size[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)effective_cache_size[0]), make_str((const char*)parameters[7]), make_str((const char*)effective_cache_size[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "maintenance_work_mem") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)maintenance_work_mem[0]), make_str((const char*)parameters[8]), make_str((const char*)maintenance_work_mem[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)maintenance_work_mem[0]), make_str((const char*)parameters[8]), make_str((const char*)maintenance_work_mem[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "max_fsm_pages") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)max_fsm_pages[0]), make_str((const char*)parameters[9]), make_str((const char*)max_fsm_pages[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)max_fsm_pages[0]), make_str((const char*)parameters[9]), make_str((const char*)max_fsm_pages[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "max_fsm_relations") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)max_fsm_relations[0]), make_str((const char*)parameters[10]), make_str((const char*)max_fsm_relations[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)max_fsm_relations[0]), make_str((const char*)parameters[10]), make_str((const char*)max_fsm_relations[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "random_page_cost") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)random_page_cost[0]), make_str((const char*)parameters[11]), make_str((const char*)random_page_cost[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)random_page_cost[0]), make_str((const char*)parameters[11]), make_str((const char*)random_page_cost[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "shared_buffers") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)shared_buffers[0]), make_str((const char*)parameters[12]), make_str((const char*)shared_buffers[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)shared_buffers[0]), make_str((const char*)parameters[12]), make_str((const char*)shared_buffers[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "wal_buffers") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)wal_buffers[0]), make_str((const char*)parameters[13]), make_str((const char*)wal_buffers[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)wal_buffers[0]), make_str((const char*)parameters[13]), make_str((const char*)wal_buffers[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "work_mem") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)work_mem[0]), make_str((const char*)parameters[14]), make_str((const char*)work_mem[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)work_mem[0]), make_str((const char*)parameters[14]), make_str((const char*)work_mem[1]), make_str(n));
			}
	}
	else if(strstr(indicator, "stats_row_level") != NULL)
	{
			if(line[0] == '#')
			{
				outputStr = cat_str(5, make_str((const char*)line), make_str((const char*)stats_row_level[0]), make_str((const char*)parameters[16]), make_str((const char*)stats_row_level[1]), make_str(n));
			}
			else
			{
				outputStr = cat_str(6, make_str((const char*)"#"), make_str((const char*)line), make_str((const char*)stats_row_level[0]), make_str((const char*)parameters[16]), make_str((const char*)stats_row_level[1]), make_str(n));
			}
	}


	return outputStr;
}



int main (int argc, char* argv[])
{
	FILE * fptrBackfile = NULL;
	FILE * fptrOutput = NULL;
	//FILE * temp_fptr  = NULL;

	char *backupFileName  = NULL;
	char *outputFileName  = NULL;

	//char* postgres_conf_Path = NULL;
	int i = 0;
	int error_Number = 0;


	if(argc != 19)
	{
		printf("Invalid number of arguments supplied ...\n");
		return 0;
	}

	memset(parameters, 0, sizeof(parameters));

	i = 0;

	// Scan for 17 parameters excluding the first two (which are
	// application-name and postgresql.conf path)
	while(i < 17)
	{
		strcpy_s((char*)parameters[i],1000, argv[i+2]);
		i++;
	}

	

	outputFileName = make_str(argv[1]);
	backupFileName = cat_str(2, make_str(outputFileName), make_str(".backup"));


	if(rename(outputFileName, backupFileName ) == 0)
	{
		printf("Backup file created '%s'.\n", backupFileName);
	}
	else
	{
		printf("File backup failed.\n");
		printf("Reverting all changes before leaving application ...\n");
		return 1;

	}

	// Open in read mode.
	fptrBackfile = openFile (backupFileName);

	if (fptrBackfile == NULL)
	{
		printf("File open failed, Leaving ...\n");
		return 0;
	}

	fptrOutput = openFileWrite (outputFileName);
	if (fptrOutput == NULL)
	{
		printf("File open failed, Leaving ...\n");
		return 0;
	}

	// Seek a string and return its pointer.
	error_Number = search_String(fptrBackfile, fptrOutput);

	if(error_Number < 1)
	{
		printf("Reverting all changes before leaving application ...\n");

		// TODO: Delete the newly created file (postgresql.conf) and
		//		 rename the postgresql.conf.backup to postgresql.conf.
		printf("Revert failed!\n");

		return 1;
	}
	else
	{
		printf("Cofiguration file '%s' has been updated.\n", outputFileName);
	}


	fflush(fptrOutput);
	fclose(fptrOutput);

	return 0;
}
