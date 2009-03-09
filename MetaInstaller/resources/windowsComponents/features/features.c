#include <stdio.h>
#include <windows.h>

int
main(int argc, char *argv[])
{
	int feature_count = 0;
	char * feature_string[500];
	
	memset (feature_string, '\0', sizeof(feature_count));
	
	if(argc != 6)
	{
		printf("Leaving, in complete arguments\n");
		return 1;
	}
	
	
	
	
	// Arg-1
	if(!strcmp(argv[1], "1"))
	{
		strcat(feature_string, "DBServer");
		feature_count++;
	}
	
	// Arg-2
	if(!strcmp(argv[2], "1"))
	{
		if(feature_count > 0)
			strcat(feature_string, ",Slony");
		else
			strcat(feature_string, "Slony");
		
		feature_count++;
	}
	
	// Arg-3
	if(!strcmp(argv[3], "1"))
	{
		if(feature_count > 0)
			strcat(feature_string, ",pgJdbc");
		else
			strcat(feature_string, "pgJdbc");
			
		feature_count++;
	
	}
	
	
	// Arg-4
	if(!strcmp(argv[4], "1"))
	{
		if(feature_count > 0)
			strcat(feature_string, ",postGIS");
		else
			strcat(feature_string, "postGIS");	
		
		feature_count++;

	}
	
	// Arg-5
	if(!strcmp(argv[5], "1"))
	{
		if(feature_count > 0)
			strcat(feature_string, ",psqlODBC");
		else
			strcat(feature_string, "psqlODBC");
			
		
		feature_count++;

	}
	
	
	printf("%s\n", feature_string);
	
	
	//return regression_main(argc, argv, psql_init, psql_start_test);
	return 0;
}
