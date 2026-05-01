# Active directory authentication

- default implementation uses two AD-security groups to map "operator" and "supervisor" application roles. This is defined in station.ini (supervisor_sid=, operator_sid=)
- when starting OGS, the currently logged on user is checked having one of the two roles and gets rights assigned accordingly
- rights:
    * supervisor has all rights
    * operator has limited rights as defined in the `user_rights` global LUA table (as with [standard authentication](./userdb.md))
- NOTE: Ensure setting a folder SID for the project folder to prevent changing and project file (admin only write allowed)

## User interface

- uses the standard windows credentials dialog
- for domain users, UPN format is used (email@domain)



