-- drop the calendar system
--
-- @author Gary Jin (gjin@arsdigita.com)
-- @creation-date Nov 27, 2000
-- $Id$
--
-- @ported by Charles Mok (mok_cl@eelab.usyd.edu.au)

------------------------------------------------
-- Drop the Permissions
------------------------------------------------

delete 	from acs_permissions
where 	privilege in (
		'cal_item_create', 
		'cal_item_read',
        	'cal_item_write', 
		'cal_item_delete',
        	'cal_item_invite'
	);

delete 	from acs_privilege_hierarchy
where 	privilege in (
		'cal_item_create', 
	        'cal_item_read', 
         	'cal_item_write', 
         	'cal_item_delete',       
         	'cal_item_invite'
	);


delete 	from acs_privilege_hierarchy
where 	child_privilege in (
		'cal_item_create', 
	        'cal_item_read', 
         	'cal_item_write', 
         	'cal_item_delete',       
         	'cal_item_invite'
	);


delete 	from acs_privileges
where 	privilege in (
		'cal_item_create', 
	        'cal_item_read', 
         	'cal_item_write', 
         	'cal_item_delete',       
         	'cal_item_invite'
	);



delete 	from acs_permissions
where 	privilege in (
		'calendar_create', 
		'calendar_read',
        	'calendar_write', 
		'calendar_delete',
        	'calendar_admin',
	       	'calendar_on',
	       	'calendar_show'
	);

delete 	from acs_privilege_hierarchy
where 	privilege in (
		'calendar_create', 
	        'calendar_read', 
         	'calendar_write', 
         	'calendar_delete',       
         	'calendar_admin',
	       	'calendar_on',
	       	'calendar_show'
	);

delete 	from acs_privilege_hierarchy
where 	child_privilege in (
		'calendar_create', 
	        'calendar_read', 
         	'calendar_write', 
         	'calendar_delete',       
         	'calendar_admin',
	       	'calendar_on',
	       	'calendar_show'
	);


delete 	from acs_privileges
where 	privilege in (
		'calendar_create', 
	        'calendar_read', 
         	'calendar_write', 
         	'calendar_delete',
         	'calendar_admin',
	       	'calendar_on',
	       	'calendar_show'
	);


------------------------------------------------
-- Drop Support Tables
------------------------------------------------
\i cal-table-drop.sql


------------------------------------------------
-- drop cal_item
------------------------------------------------
\i cal-item-drop.sql


------------------------------------------------
-- Drop Calendar
------------------------------------------------

DROP TABLE calendars;
CREATE FUNCTION inline_0 ()
RETURNS integer
AS 'begin
	PERFORM acs_attribute__drop_attribute (''calendar'',''owner_id'');
	PERFORM acs_attribute__drop_attribute (''calendar'',''private_p'');
	DELETE FROM acs_objects WHERE object_type = ''calendar'';
	PERFORM acs_object_type__drop_type (''calendar'', ''f'');

	return 0;
    end;'
LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();


DELETE FROM acs_objects WHERE object_type='calendar';

DROP FUNCTION calendar__new (
       integer,            -- calendar.calendar_id%TYPE
       varchar,            -- calendar.calendar_name%TYPE
       varchar,            -- acs_objects.object_type%TYPE
       integer,            -- calendar.owner_id%TYPE
       boolean,            -- calendar.private_p
       integer,            -- calendar.package_id
       integer,            -- acs_objects.context_id%TYPE
       timestamptz,        -- acs_objects.creation_date%TYPE
       integer,            -- acs_objects.creation_user%TYPE
       varchar             -- acs_objects.creation_ip%TYPE
);

DROP FUNCTION calendar__delete(
       integer            
);

DROP FUNCTION calendar__first_displayed_date(
	timestamptz
);

DROP FUNCTION calendar__last_displayed_date(
	timestamptz
);










