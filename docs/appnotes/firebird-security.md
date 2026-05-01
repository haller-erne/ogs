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

### Overview

### Installing steps

While installing the Firebird server, the installer asks for a `SYSDBA` password. The `SYSDBA` user is a builtin "superuser", which has all rights to manage the database.

!!! info 

    Make sure to change the password! Note also, that we will disable the SYSDBA access in the next steps (users with physical access to the `database.conf` on the server can always reset/restore access).
    See [change SYSDBA password](https://www.firebirdsql.org/file/documentation/html/en/firebirddocs/qsg5/firebird-5-quickstartguide.html#qsg5-config-gsec-changepw).

See [Firebird configuration reference](https://www.firebirdsql.org/docs/html/en/refdocs/fbconf/firebird-configuration-reference.html).

### Setting up trusted authentication

See [Configuring trusted authentication](https://ib-aid.com/download/docs/fb4migrationguide.html#_configuring_trusted_authentication).
See [README.trusted_authentication](https://github.com/FirebirdSQL/firebird/blob/master/doc/README.trusted_authentication).


### Mapping

See [README.mapping.html](https://github.com/FirebirdSQL/firebird/blob/master/doc/sql.extensions/README.mapping.html)

    create global mapping win_admin using plugin win_sspi from predefined_group DOMAIN_ANY_RID_ADMINS to role RDB$ADMIN;

#### Auto admin mapping

See [using GSEC to setup automatic admin mapping](https://www.firebirdsql.org/file/documentation/html/en/firebirddocs/gsec/firebird-gsec.html#gsec-interactive-admin-mapping) and [LANGREF:auto admin mapping](https://www.firebirdsql.org/refdocs/langrefupd25-security-auto-admin-mapping.html).

#### win_sspi mapping

Enable use of windows trusted authentication in all databases that use current security database:

CREATE GLOBAL MAPPING TRUSTED_AUTH USING PLUGIN WIN_SSPI FROM ANY USER TO USER;



Enable SYSDBA-like access for windows admins in current database:

CREATE MAPPING WIN_ADMINS USING PLUGIN WIN_SSPI FROM Predefined_Group DOMAIN_ANY_RID_ADMINS TO ROLE RDB$ADMIN;

(there is no group DOMAIN_ANY_RID_ADMINS in windows, but such name is added by win_sspi plugin to provide exact backwards compatibility)



Enable particular user from other database access current database with other name:

CREATE MAPPING FROM_RT USING PLUGIN SRP IN "rt" FROM USER U1 TO USER U2;

(providing database names/aliases in double quotes is important for operating systems that have case-sensitive file names)



Enable server's SYSDBA (from main security database) access current database (assuming it has non-default security database):

CREATE MAPPING DEF_SYSDBA USING PLUGIN SRP IN "security.db" FROM USER SYSDBA TO USER;



Force people who logged in using legacy authentication plugin have not too much rights:

CREATE MAPPING LEGACY_2_GUEST USING PLUGIN legacy_auth FROM ANY USER TO USER GUEST;



Map windows group to trusted firebird role:

CREATE MAPPING WINGROUP1 USING PLUGIN WIN_SSPI FROM GROUP GROUP_NAME TO ROLE ROLE_NAME;

Here we expect that some windows users may belong to group GROUP_NAME. If needed name of the group may be given in long form, i.e. DOMAIN\GROUP.


## Setting up database and server rights and roles

See the [Security Chapter in the Language Reference Manual](https://firebirdsql.org/file/documentation/chunk/en/refdocs/fblangref50/fblangref50-security.html).

Users, Roles and Grants can be managed using SQL commands or the [GSEC command line utility](https://www.firebirdsql.org/file/documentation/html/en/firebirddocs/gsec/firebird-gsec.html). 


## Hardening

See the [official documentation](https://www.firebirdsql.org/manual/de/qsg2-de-config.html) for best practices about configuring the server and security settings.

### Service user account

Best practice is to change the default `LocalService` account to the windows service
default account `NTService\<servicename>`. As this account does not have any local
file system access, make sure to grant write access to the following files:

- all databases, including security2.fdb (isc4.gdb in pre-1.5 versions)
- the firebird.log file

For security reasons, make sure no other user has (read) access to the database files.

### Change SYSDBA password 

See the [official documentation](https://www.firebirdsql.org/manual/de/qsg2-de-config.html).

### Restrict server filesystem access

Best practice is to run the service using the windows service account (see [Service user account](#service-user-account)),
but this requires setting explicit permissions on the database files. As another option, the [DatabaseAccess](https://www.firebirdsql.org/docs/html/en/refdocs/fbconf/firebird-configuration-reference.html#fbconf-database-access) parameter
in [firebird.conf](https://www.firebirdsql.org/docs/html/en/refdocs/fbconf/firebird-configuration-reference.html#fbconf-firebird) can be set to `restrict` (to allow external access to a given set of folders) or to `none` (to only
allow alias access - i.e. only databases registered in [databases.conf](https://www.firebirdsql.org/docs/html/en/refdocs/fbconf/firebird-configuration-reference.html#fbconf-databases)). 


## Notes

### isql in embedded mode

If the firebird server service is stopped, then `isql` can be used in embedded mode. This is especially useful to fix
issues in the security database (e.g. bad mapping). To access the security database, run isql as follows (you **must** use `SYSDBA` as user name):

    isql security.fdb user SYSDBA

for more details, see [README.security_database.txt](https://github.com/FirebirdSQL/firebird/blob/master/doc/README.security_database.txt).

    1. Stop the Firebird server. Firebird caches connections to the security database aggressively. The presence
    of server connections may prevent isql from establishing an embedded connection.
    2. In a suitable shell, start an isql interactive session, opening the employee database via its alias:
        > isql -user sysdba employee
    3. Create the SYSDBA user:
        WARNING! Do not just copy and paste! Generate your own strong password!

        SQL> create user SYSDBA password 'StrongPassword';
        SQL> exit;

        WARNING! Do not just copy and paste! Generate your own strong password!
    4. To complete the initialization, start the Firebird server again. Now you will be able to perform a network
    login to databases using login SYSDBA and the password you assigned to it.


### hhh

First enable use of Windows trusted authentication:

CREATE GLOBAL MAPPING TRUSTED_AUTH
USING PLUGIN WIN_SSPI
FROM ANY USER
TO USER;

Then we want to define some exact Windows trusted authentication user group mapping to firebird role:

CREATE MAPPING WIN_GLADMIN
USING PLUGIN WIN_SSPI
FROM Group NOOMGLADMIN
TO ROLE GLADMIN;

But this does not work.


## Reference

Firebird starting with version 2.1 can use Windows security for user authentication.
Current security context is passed to the server and if it's OK for that server is used to determine
firebird user name. To use Windows trusted authentication in FB3 you should make minimum changes in
firebird.conf and tune mappings in your databases.

Parameter Authentication in firebird.conf file is not used any more - it's replaced with more
generic AuthServer (and AuthClient) parameters. Also to use trusted authentication one should turn
off mandatory wire encryption because Win_Sspi plugin (which implements trusted authentication on
Windows) does not provide an encryption key. So minimum changes in firebird.conf you need is:

AuthServer = Srp, Win_Sspi
WireCrypt = Enabled

Also mapping (see sql.extensions/README.mapping.html) should be created. To tune for all databases
do:

create global mapping trusted_auth using plugin win_sspi from any user to user;

Do not put user and password parameters in DPB/SPB. With provided firebird.conf in almost all cases
trusted authentication will be used (see environment below for exceptions). Suppose you have logged
to the Windows server SRV as user John. If you connect to server SRV with isql, not specifying
Firebird login and password:

isql srv:employee

and do:

SELECT CURRENT_USER FROM RDB$DATABASE;

you will get something like:

USER
====================================================
SRV\John

Windows users may be granted rights to access database objects and roles in the same way as
traditional Firebird users. (This is not something new - in UNIX OS users might be granted rights
virtually always).

- If domain administrator (member of well known predefined groups) connects to Firebird using trusted
authentication, he/she may be granted 'god-like' (SYSDBA) rights depending upon settings in database,
to which such user attachs. To keep CURRENT_USER value in a form DOMAIN\User, a new object (predefined
system role) is added to the database. The name of that role is RDB$ADMIN, and any user, granted it,
can attach to the database with SYSDBA rights. To configure all databases to auto-grant that role to
administrators, use the following command:

create global mapping win_admin using plugin win_sspi from predefined_group DOMAIN_ANY_RID_ADMINS to role RDB$ADMIN;

Take into an account, that if Windows administrator attaches with role set in dpb, it will not be
replaced with RDB$ADMIN, i.e. he/she will not get SYSDBA rights.

- To keep legacy behavior when ISC_USER/ISC_PASSWORD variables are set in environment, they
are picked and used instead of trusted authentication. In case when trusted authentication is needed
and ISC_USER/ISC_PASSWORD are set, add new DPB parameter isc_dpb_trusted_auth to DPB. In most
of Firebird command line utilities switch -trusted (may be abbreviated up to utility rules) is used
for it.

isql srv:db                -- log using trusted authentication
set ISC_USER=user1
set ISC_PASSWORD=12345
isql srv:db                -- log as 'user1' from environment
isql -trust srv:db         -- log using trusted authentication
