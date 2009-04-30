#include <stdio.h>
#include <string.h>
#include <windows.h>
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
		strcat_s((char*)feature_string,256, "DBServer");
		feature_count++;
	}
	
	// Arg-2
	if(!strcmp(argv[2], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",Slony");
		else
			strcat_s((char*)feature_string,256, "Slony");
		
		feature_count++;
	}
	
	// Arg-3
	if(!strcmp(argv[3], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",pgJdbc");
		else
			strcat_s((char*)feature_string,256, "pgJdbc");
			
		feature_count++;
	
	}
	
	
	// Arg-4
	if(!strcmp(argv[4], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",postGIS");
		else
			strcat_s((char*)feature_string,256, "postGIS");	
		
		feature_count++;

	}
	
	// Arg-5
	if(!strcmp(argv[5], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",psqlODBC");
		else
			strcat_s((char*)feature_string,256, "psqlODBC");
			
		
		feature_count++;

	}

	// Arg-6
	if(!strcmp(argv[6], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",Npgsql");
		else
			strcat_s((char*)feature_string,256, "Npgsql");
			
		
		feature_count++;

	}

	// Arg-7
	if(!strcmp(argv[7], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",pgbouncer");
		else
			strcat_s((char*)feature_string,256, "pgbouncer");
			
		
		feature_count++;

	}

	// Arg-8
	if(!strcmp(argv[8], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",pgmemcache");
		else
			strcat_s((char*)feature_string,256, "pgmemcache");
			
		
		feature_count++;

	}

	// Arg-9
	if(!strcmp(argv[9], "1"))
	{
		if(feature_count > 0)
			strcat_s((char*)feature_string,256, ",pgAgent");
		else
			strcat_s((char*)feature_string,256, "pgAgent");
			
		
		feature_count++;

	}
	
	
	printf("%s\n", feature_string);
	
	
	//return regression_main(argc, argv, psql_init, psql_start_test);
	return 0;
}
