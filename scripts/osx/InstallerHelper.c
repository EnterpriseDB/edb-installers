#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main (int argc, char** argv)
{
  int res, index, argLen, totalLen;
  char process_command[2048] = {0};
  if (argc < 2)
  {
    fprintf(stderr, "Please provide the executable to run.");
    return -1;
  }
  // Change the process to run as root user
  res = setuid(0);
  if (res != 0)
  {
    fprintf(stderr, "Could not change the current process user to root.");
    return res;
  }
  process_command[0] = '\"';
  strncat (process_command, argv[1], 2046);
  totalLen = strlen(process_command);
  process_command[totalLen] = '\"';
  process_command[totalLen + 1] = '\0';
  totalLen += 1;

  for (index=2; index < argc; index++)
  {
    process_command[totalLen] = ' ';
    process_command[totalLen + 1] = '\0';
    strncat(process_command, argv[index], 2047 - totalLen);
    totalLen = strlen(process_command);
  }

  res = 0;
  res = system(process_command);
  printf ("The value returned was: %d.\n", res);
  return 0;
}

