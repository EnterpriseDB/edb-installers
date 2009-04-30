#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <rpc.h>
#include <string.h>
#pragma comment(lib, "rpcrt4.lib")

RPC_CSTR genguid() {

UUID uuid;
RPC_CSTR str;

// create UUID
UuidCreate(&uuid);

// create ansi string like "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

UuidToStringA(&uuid, &str);

return str;


}

int main(){

char *dbserver_guid=genguid();

printf("dbser_guid=%s",dbserver_guid);
return 0;

}