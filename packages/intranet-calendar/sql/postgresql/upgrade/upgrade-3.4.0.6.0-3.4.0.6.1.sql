--upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-calendar/sql/postgresql/upgrade/upgrade-3.4.0.6.0-3.4.0.6.1.sql','');

-- Dont inherit from Main Site anymore
update acs_objects set 
	context_id = null 
where
	object_id in (
		select package_id 
		from apm_packages 
		where package_key = 'intranet-calendar'
	)
;

-- Granting Senior Managers read permissions on the calendar package by
-- default. 
--
-- macordovam at: https://sourceforge.net/forum/message.php?msg_id=7532369
-- added "limit 1" clause in case there are multiple calendars.
-- This permission granting is optional and rarely there are more then
-- one, so this quick fix should be OK...

-- Ignore multiple calendar instances and just setting permissions for the
-- first one...

SELECT acs_permission__grant_permission(
	(select package_id from apm_packages where package_key = 'intranet-calendar' limit 1),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
