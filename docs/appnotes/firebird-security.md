# Firebird database configuration

## Overview

The Firebird database server is used by OGS to store configuration and result data. Typically, there are two databases involved:
- Station database. This is typically used on the station as follows:
    - Monitor.exe: The OGS runtime reads the workflow configuration and writes the result data (part results)
    - heOpImp.exe: The OGS project import utility writes updated configuration into the station database
- Configuration database. This is used to store the workflow configuration data. This is typically used as follows:
    - heOpCfg.exe: The OGS workflow editor reads from and writes to the database. The database can be local or remote, for a remote database, heOpCfg uses two application roles to access the data ("editor" and "admin")
    - heOpImp.exe: The OGS project import utility reads from this database.

The station database usually is hosted on the station PC and does not need access from the outside ("local server"). The location of the configuration database might be local or remote, so the "remote" database server needs network access.

## Network communication

The Firebird database server by default listens on TCP/3050 for client requests. The server can be configured (in `firebird.conf`) for different authentication, authorization and encryption schemes using plugins.

Access over the network can be configured by setting up firewall rules on the database server accordingly.

Typical options are:
- username/password authentication
- active directory integrated authentication
- mapping roles to rights, mapping users and groups to roles
- encrypted communication


## Setting a Firebird server up for Window authentication

### Installing steps

While installing the Firebird server, the installer asks for a `SYSDBA` password. The `SYSDBA` user is a builtin "superuser", which has all rights to manage the database.

!!! info 

    Make sure to change the password! Note also, that we will disable the SYSDBA access in the next steps (users with physical access to the `database.conf` on the server can always reset/restore access).



