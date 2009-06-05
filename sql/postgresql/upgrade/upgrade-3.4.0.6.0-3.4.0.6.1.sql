--upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-calendar/sql/postgresql/upgrade/upgrade-3.4.0.6.0-3.4.0.6.1.sql','');

-- Dont inherit from Main Site anymore
update acs_objects set 
	context_id = null 
where
	object_id in (
		select package_id 
		from apm_packages 
		where package_key = 'calendar'
	)
;

-- Granting Senior Managers read permissions on the calendar package by
-- default. 
SELECT acs_permission__grant_permission(
	(select package_id from apm_packages where package_key = 'calendar'),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
