
-- The following inserts the OGS permissions for application_id = 2
-- Make sure to create the application in heUserManager first!
insert into permissions (application_id, name, code, command, [desc]) values(2, 'finish',     1, 'finish','finish assembly processing');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'clear all',     2, 'clear all','clear assembly (clear all tightening results on assembly)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'start job',     4, 'start job','start current Job');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'stop job',     8, 'stop job','finish current Job processing');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'skip job',    16 , 'skip job','skip Job (finish current Job processing and start the next)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'clear job',    32, 'clear job','clear Job (clear all tightening results on current Job)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'skip operation',    64, 'skip operation','skip Operation (set current operation to NOK and start the next)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'clear operation',   128, 'clear operation','clear Bolt (clear tightening results on current bolt position and define it as NOT_PROCESSED)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'start diagnostic',   256, 'start diagnostic','start diagnostic Job');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'select',   512, 'select','select Job / Bolt in view');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'process nok',  4096, 'process nok','process NOK (continue tightening process after NOK result)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'ccw',  8192, 'ccw','use the switch on the tool to activate the loosen process (CCW)');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'unmount', 32768, 'unmount','unmount Job');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'alternative tool', 65536, 'alternative tool','switch between alternative and standard tool');
insert into permissions (application_id, name, code, command, [desc]) values(2, 'teach position',131072, 'teach position','teach Tool position');

-- after inserting the permissions, use heUserManager to assign them to the app role(s) as needed
