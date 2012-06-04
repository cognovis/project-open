-- /package/intranet-forum/sql/intranet-helpdesk-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-helpdesk');
select  im_menu__del_module('intranet-helpdesk');


-----------------------------------------------------------
-- Drop main structures info

-- Drop functions
drop function im_ticket__name(integer);
drop function im_ticket__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer, integer, integer
);
drop function im_ticket__delete(integer);


drop sequence im_ticket_seq;


-- Drop the main table
drop table im_tickets;

update acs_objects set context_id = null 
where context_id in (select object_id from acs_objects where object_type = 'im_ticket');

delete from im_biz_object_members
where rel_id in (
	select	rel_id from acs_rels
	where object_id_one in (select object_id from acs_objects where object_type = 'im_ticket') OR 
	      object_id_two in (select object_id from acs_objects where object_type = 'im_ticket')
);

delete from acs_rels
where object_id_one in (select object_id from acs_objects where object_type = 'im_ticket') OR 
      object_id_two in (select object_id from acs_objects where object_type = 'im_ticket');


delete from im_forum_topic_user_map
where topic_id in (
	select topic_id from im_forum_topics 
	where object_id in (select object_id from acs_objects where object_type = 'im_ticket')
);

delete from im_forum_topics 
where object_id in (select object_id from acs_objects where object_type = 'im_ticket');

update im_costs set project_id = null
where project_id in (select object_id from acs_objects where object_type = 'im_ticket');

delete from im_hours
where project_id in (select object_id from acs_objects where object_type = 'im_ticket');

delete from im_projects
where project_id in (select object_id from acs_objects where object_type = 'im_ticket');

delete from wf_tokens
where case_id in (
	select case_id from wf_cases
	where object_id in (select object_id from acs_objects where object_type = 'im_ticket')
);

delete from wf_cases
where object_id in (select object_id from acs_objects where object_type = 'im_ticket');

-- Delete entries from acs_objects
delete from acs_objects where object_type = 'im_ticket';


delete from im_dynfield_layout
where attribute_id in (
	select attribute_id from im_dynfield_attributes
	where acs_attribute_id in (
		select	attribute_id from acs_attributes
		where object_type = 'im_ticket'
	)
);

delete from im_dynfield_attributes
where acs_attribute_id in (
	select	attribute_id from acs_attributes
	where object_type = 'im_ticket'
);

delete from im_dynfield_layout_pages
where object_type = 'im_ticket';

delete from acs_attributes
where object_type = 'im_ticket';

delete from acs_object_type_tables
where object_type = 'im_ticket';


delete from im_biz_object_urls
where object_type = 'im_ticket';

-- Completely delete the object type from the
-- object system
SELECT acs_object_type__drop_type ('im_ticket', 't');



-----------------------------------------------------------
-- Drop Categories
--

drop view im_ticket_status;
drop view im_ticket_type;


delete from im_category_hierarchy
where	parent_id in (select category_id from im_categories where category_type = 'Intranet Ticket Status') OR
	child_id in (select category_id from im_categories where category_type = 'Intranet Ticket Status');

delete from im_dynfield_type_attribute_map
where attribute_id in (select category_id from im_categories where category_type = 'Intranet Ticket Status');

delete from im_categories where category_type = 'Intranet Ticket Status';


delete from im_category_hierarchy
where	parent_id in (select category_id from im_categories where category_type = 'Intranet Ticket Type') OR
	child_id in (select category_id from im_categories where category_type = 'Intranet Ticket Type');

delete from im_dynfield_type_attribute_map
where	attribute_id in (select category_id from im_categories where category_type = 'Intranet Ticket Type') OR
	object_type_id in (select category_id from im_categories where category_type = 'Intranet Ticket Type');

delete from im_categories where category_type = 'Intranet Ticket Type';

