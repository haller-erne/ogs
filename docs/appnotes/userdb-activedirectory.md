# Active directory authentication

## Overview

The OGS active directory authentication actually consists of two main areas:

- OGS application logon and user rights. This is used by the OGS runtime application `monitor.exe` to determine the rights a user has when using the software. See [OGS application logon and user rights](#ogs-application-logon-and-user-rights) below for more information.
- OGS database access and rights. The databases also manages security and Active Directory can be used to control who can connect to a database and which rights are available based on the user initialing the connection. See [Firebird SQL Active Directory Integration](./firebird-security.md) for more information.

## OGS application logon and user rights

### Overview

- default implementation uses two AD-security groups to map "operator" and "supervisor" application roles. This is defined in station.ini (supervisor_sid=, operator_sid=)
- when starting OGS, the currently logged-on process user is automatically logged in once if they belong to one of the configured AD groups (SSO auto-login at startup)
- rights:
    * supervisor has all rights
    * operator has limited rights as defined in the `user_rights` global LUA table (as with [standard authentication](./userdb.md))
- NOTE: Ensure setting a folder SID for the project folder to prevent changing and project file (admin only write allowed)

### User interface

- uses the standard windows credentials dialog (when `windows_default_auth=1`) or the OGS username/password field (when `windows_default_auth=0`)
- accepted username formats: UPN (`user@domain`) or plain username; `DOMAIN\user` format is **not** supported


## OGS setup

To setup OGS, copy the two LUA files into your projects folder:

- `user_manager_ad.lua`: the high level LUA interface to be added to the `requires` table in `config.lua` 
- `user_db_activedirectory.lua`: the low-level active directory access for user management

The `config.lua` file in you project should add the `user_manager_ad.lua` as follows:

``` lua hl_lines="6" title="config.lua"
-- add the shared folder (..\shared)
OGS.Project.AddPath('../shared')

requires = {
	"barcode",
	"user_manager_ad",           -
    -- possibly more...
}
current_project.logo_file = '../shared/logo-rexroth.png'
current_project.billboard = 'billboard.html'
```

1.  Add this line to include the `user_manager_ad.lua` active directory interface in the project.

In `station.ini` you can now use additional settings to define the active directory mapping and logon behaviour. Update your `[USER]` section is `station.ini` as follows:

``` ini title="station.ini"
[USER]

; Define, if users should be logged out automatically after a configured 
; inactivity time (given in minutes). If autologoff is defined and set 
; to a nonzero value, users will be loggerd off automatically.
; Note, that the autologon user will never be logged out automatically!
autologoff=10

; Defines the OGS "operator" role SID
sid_operator=S-1-5-21-1351067494-3386591924-3478655970-6131

; Defines the OGS "supervisor" role SID
sid_supervisor=S-1-5-21-1351067494-3386591924-3478655970-4621

; Defines, if the native Windows authentication dialog should be used
; or if username/password can be entered through the OGS username/password
; field (a little bit less secure, but works better with touch screens).
; When set to 0, the password typed in the OGS field is passed from C++ to
; Lua for direct AD validation via LogonUserW (no Windows dialog shown).
; Default 1 (use Windows logon dialog)
windows_default_auth=0

```

!!! warning

    Make sure to set ACLs which prevent non-administrative users to change files in the <project> folder (the folder where `station.ini`) is stored.
    Not doing so will allow any user to disable/change the security related settings (and get higher priviledges as intended)!
     

## Notes and hints

- No fallback: if AD authentication fails or the user is not a member of any configured group, the login attempt returns an empty result. There is no fallback to static `[USER]` entries.
- Static `user=password,level,cardid` entries in `[USER]` are **not** evaluated by the AD variant.

