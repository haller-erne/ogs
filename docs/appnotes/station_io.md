---
id: station_io
name: Station IO
title: Station IO
tags:
    - appnote
---

# Station IO

## Overview

Many times, a real world installation of OGS needs to interact with external sensors and actuators. Typical samples are external push buttons (to acknowledge an operation) connected to a remote I/O module or positioning sensors connected over EtherNet/IP.

To simplify access to external IO, OGS provides two generic LUA modules to interact with Modbus/TCP and EtherNet/IP based remote IO devices.

These modules provide the following:

- Configuration of the devices (like IP address and register scanlist) in `station.ini`
- Cyclic data exchange in the background (not blocking LUA processing)
- A LUA interface to add application specific code for mapping input/output data and connecting the physical IOs to a logical OGS function 

Currently the following modules are available (see below for more details on using them):

- `station_io_enip.lua`: Handle Ethernet/IP remote IO devices using a class 1 (implicit) connection. IP addresses are configurable through station.ini. A set of 'known' devices is included, but others can be added (by specifying the CIP forward open parameters).
- `station_io_modbus.lua`: Handle Modbus/TCP remote I/O devices. IP addresses and scan list (registers to be scanned cyclically) are configurable through station.ini.

!!! Info

    Note, that you can also use the OpenProtocol custom IO signals for IO. This is not covered here, see the [OpenProtocol tools](/ogs/tools/openprotocol/) section for more information.

## Usage

The recommended way to use the station IO modules is to create a station specific `station_io.lua` file and add this to the `config.lua` requires list.



## station_io_enip



## station_io_modbus



1. When starting a workflow, read the part/job state 
2. When finishing a workflow, write the part/job state

Reading and writing the part/job state can be implemented in LUA. Therefore almost any backed system can be used to access and store the parts current build state.

Typical use cases are:

- Rework stations (usually having the workflows of multiple stations combined into a single, large workflow).
- EOL-Checks (end of line checks): Can be used to selectively check single tasks from the assembly stations and visualize these to the operator and add additional (plausibility) checks.

A default implementation using a Microsoft SQL server backend is available and described here.

## Default SQL Server implementation

### Overview

The SQL server default databanking implementation identifies and stores data by combining then following properties and using it as a key for data retrieval:

- Part serial number
- Job name
- Task name

??? example "Sample rework scenario"

    ### Example

    Say `station 1` processes the part with the serial `123456` as follows:

    | Jobs     | Tasks    | Result |
    | -------- | -------- | ------ |
    | S1 Job 1 | Task 1.1 | OK |
    | S1 Job 2 | Task 2.1 | OK |
    |          | Task 2.1 | NOK |
    | S1 Job 3 | Task 3.1 | not completed|

    Say the rework station `station 5` is configured to rework all jobs as follows:

    | Jobs     | Tasks    | 
    | -------- | -------- | 
    | S1 Job 2 | Task 2.1 | 
    |          | Task 2.1 | 
    | S1 Job 3 | Task 3.1 | 
    | S2 Job 1 | Task 4.1 | 
    | S3 Job 1 | Task 5.1 | 
    | S4 Job 1 | Task 6.1 | 

    If the part with the serial `123456` is scanned in `station 5` (assume due to being NOK in `station 1` it is directly routed to the rework station `station 5`), it now shows up as follows in the OGS process screen (current part status was loaded from the databanking SQL server):

    | Jobs     | Tasks    | Result |
    | -------- | -------- | ------ |
    | S1 Job 2 | Task 2.1 | OK |
    |          | Task 2.1 | NOK |
    | S1 Job 3 | Task 3.1 | not completed |
    | S2 Job 1 | Task 4.1 | not completed |
    | S3 Job 1 | Task 5.1 | not completed |
    | S4 Job 1 | Task 6.1 | not completed |



!!! Info

    - All data is retrieved by using the key `[part serial number]:[Job name]:[Task name]`, so the rework station shows the exact part/task status of the previous operations
    - The rework station does not need to have all jobs/tasks defined identically to the original stations (e.g. S1 Job 1 is not defined in the example rework config shown above). Setup just what you need!


### Server requirements

A Microsoft SQL server database must be available and accessible from each OGS station using databanking. As OGS accesses the data every time a workflow is started and completed, a reliable and fast network connection to the database server is very important.

Supported SQL server versions are: 2019, 2022.

### Client Requirements

Databanking is fully supported with OGS >= V3.0.

Additional software components required:

- SQL Server native client 11 ([SNAC/SQLNCLI](https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/installing-sql-server-native-client)) or SQL Server OLE DB driver ([MSOLEDBSQL](https://learn.microsoft.com/en-us/sql/connect/oledb/oledb-driver-for-sql-server)). <span style="color:red">NOTE: On an x64 operating system, the x64 versions od the database drivers must be used!</span> 

### Installation

To install follow the steps outlined in the next sections. All files mentioned are available from the public [OGS GitHub repository](https://github.com/haller-erne/ogs/tree/main/samples/databanking).

#### SQL Server Schema

Use the [OGS_Databanking.dacpac](https://github.com/haller-erne/ogs/raw/main/samples/databanking/OGS_Databanking.dacpac) file to install the database schema required by the default databanking implementation. See [Microsofts documentation on how to import a dacpac file](https://learn.microsoft.com/en-us/sql/relational-databases/data-tier-applications/data-tier-applications) for more information.

#### Integrate databanking into OGS Project 

To integrate databanking into your OGS project, the following changes to the project are needed:

1. Add the [databanking.lua](https://github.com/haller-erne/ogs/raw/main/samples/databanking/databanking.lua) file to your project by adding it into the `requires` table in your projects `config.lua` file.
2. Modify your `station.ini` file to add the database connection information in the `[DATABANKING]` section to the `ConnectionString=` parameter. Here is a sample (using SQL server native client, see [Connection strings below](#database-connection-strings) for more info):

    ``` ini
    [DATABANKING]
    ConnectionString=Provider=SQLNCLI11.1;User ID=<my-user>;Password=<my-pass>;Initial Catalog=<my-db>;Data Source=<my-server>\<my-instance>[,server-port]
    ```

!!! info

    To use an encrypted database connection string, see [database connection strings below](#database-connection-strings).


### Database connection strings

The databanking setup in this sample uses Microsoft ADO to connect to the database. It therefore is not limited to Microsoft SQL server, but works with all databases providing ODBC or OleDB database drivers.

To prevent information leakage, you can also use encrypted database connection strings. This works by encrypting the plaintext connection string with Microsofts data protection API using the machine key of the current system. As this ties the encrypted string to the physical machine, copies of the configureation file cannot be decrypted on another machine. See [sample powershell command for encryption](https://haller-erne.github.io/ogs/libs/lua-dpapi/#sample-powershell-commandlet-for-encryption) on how to encrypt a plaintext string for use with OGS.

For Microsoft SQL server, there are multiple options for connecting to the database, supported are the (old) SQL server native client and the current SQL server OleDB driver. These are described in more detail in the following section.

!!! info

    To workaround missing or invalid server certificates, add `Encrypt=false;` and/or `TrustServerCertificate=false;` to the connection string.


#### SQL Server OleDB driver (MSOLEDBSQL)

Here is a sample connection string using the SQL server native client 11:

``` ini
[DATABANKING]
ConnectionString=Provider=MSOLEDBSQL;Data Source=<my-server>\<my-instance>[,server-port];Initial Catalog=<my-db>;User ID=<my-user>;Password=<my-pass>;
```

A quick reference to the parameters can be found at [connectionstrings.com](https://www.connectionstrings.com/ole-db-driver-for-sql-server/) or in the [official Microsoft documentation](https://learn.microsoft.com/en-us/sql/connect/oledb/oledb-driver-for-sql-server).

#### SQL Server native client (SNAC/SQLNCLI)

Here is a sample connection string using the SQL server native client 11:

``` ini
[DATABANKING]
ConnectionString=Provider=SQLNCLI11.1;Data Source=<my-server>\<my-instance>[,server-port];Initial Catalog=<my-db>;User ID=<my-user>;Password=<my-pass>;
```

A quick reference to the parameters can be found at [connectionstrings.com](https://www.connectionstrings.com/sql-server-native-client-11-0-oledb-provider/) or in the [official Microsoft documentation](https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/installing-sql-server-native-client).


## Custom implementations

_TODO: describe the LUA functions used for databanking._
