# Enterprise user management

OGS provides a flexible user and rights management. By implementing the user management LUA interface functions,
LUA can control all aspects of user and rights management. 

Currently the following user management modules are available:

- [Standard](#standard-user-management): Uses predefined usernames and passwords (optionally RFID tag/card numbers) defined in station.ini. Each user can be assigned the `operator` or the `supervisor` role, rights are defined through the global LUA table `user_rights` (the `supervisor` rols always has all rights, the `operator` role has only the rights assigned through the `user_rights` table). Note, that this is not "enterprise", but often good enough for small setups.
- [Active Directory authentication and security group mapping](userdb-activedirectory.md): Authenticates the user through active directory and reads the users group membership from active directory. Also uses the `operator` or the `supervisor` roles and defines the rights through the global `user_rights` LUA table, but maps them to two distinct active directory groups (defined using their SID in station.ini). If a user is no member of any of these groups, he cannot use OGS. Login to OGS is either through the currently logged on Windows account or by entering the active directory username and password.
- [heUserManager centralized rights and role management](userdb-heusermanager.md): Authenticates the user through username/password or RFID card/tag ID define in a central SQL server database. There is a GUI utility (heUserManager.exe) available to define rights and roles as well as groups and users. This provides high flexibility, e.g. multiple user levels and mutliple user rights depending on different variables (e.g. different user rights for the same user on different stations/lines).

## Standard user management

