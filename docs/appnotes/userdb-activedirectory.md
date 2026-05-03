# Active directory authentication

## Overview

The OGS active directory authentication actaully consists of two main areas:

- OGS application logon and user rights. This is used by the OGS runtime application `monitor.exe` to determine the rights a user has when using the software. See [OGS application logon and user rights](#ogs-application-logon-and-user-rights) below for more information.
- OGS database access and rights. The databases also manages security and Active Directory can be used to control who can connect to a database and which rights are available based on the user initialing the connection. See [Firebird SQL Active Directory Integration](./firebird-security.md) for more information.

## OGS application logon and user rights

### Overview

- default implementation uses two AD-security groups to map "operator" and "supervisor" application roles. This is defined in station.ini (supervisor_sid=, operator_sid=)
- when starting OGS, the currently logged on user is checked having one of the two roles and gets rights assigned accordingly
- rights:
    * supervisor has all rights
    * operator has limited rights as defined in the `user_rights` global LUA table (as with [standard authentication](./userdb.md))
- NOTE: Ensure setting a folder SID for the project folder to prevent changing and project file (admin only write allowed)

### User interface

- uses the standard windows credentials dialog
- for domain users, UPN format is used (email@domain)



