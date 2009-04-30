#include <stdio.h>
#include <string.h>

int
main(int argc, char *argv[])
{
	int feature_count = 0;
	char * feature_string[500];
	
	memset (feature_string, '\0', (int)sizeof(feature_count));
	
	if(argc != 10)
	{
		printf("Leaving, in complete arguments\n");
		return 1;
	}
	
	
	
	
	// Arg-1
	if(!strcmp(argv[1], "1"))
	{
		strcat((char*)feature_string, "DBServer");
		feature_count++;
	}
	
	// Arg-2
	if(!strcmp(argv[2], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",Slony");
		else
			strcat((char*)feature_string, "Slony");
		
		feature_count++;
	}
	
	// Arg-3
	if(!strcmp(argv[3], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",pgJdbc");
		else
			strcat((char*)feature_string, "pgJdbc");
			
		feature_count++;
	
	}
	
	
	// Arg-4
	if(!strcmp(argv[4], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",postGIS");
		else
			strcat((char*)feature_string, "postGIS");	
		
		feature_count++;

	}
	
	// Arg-5
	if(!strcmp(argv[5], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",psqlODBC");
		else
			strcat((char*)feature_string, "psqlODBC");
			
		
		feature_count++;

	}

	// Arg-6
	if(!strcmp(argv[6], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",Npgsql");
		else
			strcat((char*)feature_string, "Npgsql");
			
		
		feature_count++;

	}

	// Arg-7
	if(!strcmp(argv[7], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",pgbouncer");
		else
			strcat((char*)feature_string, "pgbouncer");
			
		
		feature_count++;

	}

	// Arg-8
	if(!strcmp(argv[8], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",pgmemcache");
		else
			strcat((char*)feature_string, "pgmemcache");
			
		
		feature_count++;

	}

	// Arg-9
	if(!strcmp(argv[9], "1"))
	{
		if(feature_count > 0)
			strcat((char*)feature_string, ",pgAgent");
		else
			strcat((char*)feature_string, "pgAgent");
			
		
		feature_count++;

	}
	
	
	printf("%s\n", feature_string);
	
	
	//return regression_main(argc, argv, psql_init, psql_start_test);
	return 0;
}
