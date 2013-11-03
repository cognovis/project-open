﻿-- /packages/intranet-events/sql/postgresql/intranet-events-create.sql
--
-- Copyright (C) 2003-2013 ]project-open[
-- @author	frank.bergmann@project-open.com


-----------------------------------------------------------
-- Create the object type

SELECT acs_object_type__create_type (
	'im_event',			-- object_type
	'Event',			-- pretty_name
	'Events',			-- pretty_plural
	'acs_object',			-- supertype
	'im_events',			-- table_name
	'event_id',			-- id_column
	'intranet-events',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_event__name'		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_event', 'im_events', 'event_id');

-- Setup status and type columns for im_events
update acs_object_types set 
	status_type_table = 'im_events',
	status_column = 'event_status_id', 
	type_column = 'event_type_id',
	type_category_type = 'Intranet Event Type',
	status_category_type = 'Intranet Event Status'
where object_type = 'im_event';

-- Create "Trainer" role for tickets
SELECT im_category_new (1307, 'Consultant', 'Intranet Biz Object Role');
SELECT im_category_new (1308, 'Trainer', 'Intranet Biz Object Role');

update im_categories set category_gif = 'c' where category_id = 1307;
update im_categories set category_gif = 't' where category_id = 1308;

insert into im_biz_object_role_map values ('im_event',null,1300);
insert into im_biz_object_role_map values ('im_event',null,1307);
insert into im_biz_object_role_map values ('im_event',null,1308);


-- Define how to link to Event pages from the Forum or the
-- Search Engine
delete from im_biz_object_urls where object_type = 'im_event';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_event','view','/intranet-events/new?form_mode=display&event_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_event','edit','/intranet-events/new?event_id=');




-- Insert a design page
insert into im_dynfield_layout_pages (
        page_url,
        object_type,
        layout_type
) values (
        '/intranet-events/index',
        'im_event',
        'table'
);


-- Add a status field in order to track user's assignment
alter table im_biz_object_members 
add column member_status_id integer default 82210
constraint im_biz_object_members_status_fk references im_categories;

alter table im_biz_object_members 
add column note text;



------------------------------------------------------
-- Events Table
--

create sequence im_event_nr_seq;
create table im_events (
	event_id			integer
					constraint im_events_pk
					primary key
					constraint im_events_id_fk
					references acs_objects,

	event_name			text
					constraint im_events_name_nn not null,

	event_nr			text
					constraint im_events_nr_nn not null,

	-- Status and type for orderly objects...
	event_type_id			integer
					constraint im_events_type_fk
					references im_categories
					constraint im_events_type_nn
					not null,
	event_status_id			integer
					constraint im_events_status_fk
					references im_categories
					constraint im_events_type_nn 
					not null,

	-- Other content fields
	event_material_id		integer
					constraint im_events_material_fk
					references im_materials,
	event_location_id		integer
					constraint im_events_location_fk
					references im_conf_items,

	event_start_date		timestamptz
					constraint im_events_start_const not null,
	event_end_date			timestamptz
					constraint im_events_end_const not null,

	-- Link to associated timesheet task + sweeper info
	event_timesheet_task_id		integer
					constraint im_events_ts_task_fk
					references im_timesheet_tasks,
	event_timesheet_last_swept	timestamptz,

	event_description		text
);

-- Unique constraint to avoid that you can add two identical events
-- alter table im_events drop constraint owner_and_start_date_unique;
alter table im_events 
add constraint im_events_name_type_un unique (event_name, event_type_id);



-- Incices to speed up frequent queries
create index im_events_dates_idx on im_events(event_start_date, event_end_date);
create index im_events_type_idx on im_events(event_type_id);


-----------------------------------------------------------
-- Create, Drop and Name PlPg/SQL functions
--
-- These functions represent creator/destructor
-- functions for the OpenACS object system.

create or replace function im_event__name(integer)
returns varchar as '
DECLARE
	p_event_id		alias for $1;
	v_name			varchar;
BEGIN
	select	event_name into v_name
	from	im_events
	where	event_id = p_event_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_event__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, varchar, timestamptz, timestamptz,
	integer, integer
) returns integer as '
DECLARE
	p_event_id		alias for $1;		-- event_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_event''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_event_name		alias for $7;		-- event_name
	p_event_nr		alias for $8;		-- event_nr
	p_event_start_date	alias for $9;
	p_event_end_date	alias for $10;
	p_event_status_id	alias for $11;
	p_event_type_id		alias for $12;

	v_event_id	integer;
BEGIN
	v_event_id := acs_object__new (
		p_event_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''f''			-- security_inherit_p
	);

	insert into im_events (
		event_id, event_name, event_nr,
		event_start_date, event_end_date,
		event_status_id, event_type_id
	) values (
		v_event_id, p_event_name, p_event_nr,
		p_event_start_date, p_event_end_date,
		p_event_status_id, p_event_type_id
	);

	return v_event_id;
END;' language 'plpgsql';


create or replace function im_event__delete(integer)
returns integer as '
DECLARE
	p_event_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_events
	where	event_id = p_event_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_event_id);

	return 0;
end;' language 'plpgsql';






-----------------------------------------------------------
-- Event Helper Functions
-----------------------------------------------------------

create or replace function im_event__participant_list(integer)
returns varchar as $$
DECLARE
	p_event_id	alias for $1;
	row		RECORD;
	v_result	varchar;
BEGIN
	v_result := '';
	FOR row IN
		select	pe.first_names || ' ' || pe.last_name as user_name,
			pe.person_id
		from	persons pe,
			acs_rels r
		where	r.object_id_two = pe.person_id and
			r.object_id_one = p_event_id
	LOOP
		IF '' != v_result THEN v_result := v_result || ' '; END IF;
		v_result := v_result || '{' || '<a href=/intranet/users/view?user_id=' || row.person_id || '>' || row.user_name || '</a>}';
	END LOOP;

	return v_result;
end;$$ language 'plpgsql';
-- select im_event__participant_list(480591);


create or replace function im_event__customer_list(integer)
returns varchar as $$
DECLARE
	p_event_id	alias for $1;
	row		RECORD;
	v_result	varchar;
BEGIN
	v_result := '';
	FOR row IN
		select	company_id, company_name
		from	im_companies c,
			acs_rels r
		where	r.object_id_two = c.company_id and
			r.object_id_one = p_event_id
	LOOP
		IF '' != v_result THEN v_result := v_result || ' '; END IF;
		v_result := v_result || '{' || '<a href=/intranet/companies/view?company_id=' || row.company_id || '>' || row.company_name || '</a>}';
	END LOOP;

	return v_result;
end;$$ language 'plpgsql';
-- select im_event__customer_list(480591);






-----------------------------------------------------------
-- Full-Text Search for Events
-----------------------------------------------------------


insert into im_search_object_types values (10, 'im_event', 0.6);


create or replace function im_events_tsearch ()
returns trigger as $$
declare
	v_string	varchar;
begin
	select	coalesce(e.event_name, '') || ' ' ||
		coalesce(e.event_nr, '') || ' ' ||
		coalesce(e.event_description, '') || ' ' ||
		coalesce(m.material_name, '') || ' ' ||
		coalesce(m.material_nr, '') || ' ' ||
		coalesce(ci.conf_item_name, '') || ' ' ||
		coalesce(ci.conf_item_nr, '')
	into    v_string
	from    im_events e
		LEFT OUTER JOIN im_materials m ON (e.event_material_id = m.material_id)
		LEFT OUTER JOIN im_conf_items ci ON (e.event_location_id = ci.conf_item_id)
	where   e.event_id = new.event_id;

	RAISE INFO 'im_events_tsearch: %', v_string;
	perform im_search_update(new.event_id, 'im_event', new.event_id, v_string);

	return new;
end;$$ language 'plpgsql';


CREATE TRIGGER im_events_tsearch_tr
AFTER INSERT or UPDATE
ON im_events
FOR EACH ROW
EXECUTE PROCEDURE im_events_tsearch();






-- ------------------------------------------------------------
-- Event - Customer Relationship
-- ------------------------------------------------------------

create table im_event_customer_rels (
	rel_id			integer
				constraint im_event_customer_rels_rel_fk
				references acs_rels (rel_id)
				constraint im_event_customer_rels_rel_pk
				primary key
);

select acs_rel_type__create_type (
	'im_event_customer_rel',		-- relationship (object) name
	'Event Customer Relation',		-- pretty name
	'Event Customer Relations',		-- pretty plural
	'relationship',				-- supertype
	'im_event_customer_rels',		-- table_name
	'rel_id',				-- id_column
	'intrnet-events',			-- package_name
	'im_event',				-- object_type_one
	'member',				-- role_one
	0,					-- min_n_rels_one
	null,					-- max_n_rels_one
	'im_company',				-- object_type_two
	'member',				-- role_two
	0,					-- min_n_rels_two
	null					-- max_n_rels_two
);



-- New version of the PlPg/SQL routine with percentage parameter
--
create or replace function im_event_customer_rel__new (
       integer, integer, varchar, integer, integer
) returns integer as $body$
DECLARE
	p_rel_id		alias for $1;	-- null
	p_creation_user		alias for $2;	-- null
	p_creation_ip		alias for $3;	-- null
	p_event_id		alias for $4;	-- object_id_one
	p_customer_id		alias for $5;	-- object_id_two

	v_rel_id		integer;
	v_count			integer;
BEGIN
	select	min(rel_id) into v_rel_id from acs_rels
	where	rel_type = 'im_event_customer_rel' and
		object_id_one = p_event_id
		and object_id_two = p_customer_id;

	IF v_rel_id is not null THEN return v_rel_id; END IF;

	v_rel_id := acs_rel__new (
		p_rel_id,			-- rel_id
		'im_event_customer_rel',	-- relation type
		p_event_id,			-- object_id_one
		p_customer_id,			-- object_id_two
		null,				-- contect_id
		p_creation_user,		-- creation_user
		p_creation_ip			-- creation_ip
	);

	insert into im_event_customer_rels (rel_id) values (v_rel_id);

	return v_rel_id;
end;$body$ language 'plpgsql';



create or replace function im_event_customer_rel__delete (integer)
returns integer as $body$
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete from im_event_customer_rels where rel_idi = p_rel_id;
	PERFORM acs_rel__delete(v_rel_id);
	return 0;
end;$body$ language 'plpgsql';


create or replace function im_event_customer_rel__delete (integer, integer)
returns integer as $body$
DECLARE
	p_event_id	alias for $1;
	p_customer_id	alias for $2;

	v_rel_id	integer;
BEGIN
	select	min(rel_id) into v_rel_id from acs_rels
	where	rel_type = 'im_event_customer_rel' and
		object_id_one = p_event_id
		and object_id_two = p_customer_id;

	delete from im_event_customer_rels where rel_id = v_rel_id;
	PERFORM acs_rel__delete(v_rel_id);
	return 0;
end;$body$ language 'plpgsql';




-- ------------------------------------------------------------
-- Event - Order Item Relationship
 -- ------------------------------------------------------------

create table im_event_order_item_rels (
    	event_id		integer
				constraint im_event_order_item_rels_event_fk
				references im_events,
	order_item_id		integer
				constraint im_event_order_item_rels_order_item_fk
				references im_invoice_items,
	order_item_amount	numeric(12,3) default 1.0
	primary key(event_id, order_item_id)
);


-- Incices to speed up frequent queries
create index im_event_order_item_rels_event_idx on im_event_order_item_rels(event_id);
-- create index im_event_order_item_rels_order_item_idx on im_event_order_item_rels(order_item_id);

alter table im_event_order_item_rels alter column order_item_amount type numeric(12,3);


------------------------------------------------------
-- Events Permissions
--

-- add_events makes it possible to restrict the event registering to internal stuff
SELECT acs_privilege__create_privilege('add_events','Add Events','Add Events');
SELECT acs_privilege__add_child('admin', 'add_events');

-- view_events_all restricts possibility to see events of others
SELECT acs_privilege__create_privilege('view_events_all','View Events All','View Events All');
SELECT acs_privilege__add_child('admin', 'view_events_all');

-- edit_events_all restricts possibility to see events of others
SELECT acs_privilege__create_privilege('edit_events_all','Edit Events All','Edit Events All');
SELECT acs_privilege__add_child('admin', 'edit_events_all');


-- Set default permissions per group
-- ToDo: Permission granting does not work
SELECT im_priv_create('add_events', 'Employees');
SELECT im_priv_create('view_events_all', 'Employees');
SELECT im_priv_create('edit_events_all', 'Project Managers');
SELECT im_priv_create('edit_events_all', 'Senior Managers');
SELECT im_priv_create('edit_events_all', 'Accounting');


-----------------------------------------------------------
-- Type and Status
--
-- 82000-81999  Events (1000)
-- 82000-82099	Event Status (100)
-- 82100-82199	Event Type (100)
-- 82200-82299	Participant Member Status (100)
-- 82300-82999	reserved (800)


SELECT im_category_new (82000, 'Unplanned', 'Intranet Event Status');
update im_categories set aux_string2 = 'FF0000' where category_id = 82000;
SELECT im_category_new (82002, 'Planned', 'Intranet Event Status');
update im_categories set aux_string2 = 'FFAA00' where category_id = 82002;
SELECT im_category_new (82004, 'Reserved', 'Intranet Event Status');
update im_categories set aux_string2 = 'FFFF00' where category_id = 82004;
SELECT im_category_new (82006, 'Booked', 'Intranet Event Status');
update im_categories set aux_string2 = '00FF00' where category_id = 82006;
SELECT im_category_new (82099, 'Deleted', 'Intranet Event Status');
update im_categories set aux_string2 = '000000' where category_id = 82099;


SELECT im_category_new (82100, 'Training Event', 'Intranet Event Type');
update im_categories set category = 'Training Event' where category_id = 82100;
SELECT im_category_new (82110, 'Presales Event', 'Intranet Event Type');
SELECT im_category_new (82120, 'Internal Event', 'Intranet Event Type');



SELECT im_category_new (82200, 'Confirmed', 'Intranet Event Participant Status');
SELECT im_category_new (82210, 'Reserved', 'Intranet Event Participant Status');
SELECT im_category_new (82290, 'Deleted', 'Intranet Event Participant Status');




update im_categories set aux_string2 = '99CCFF' where category_id = 5000;
update im_categories set aux_string2 = 'CCFFCC' where category_id = 5001;
update im_categories set aux_string2 = 'CC9999' where category_id = 5002;
update im_categories set aux_string2 = 'CC99FF' where category_id = 5003;
update im_categories set aux_string2 = 'FFCC99' where category_id = 5004;
update im_categories set aux_string2 = 'CCCCCC' where category_id = 5005;
update im_categories set aux_string2 = 'FF99CC' where category_id = 5006;
update im_categories set aux_string2 = 'FF9999' where category_id = 5007;



-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_event_status as
select	category_id as event_status_id, category as event_status
from	im_categories
where	category_type = 'Intranet Event Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_event_types as
select	category_id as event_type_id, category as event_type
from	im_categories
where	category_type = 'Intranet Eventy Type'
	and (enabled_p is null or enabled_p = 't');



-- ------------------------------------------------------
-- Menus
-- ------------------------------------------------------


create or replace function inline_0 ()
returns integer as $body$
declare
	v_menu		integer;	
	v_parent_menu	integer;
	v_employees	integer;
	v_count		integer;
BEGIN
	select group_id into v_employees from groups where group_name = 'Employees';

	select count(*) into v_count from im_menus where label = 'events';
	IF v_count > 0 THEN return 1; END IF;

	select menu_id into v_parent_menu from im_menus where label = 'main';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-events',		-- package_name
		'events',			-- label
		'Events',			-- name
		'/intranet-events/index?',	-- url
		78,				-- sort_order
		v_parent_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as $body$
declare
	v_menu		integer;	
	v_parent_menu	integer;
	v_employees	integer;
	v_count		integer;
BEGIN
	select group_id into v_employees from groups where group_name = 'Employees';

	select count(*) into v_count from im_menus where label = 'event_summary';
	IF v_count > 0 THEN return 1; END IF;

	select menu_id into v_parent_menu from im_menus where label = 'events';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-events',		-- package_name
		'event_summary',		-- label
		'Summary',			-- name
		'/intranet-events/new?',	-- url
		0,				-- sort_order
		v_parent_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- EventListPage Main View
-----------------------------------------------------------

-- 970-979              intranet-events


delete from im_view_columns where view_id = 970;
delete from im_views where view_id = 970;

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (970, 'event_list', 'view_events_all', 1400);


-- Add a "select all" checkbox to select all events in the list
insert into im_view_columns (
        column_id, view_id, sort_order,
	column_name,
	column_render_tcl,
        visible_for
) values (
        97099,970,0,
        '<input type=checkbox name=_dummy onclick="acs_ListCheckAll(''event'',this.checked)">',
        '$action_checkbox',
        ''
);


insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97010,970,10,'Name','"<a href=/intranet-events/new?form_mode=display&event_id=$event_id>$event_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97020,970,20,'Material','$material_name');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97030,970,30,'Type','$event_type');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97050,970,50,'Start','$event_start_date_formatted');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97060,970,60,'Duration','$event_duration_days');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97070,970,70,'Location','$event_location_name');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97075,970,75,'Customers','$event_customers_pretty');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97080,970,80,'Participants','$event_participants_pretty');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(97090,970,90,'Status','$event_status');





-----------------------------------------------------------
-- DynFields
-----------------------------------------------------------

-- Insert a design page
insert into im_dynfield_layout_pages (
    	page_url,
	object_type,
	layout_type
) values (
	'/intranet-events/index',
	'im_event',
	'table'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'event_type', 'Event Type', 'Event Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Event Type"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'event_status', 'Event Status', 'Event Status',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Event Status"}}'
);


SELECT im_dynfield_attribute_new ('im_event', 'event_type_id', 'Type', 'event_type', 'integer', 'f', 30, 't');
SELECT im_dynfield_attribute_new ('im_event', 'event_status_id', 'Status', 'event_status', 'integer', 'f', 40, 't');
-- SELECT im_dynfield_attribute_new ('im_event', 'event_location_id', 'Location', 'event_location', 'integer', 'f', 50, 't');
SELECT im_dynfield_attribute_new ('im_event', 'event_material_id', 'Material', 'materials', 'integer', 'f', 100, 't');



-- DynField for Timesheet Tasks to show the NAV OrderItem
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'solidline_task_order_item', 'SolidLine Task Order Item', 'SolidLine Task Order Item',
	10007, 'integer', 'generic_sql', 'integer',
	'
{custom {sql "
select  item_id, item_name
from    im_invoice_items ii,
        im_costs c
where   ii.invoice_id = c.cost_id and
        c.customer_id in (
             select  company_id
             from    im_projects
             where   project_id = :task_id
        )
"}}
'
);


SELECT im_dynfield_attribute_new ('im_timesheet_task', 'nav_order_item_id', 'Order Item', 'solidline_task_order_item', 'integer', 'f', 100, 'f');





-- ------------------------------------------------------
-- Show users associated with event
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event Members',		-- plugin_name
	'intranet-events',		-- package_name
	'right',			-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	50,				-- sort_order
        'im_group_member_component $event_id $current_user_id $user_admin_p $return_url [im_profile_employee] "" 1',
	'lang::message::lookup "" intranet-events.Event_Consultants "Event Consultants"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Members' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



-- ------------------------------------------------------
-- Show customers associated with event
--

SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event Customers',		-- plugin_name
	'intranet-events',		-- package_name
	'bottom',			-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	50,				-- sort_order
        'im_event_customer_component $event_id $form_mode $plugin_id $view_name $orderby $return_url',
	'lang::message::lookup "" intranet-events.Event_Customers "Event Customers"'
);

update im_component_plugins 
set component_tcl = 'im_event_customer_component $event_id $form_mode $plugin_id $view_name $orderby $return_url'
where plugin_name = 'Event Customers';



SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Customers' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);




-- Order Items associated with event
--

SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event Order Items',		-- plugin_name
	'intranet-events',		-- package_name
	'bottom',			-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	50,				-- sort_order
        'im_event_order_item_component $event_id $form_mode $plugin_id $view_name $orderby $return_url',
	'lang::message::lookup "" intranet-events.Event_Order_Items "Event Order Items"'
);

update im_component_plugins
set component_tcl = 'im_event_order_item_component $event_id $form_mode $plugin_id $view_name $orderby $return_url'
where plugin_name = 'Event Order Items';


SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Order Items' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);




-- ------------------------------------------------------
-- Show customers associated with event
--

SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event Participants',		-- plugin_name
	'intranet-events',		-- package_name
	'bottom',			-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	100,				-- sort_order
        'im_event_participant_component $event_id $form_mode $plugin_id $view_name $orderby $return_url',
	'lang::message::lookup "" intranet-events.Event_Participants "Event Participants"'
);

update im_component_plugins
set component_tcl = 'im_event_participant_component $event_id $form_mode $plugin_id $view_name $orderby $return_url'
where plugin_name = 'Event Participants';

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Participants' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


-- ------------------------------------------------------
-- Show customers associated with event
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event New Participant',	-- plugin_name
	'intranet-events',		-- package_name
	'right',			-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	100,				-- sort_order
        'im_user_biz_card_component -limit_to_company_id $event_customer_ids -also_add_to_biz_object [list $event_id 1300] -return_url $return_url',
	'lang::message::lookup "" intranet-events.Event_New_Participants "Event New Participants"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Participants' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'New Company Contact',		-- plugin_name
	'intranet-core',		-- package_name
	'right',			-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	30,				-- sort_order
        'im_user_biz_card_component -limit_to_company_id $company_id -return_url $return_url',
	'lang::message::lookup "" intranet-core.New_Company_Contact "New Company Contact"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'New Company Contact' and package_name = 'intranet-core'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


-- ------------------------------------------------------
-- Show customers associated with event
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Event Resources',		-- plugin_name
	'intranet-events',		-- package_name
	'left',				-- location
	'/intranet-events/new',		-- page_url
	null,				-- view_name
	10,				-- sort_order
        'im_event_resource_component $event_id $form_mode $plugin_id $view_name $orderby $return_url',
	'lang::message::lookup "" intranet-events.Event_Resources "Event Resources"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Event Resources' and package_name = 'intranet-events'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);
