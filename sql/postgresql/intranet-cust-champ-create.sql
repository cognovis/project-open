-- /packages/intranet-cust-champ/sql/postgresql/intranet-cust-champ-create.sql
--
-- Copyright (c) 2012 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author klaus.hofeditz@project-open.com

---------------------------------------------------------
-- Components
---------------------------------------------------------

-- Component in member-add page
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Add group members',			-- plugin_name
	'intranet-cust-champ',			-- package_name
	'bottom',				-- location
	'/intranet/member-add',			-- page_url
	null,					-- view_name
	200,					-- sort_order
	'assign_group_members_to_project_component $user_id $object_id $return_url',
	'lang::message::lookup "" intranet-cust-champ.AddGroupComponent "Add groups"'
);

-- Setting permissions for portlet 

create or replace function inline_1 ()
returns integer as '
declare
        v_plugin_id           integer;
        v_employees           integer;
begin

	select  plugin_id
	into    v_plugin_id
	from    im_component_plugins pl
	where   plugin_name = ''Add group members'';

        select group_id into v_employees from groups where group_name = ''Employees'';

	PERFORM im_grant_permission(v_plugin_id,  v_employees, ''read'');

        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();





 
