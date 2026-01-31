# Low level database access

OGS provides two interfaces to access SQL databases:

- Access to the "local" `station.fds` database through the Firebird API
- Access to any other database using `ADO` 

## Local station.fds interface

The "local" database access is automatically initialized and only allows to access the `station.fds`. Note, that this connection is shared with the OGS core and also used by the core.

The following functions are available:

- asdasd
- asdasd


## ADO interface

The ADO interface allows connections to any other database, as long as OleDB or ODBC drivers are installed. As OGS is (currently) a 32-Bit application, it also uses the 32-Bit OleDB/ODBC drivers.

### Microsoft SQL Server

### Firebird Server

To access a Firebird database using the ADO interface, the "official" [Firebird ODBC Driver](https://github.com/FirebirdSQL/firebird-odbc-driver) is used together with the [Microsoft OLE DB Provider for ODBC](https://learn.microsoft.com/de-de/office/client-developer/access/desktop-database-reference/microsoft-ole-db-provider-for-odbc).

The driver can be used by either creating a datasource (DSN) using the `ODBC-Datasources (32-Bit)` editor or by directly specifying all parameters in the connection string. 

#### Full connection

A full connection string is specified as follows:

    Driver=Firebird ODBC Driver;UID=SYSDBA;PWD=masterkey;DBNAME=C:\path\mydatabase.fdb



#### DSN connection

To use a DSN, one must be created first. To do so, start the `ODBC-Datasources (32-Bit)` from the Windows start menu and create a new DSN: 

![alt text](2026-01-31_18h02_29.png)

The connection string then is as follows:

    'Provider=MSDASQL.1;Persist Security Info=False;Data Source=Iveco'
