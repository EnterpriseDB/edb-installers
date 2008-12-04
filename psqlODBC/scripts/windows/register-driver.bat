@ECHO OFF

odbcconf /a {REGSVR "@@INSTALL_DIR@@\bin\psqlodbc35w.dll"} /a {INSTALLDRIVER "PostgreSQL ODBC Driver(UNICODE)|Driver=@@INSTALL_DIR@@\bin\psqlodbc35w.dll|APILevel=1|ConnectFunctions=YYN|DriverODBCVer=@@VERSION@@|FileUsage=0|Setup=@@INSTALL_DIR@@\bin\psqlodbc35w.dll|SQLLevel=1||"}

odbcconf /a {REGSVR "@@INSTALL_DIR@@\bin\psqlodbc30a.dll"} /a {INSTALLDRIVER "PostgreSQL ODBC Driver(ANSI)|Driver=@@INSTALL_DIR@@\bin\psqlodbc30a.dll|APILevel=1|ConnectFunctions=YYN|DriverODBCVer=@@VERSION@@|FileUsage=0|Setup=@@INSTALL_DIR@@\bin\psqlodbc30a.dll|SQLLevel=1||"}
