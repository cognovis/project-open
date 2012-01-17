-- /packages/intranet-helpdesk/sql/postgresql/intranet-helpdesk-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-----------------------------------------------------------
-- Helpdesk Ticket

SELECT acs_object_type__create_type (
	'im_ticket',			-- object_type
	'Ticket',			-- pretty_name
	'Ticket',			-- pretty_plural
	'im_project',			-- supertype
	'im_tickets',			-- table_name
	'ticket_id',			-- id_column
	'intranet-helpdesk',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_ticket__name'		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_ticket', 'im_tickets', 'ticket_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_ticket', 'im_projects', 'project_id');


insert into im_biz_object_urls (object_type, url_type, url) values (
'im_ticket','view','/intranet-helpdesk/new?form_mode=display&ticket_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_ticket','edit','/intranet-helpdesk/new?ticket_id=');

-- Create "Full Member" role for tickets
insert into im_biz_object_role_map values ('im_ticket',null,1300);

-- Define where the system can find the status and type of the ticket.
-- Allows for automatic workflow updates and display
update acs_object_types set
		status_type_table = 'im_tickets',
		status_column = 'ticket_status_id',
		type_column = 'ticket_type_id',
		type_category_type = 'Intranet Ticket Type'
where object_type = 'im_ticket';

SELECT im_category_new(101, 'Ticket', 'Intranet Project Type');

-- Disable "Ticket" so that it doesn't appear in the list of project types
update im_categories
set enabled_p = 'f'
where category = 'Ticket' and category_type = 'Intranet Project Type';


-- Create a new profile
select im_create_profile ('Helpdesk','helpdesk');

create sequence im_ticket_seq;
create table im_tickets (
	ticket_id			integer
					constraint im_ticket_id_pk
					primary key
					constraint im_ticket_id_fk
					references im_projects,
	ticket_status_id		integer 
					constraint im_ticket_status_nn
					not null
					constraint im_ticket_status_fk
					references im_categories,
	ticket_type_id			integer
					constraint im_ticket_type_nn
					not null
					constraint im_ticket_type_fk
					references im_categories,
	ticket_prio_id			integer
					constraint im_ticket_prio_fk
					references im_categories,
	ticket_customer_contact_id	integer
					constraint im_ticket_customr_contact_fk
					references persons,
	ticket_assignee_id		integer
					constraint im_ticket_assignee_fk
					references persons,
	ticket_service_id		integer
					constraint im_ticket_service_fk
					references im_categories,
	ticket_conf_item_id		integer
					constraint im_ticket_conf_item_fk
					references im_conf_items,
	ticket_component_id		integer,
	ticket_queue_id			integer
					constraint im_ticket_queue_fk
					references groups,
	ticket_dept_id			integer
					constraint im_ticket_dept_fk
					references im_cost_centers,

	ticket_alarm_date		timestamptz,
	ticket_alarm_action		text,
	ticket_note			text,

	-- Creation
	ticket_creation_date		timestamptz,
	-- First human reaction from provider side
	ticket_reaction_date		timestamptz,
	-- Confirmation that this is an issue
	ticket_confirmation_date	timestamptz,
	-- Provider says ticket is done
	ticket_done_date		timestamptz,
	-- Customer confirms ticket is done
	ticket_signoff_date		timestamptz,

	ticket_description		text,
	ticket_customer_deadline	timestamptz,
	ticket_quoted_days		numeric(12,2),
	ticket_quote_comment		text,
	ticket_telephony_request_type_id integer,
	ticket_telephony_old_number 	text,
	ticket_telephony_new_number 	text
);

-- Create indices on type and status to speedup queries
create index im_ticket_type_id_idx on im_tickets(ticket_type_id);
create index im_ticket_status_id_idx on im_tickets(ticket_status_id);



-----------------------------------------------------------
-- Permissions & Privileges
-----------------------------------------------------------

select acs_privilege__create_privilege('view_tickets_all','View all Tickets','');
select acs_privilege__add_child('admin', 'view_tickets_all');

select acs_privilege__create_privilege('add_tickets','Add new Tickets','');
select acs_privilege__add_child('admin', 'add_tickets');

select acs_privilege__create_privilege('edit_ticket_status','Add new Tickets','');
select acs_privilege__add_child('admin', 'edit_ticket_status');

select acs_privilege__create_privilege('add_tickets_for_customers','Add new Tickets for customers','');
select acs_privilege__add_child('admin', 'add_tickets_for_customers');



select im_priv_create('view_tickets_all', 'P/O Admins');
select im_priv_create('view_tickets_all', 'Senior Managers');
select im_priv_create('view_tickets_all', 'Project Managers');
select im_priv_create('view_tickets_all', 'Employees');

select im_priv_create('add_tickets', 'P/O Admins');
select im_priv_create('add_tickets', 'Senior Managers');
select im_priv_create('add_tickets', 'Project Managers');
select im_priv_create('add_tickets', 'Employees');
select im_priv_create('add_tickets', 'Customers');

select im_priv_create('edit_ticket_status', 'P/O Admins');
select im_priv_create('edit_ticket_status', 'Senior Managers');

select im_priv_create('add_tickets_for_customers', 'P/O Admins');
select im_priv_create('add_tickets_for_customers', 'Senior Managers');
select im_priv_create('add_tickets_for_customers', 'Project Managers');
select im_priv_create('add_tickets_for_customers', 'Employees');



-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_ticket__name(integer)
returns varchar as '
DECLARE
	p_ticket_id		alias for $1;
	v_name			varchar;
BEGIN
	select	project_name into v_name from im_projects
	where	project_id = p_ticket_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_ticket__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer 
) returns integer as '
DECLARE
	p_ticket_id		alias for $1;		-- ticket_id default null
	p_object_type		alias for $2;		-- object_type default im_ticket
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_ticket_name		alias for $7;		-- ticket_name
	p_ticket_nr		alias for $8;		-- ticket_name
	p_ticket_customer_id	alias for $9;
	p_ticket_type_id	alias for $10;		
	p_ticket_status_id	alias for $11;
	v_ticket_id		integer;
BEGIN
	v_ticket_id := im_project__new (
		p_ticket_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		p_ticket_name,
		p_ticket_nr::varchar,
		p_ticket_nr::varchar,
		null,			-- parent_id
		p_ticket_customer_id,
		101,			-- p_project_type_id
		76			-- p_project_status_id	
	);

	update im_projects set
		start_date = now()
	where project_id = v_ticket_id;

	insert into im_tickets (
		ticket_id, ticket_status_id, ticket_type_id, ticket_creation_date
	) values (
		v_ticket_id, p_ticket_status_id, p_ticket_type_id, now()
	);

	return v_ticket_id;
END;' language 'plpgsql';



create or replace function im_ticket__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, integer, integer, integer 
) returns integer as '
DECLARE
	p_ticket_id		alias for $1;		-- ticket_id default null
	p_object_type		alias for $2;		-- object_type default im_ticket
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_ticket_name		alias for $7;		-- ticket_name
	p_ticket_customer_id	alias for $8;
	p_ticket_type_id	alias for $9;		
	p_ticket_status_id	alias for $10;
	v_ticket_nr		integer;
BEGIN
	select nextval(''im_ticket_seq'') into v_ticket_nr;

	return im_ticket__new (
		p_ticket_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id,
		p_ticket_name,
		v_ticket_nr,
		p_ticket_customer_id,
		p_ticket_type_id,
		p_ticket_status_id	
	);

END;' language 'plpgsql';




create or replace function im_ticket__delete(integer)
returns integer as '
DECLARE
	p_ticket_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_tickets
	where	ticket_id = p_ticket_id;

	-- Finally delete the object iself
	PERFORM im_project__delete(p_ticket_id);

	return 0;
end;' language 'plpgsql';



-----------------------------------------------------------
-- Full-Text Search for Tickets
-----------------------------------------------------------


insert into im_search_object_types values (8,'im_ticket',0.7);

create or replace function im_tickets_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select  coalesce(p.project_name, '''') || '' '' ||
		coalesce(p.project_nr, '''') || '' '' ||
		coalesce(p.project_path, '''') || '' '' ||
		coalesce(p.description, '''') || '' '' ||
		coalesce(p.note, '''') || '' '' ||
		coalesce(t.ticket_note, '''') || '' '' ||
		coalesce(t.ticket_description, '''')
	into    v_string
	from    im_tickets t,
		im_projects p
	where   p.project_id = new.ticket_id and
		t.ticket_id = p.project_id;

	perform im_search_update(new.ticket_id, ''im_ticket'', new.ticket_id, v_string);

	return new;
end;' language 'plpgsql';


CREATE TRIGGER im_tickets_tsearch_tr
AFTER INSERT or UPDATE
ON im_tickets
FOR EACH ROW
EXECUTE PROCEDURE im_tickets_tsearch();




-----------------------------------------------------------
-- Relationship between Tickets
-----------------------------------------------------------
--
-- Implements "This ticket has been already solved in THAT other ticket"

create table im_ticket_ticket_rels (
	rel_id			integer
				constraint im_ticket_ticket_rels_rel_fk
				references acs_rels (rel_id)
				constraint im_ticket_ticket_rels_rel_pk
				primary key,
	sort_order		integer
);

select acs_rel_type__create_type (
   'im_ticket_ticket_rel',	-- relationship (object) name
   'Ticket Ticket Rel',		-- pretty name
   'Ticket Ticket Rels',	-- pretty plural
   'relationship',		-- supertype
   'im_ticket_ticket_rels',	-- table_name
   'rel_id',			-- id_column
   'intranet-helpdesk-tt-rel',	-- package_name
   'im_project',		-- object_type_one
   'member',			-- role_one
    0,				-- min_n_rels_one
    null,			-- max_n_rels_one
   'im_ticket',			-- object_type_two
   'member',			-- role_two
   0,				-- min_n_rels_two
   null				-- max_n_rels_two
);


create or replace function im_ticket_ticket_rel__new (
integer, varchar, integer, integer, integer, integer, varchar, integer)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_ticket_ticket_rel
	p_object_id_one		alias for $3;
	p_object_id_two		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_sort_order		alias for $8;

	v_rel_id	integer;
BEGIN
	IF p_object_id_one = p_object_id_two THEN return 0; END IF;

	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_object_id_one,
		p_object_id_two,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_ticket_ticket_rels (
	       rel_id, sort_order
	) values (
	       v_rel_id, p_sort_order
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_ticket_ticket_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_ticket_ticket_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_ticket_ticket_rel__delete (integer, integer)
returns integer as '
DECLARE
        p_ticket_id_one		alias for $1;
	p_ticket_id_two		alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_ticket_id_one
		and object_id_two = p_ticket_id_two;

	PERFORM im_ticket_ticket_rel__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';






-----------------------------------------------------------
-- Create Ticket Queue datatype as a dynamically managed group
-----------------------------------------------------------

select acs_object_type__create_type (
	'im_ticket_queue',
	'Ticket Queue',
	'Ticket Queues',
	'group',
	'IM_TICKET_QUEUE_EXT',
	'GROUP_ID',
	'im_ticket_queue',
	'f',
	null,
	null
);


insert into acs_object_type_tables VALUES ('im_ticket_queue', 'im_ticket_queue_ext', 'group_id');

-- update acs_object_types set
-- 		status_type_table = 'im_tickets',
-- 		status_column = 'ticket_status_id',
-- 		type_column = 'ticket_type_id'
-- where object_type = 'im_ticket';

-- Mark ticket_queue as a dynamically managed object type
update acs_object_types 
set dynamic_p='t' 
where object_type = 'im_ticket_queue';


-- Copy group type_rels to queues
insert into group_type_rels (group_rel_type_id, rel_type, group_type)
select
	nextval('t_acs_object_id_seq'), 
	r.rel_type, 
	'im_ticket_queue'
from
	group_type_rels r
where
	r.group_type = 'group';


create table im_ticket_queue_ext (
	group_id	integer
			constraint ITQE_GROUP_ID_PK primary key
			constraint ITQE_GROUP_ID_FK
			references groups (group_id)
);


select define_function_args('im_ticket_queue__new','GROUP_ID,GROUP_NAME,EMAIL,URL,LAST_MODIFIED;now(),MODIFYING_IP,OBJECT_TYPE;im_ticket_queue,CONTEXT_ID,CREATION_USER,CREATION_DATE;now(),CREATION_IP,JOIN_POLICY');

create function im_ticket_queue__new(INT4,VARCHAR,VARCHAR,VARCHAR,TIMESTAMPTZ,VARCHAR,VARCHAR,INT4,INT4,TIMESTAMPTZ,VARCHAR,VARCHAR)
returns INT4 as '
declare
	p_GROUP_ID		alias for $1;
	p_GROUP_NAME		alias for $2;
	p_EMAIL			alias for $3;
	p_URL			alias for $4;
	p_LAST_MODIFIED		alias for $5;
	p_MODIFYING_IP		alias for $6;

	p_OBJECT_TYPE		alias for $7;
	p_CONTEXT_ID		alias for $8;
	p_CREATION_USER		alias for $9;
	p_CREATION_DATE		alias for $10;
	p_CREATION_IP		alias for $11;
	p_JOIN_POLICY		alias for $12;

	v_GROUP_ID 		IM_TICKET_QUEUE_EXT.GROUP_ID%TYPE;
begin
	v_GROUP_ID := acs_group__new (
		p_group_id,p_OBJECT_TYPE,
		p_CREATION_DATE,p_CREATION_USER,
		p_CREATION_IP,p_EMAIL,
		p_URL,p_GROUP_NAME,
		p_JOIN_POLICY,p_CONTEXT_ID
	);
	insert into IM_TICKET_QUEUE_EXT (GROUP_ID) values (v_GROUP_ID);
	return v_GROUP_ID;
end;' language 'plpgsql';

create function im_ticket_queue__delete (INT4)
returns integer as '
declare
	p_GROUP_ID	alias for $1;
begin
	perform acs_group__delete( p_GROUP_ID );
	return 1;
end;' language 'plpgsql';


-- Create a first group
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count			integer;
BEGIN
	select count(*) into v_count from groups
	where group_name = ''Linux Admins'';
	IF v_count > 0 THEN return 0; END IF;

	PERFORM im_ticket_queue__new(
		null, ''Linux Admins'', NULL, NULL, now(), NULL, 
		''im_ticket_queue'', null, 0, now(), ''0.0.0.0'', 
		NULL
	);
	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


-----------------------------------------------------------
-- New "SLA" Project Type
--

SELECT im_category_new (2502, 'Service Level Agreement', 'Intranet Project Type');


-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Helpdesk type and status.
-- Status acutally is not use, so we just define "active"

-- Here are the ranges for the constants as defined in
-- /intranet-core/sql/common/intranet-categories.sql
--
-- Please contact support@project-open.com if you need to
-- reserve a range of constants for a new module.
--
-- 30000-39999	Intranet Helpdesk (10000)
--
-- 30000-30099	Intranet Ticket Status (100)
-- 30100-30199	Intranet Ticket Type (100)
-- 30200-30299	Intranet Ticket User Priority (100)
-- 30300-30399	Intranet Ticket Technical Priority (100)
-- 30400-30499	Intranet Service Catalog (100)
-- 30500-30599	Intranet Ticket Action (100)
-- 30600-30699	Intranet Ticket Telephony Request Type
-- 31000-31999	Intranet Ticket Class (1000)
-- 32000-32999	Intranet Service Catalog (Extension 1000)
-- 33000-33999	reserved (1000)
-- 34000-34999	reserved (1000)
-- 35000-39999	reserved (5000)


-- 30100-30199	Intranet Ticket Type
--

-- Ticket types for ITIL management categories
SELECT im_category_new(30150, 'Incident Ticket', 'Intranet Ticket Type');
SELECT im_category_new(30152, 'Problem Ticket', 'Intranet Ticket Type');
SELECT im_category_new(30154, 'Change Ticket', 'Intranet Ticket Type');

-- Disable meta-categories for normal use
update im_categories set
	enabled_p = 'f'
where	category_id in (30150, 30152, 30154);


-- Specific ticket types
SELECT im_category_new(30102, 'Purchasing Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30102, 30154);
SELECT im_category_new(30104, 'Workplace move Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30104, 30154);
SELECT im_category_new(30106, 'Telephony Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30106, 30154);
SELECT im_category_new(30108, 'Project Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30108, 30154);
SELECT im_category_new(30110, 'Bug Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30110, 30150);
SELECT im_category_new(30112, 'Report Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30112, 30154);
SELECT im_category_new(30114, 'Permission Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30114, 30154);
SELECT im_category_new(30116, 'Feature Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30116, 30154);
SELECT im_category_new(30118, 'Training Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30118, 30154);
SELECT im_category_new(30120, 'SLA Request', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30120, 30150);
SELECT im_category_new(30122, 'Nagios Alert', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30122, 30150);


SELECT im_category_new(30130, 'Generic Problem Ticket', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30130, 30152);




update im_categories set category = 'Purchasing Request' where category = 'Purchasing request';
update im_categories set category = 'Workplace Move Request' where category = 'Workplace move request';
update im_categories set category = 'Telephony Request' where category = 'Telephony request';
update im_categories set category = 'Project Request' where category = 'Project request';
update im_categories set category = 'Bug Request' where category = 'Bug request';
update im_categories set category = 'Report Request' where category = 'Report request';
update im_categories set category = 'Permission Request' where category = 'Permission request';
update im_categories set category = 'Feature Request' where category = 'Feature request';
update im_categories set category = 'Training Request' where category = 'Training request';


update im_categories set category_description = 'Request to buy a new IT hardware or software item.' 
where category = 'Purchasing Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request to move a user to a different work place.' 
where category = 'Workplace Move Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request new telephone equipment or a modified telephone number.' 
where category = 'Telephony Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request a new project (> 5 days of work).' 
where category = 'Project Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Report a bug. Please use this category only for clearly faulty system behaviour. Otherwise please use a "Feature Request".'
where category = 'Bug Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request a new report.' 
where category = 'Report Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request to grant or remove permissions for a user and a particular system.' 
where category = 'Permission Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request to implement a new features for a system.' 
where category = 'Feature Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Request training time or training material.' 
where category = 'Training Request' and category_type = 'Intranet Ticket Type';
update im_categories set category_description = 'Generic heavy-weight problemm responsible for multiple incidents.' 
where category = 'Generic Problem Ticket' and category_type = 'Intranet Ticket Type';



----------------------------------------------------------
-- Define workflows per ticket type
----------------------------------------------------------

-- by default use "ticket_generic_wf" for all ticket types
update im_categories set aux_string1 = 'ticket_generic_wf'
where	category_type = 'Intranet Ticket Type';

-- special feature_request WF: includes quoting
update im_categories set aux_string1 = 'feature_request_wf'
where	category_id = 30116;

-- SLA requests are meta-tickets for users without SLAs
update im_categories set aux_string1 = 'sla_request_wf'
where	category_id = 30120;




----------------------------------------------------------
-- 30000-30099	Intranet Ticket Status
----------------------------------------------------------

--
-- High-Level States
--
SELECT im_category_new(30000, 'Open', 'Intranet Ticket Status');
SELECT im_category_new(30001, 'Closed', 'Intranet Ticket Status');

--
-- Open States
--
SELECT im_category_new(30009, 'Modifying', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30009, 30000);

SELECT im_category_new(30010, 'In review', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30010, 30000);

SELECT im_category_new(30011, 'Assigned', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30011, 30000);

SELECT im_category_new(30012, 'Customer review', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30012, 30000);

SELECT im_category_new(30014, 'Quoting', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30014, 30000);

SELECT im_category_new(30016, 'Quote Sign-off', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30016, 30000);

SELECT im_category_new(30018, 'Assigning', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30018, 30000);

SELECT im_category_new(30020, 'Executing', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30020, 30000);

SELECT im_category_new(30022, 'Sign-off', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30022, 30000);

SELECT im_category_new(30024, 'Invoicing', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30024, 30000);

SELECT im_category_new(30026, 'Waiting for Other', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30026, 30000);

-- SELECT im_category_new(30028, 'Frozen', 'Intranet Ticket Status');
-- SELECT im_category_hierarchy_new(30028, 30001);


--
-- Closed States
--
SELECT im_category_new(30090, 'Duplicate', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30090, 30001);
SELECT im_category_new(30091, 'Invalid', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30091, 30001);
SELECT im_category_new(30092, 'Outdated', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30092, 30001);
SELECT im_category_new(30093, 'Rejected', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30093, 30001);
SELECT im_category_new(30094, 'Won''t fix', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30094, 30001);
SELECT im_category_new(30095, 'Can''t reproduce', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30095, 30001);
SELECT im_category_new(30096, 'Resolved', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30096, 30001);
SELECT im_category_new(30097, 'Deleted', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30097, 30001);
SELECT im_category_new(30098, 'Canceled', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30098, 30001);



----------------------------------------------------------
-- 30400-30499	Intranet Service Catalog
----------------------------------------------------------

SELECT im_category_new(30400, 'End user support', 'Intranet Service Catalog');
SELECT im_category_new(30420, 'System administrator support', 'Intranet Service Catalog');
SELECT im_category_new(30410, 'Hosting service', 'Intranet Service Catalog');
SELECT im_category_new(30430, 'Software update service', 'Intranet Service Catalog');



-- 35000-35099	1st level of Intranet Ticket Class
SELECT im_category_new(31000, 'Broken system or configuration', 'Intranet Ticket Class');

SELECT im_category_new(31001, 'Bug/error in application', 'Intranet Ticket Class');
SELECT im_category_new(31002, 'Network access to application unavailable or slow', 'Intranet Ticket Class');
SELECT im_category_new(31003, 'Performance issues with application', 'Intranet Ticket Class');
SELECT im_category_new(31005, 'Browser issue: Information is rendered incorrectly', 'Intranet Ticket Class');
SELECT im_category_new(31006, 'Report does not show expected data', 'Intranet Ticket Class');
SELECT im_category_new(31008, 'Security issue', 'Intranet Ticket Class');
SELECT im_category_new(31009, 'Issues with backup & recovery', 'Intranet Ticket Class');
SELECT im_category_hierarchy_new(31001, 31000);
SELECT im_category_hierarchy_new(31002, 31000);
SELECT im_category_hierarchy_new(31003, 31000);
SELECT im_category_hierarchy_new(31005, 31000);
SELECT im_category_hierarchy_new(31006, 31000);
SELECT im_category_hierarchy_new(31008, 31000);
SELECT im_category_hierarchy_new(31009, 31000);

SELECT im_category_new(31100, 'Invalid data in system', 'Intranet Ticket Class');

SELECT im_category_new(31101, 'Missing or bad master data', 'Intranet Ticket Class');
SELECT im_category_hierarchy_new(31101, 31100);

SELECT im_category_new(31200, 'Lack of user competency, ability or knowledge', 'Intranet Ticket Class');

SELECT im_category_new(31201, 'New user creation', 'Intranet Ticket Class');
SELECT im_category_new(31202, 'Extension/reduction of user permissions', 'Intranet Ticket Class');
SELECT im_category_new(31203, 'Training Request', 'Intranet Ticket Class');
SELECT im_category_new(31204, 'Incorrect or incomplete documentation', 'Intranet Ticket Class');
SELECT im_category_new(31205, 'Issue to export data', 'Intranet Ticket Class');

SELECT im_category_new(31300, 'Requests for new/additional services', 'Intranet Ticket Class');



-- 30200-30299 - Intranet Ticket User Priority
SELECT im_category_new(30201, '1', 'Intranet Ticket Priority');
SELECT im_category_new(30202, '2', 'Intranet Ticket Priority');
SELECT im_category_new(30203, '3', 'Intranet Ticket Priority');
SELECT im_category_new(30204, '4', 'Intranet Ticket Priority');
SELECT im_category_new(30205, '5', 'Intranet Ticket Priority');
SELECT im_category_new(30206, '6', 'Intranet Ticket Priority');
SELECT im_category_new(30207, '7', 'Intranet Ticket Priority');
SELECT im_category_new(30208, '8', 'Intranet Ticket Priority');
SELECT im_category_new(30209, '9', 'Intranet Ticket Priority');


-- 30500-30599 - Intranet Ticket Action
delete from im_categories where category_type = 'Intranet Ticket Action';
SELECT im_category_new(30500, 'Close', 'Intranet Ticket Action');
SELECT im_category_new(30510, 'Close &amp; notify', 'Intranet Ticket Action');
-- SELECT im_category_new(30515, 'Freeze', 'Intranet Ticket Action');


-- Custom screen for duplicate action to select base
SELECT im_category_new(30520, 'Duplicated', 'Intranet Ticket Action');
update im_categories set aux_string1 = '/intranet-helpdesk/action-duplicated' 
where category_id = 30520;

SELECT im_category_new(30530, 'Re-Open', 'Intranet Ticket Action');
SELECT im_category_new(30532, 'Re-Open &amp; notify', 'Intranet Ticket Action');

SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');
SELECT im_category_new(30550, 'Escalate', 'Intranet Ticket Action');
SELECT im_category_new(30552, 'Close Escalated Tickets', 'Intranet Ticket Action');

SELECT im_category_new(30560, 'Resolved', 'Intranet Ticket Action');

SELECT im_category_new(30590, 'Delete', 'Intranet Ticket Action');
SELECT im_category_new(30599, 'Nuke', 'Intranet Ticket Action');



-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_ticket_status as
select	category_id as ticket_status_id, category as ticket_status
from	im_categories
where	category_type = 'Intranet Ticket Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_ticket_types as
select	category_id as ticket_type_id, category as ticket_type
from	im_categories
where	category_type = 'Intranet Ticket Type'
	and (enabled_p is null or enabled_p = 't');



-----------------------------------------------------------
-- Component Plugin
--
-- Forum component on the ticket page itself

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Discussions',			-- plugin_name - shown in menu
	'intranet-helpdesk',		-- package_name
	'bottom',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_forum_full_screen_component -object_id $ticket_id',	-- component_tcl
	'lang::message::lookup "" "intranet-helpdesk.Ticket_Discussions" "Ticket Discussions"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Discussions' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

-- Dont hide this component like the other ones below,
-- it should appear by default on the "summary" page


-- Timesheet plugin
select im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creattion_ip
	null,					-- context_id

	'Timesheet',				-- plugin_name - shown in menu
	'intranet-helpdesk',			-- package_name
	'right',				-- location
	'/intranet-helpdesk/new',		-- page_url
	null,					-- view_name
	50,					-- sort_order
	'im_timesheet_project_component $current_user_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Timesheet "Ticket Timesheet"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Timesheet' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


create or replace function inline_0 ()
returns integer as '
declare
	row			RECORD;
	v_plugin_id		integer;
	v_sort_order		integer;
BEGIN
	select plugin_id, sort_order into v_plugin_id, v_sort_order from im_component_plugins
	where package_name = ''intranet-helpdesk'' and plugin_name = ''Timesheet'';
	FOR row IN
		select user_id from users_active au
		where 0 = (
			select count(*) from im_component_plugin_user_map cpum
			where cpum.user_id = au.user_id and cpum.plugin_id = v_plugin_id
		)
	LOOP
		insert into im_component_plugin_user_map (plugin_id, user_id, sort_order, minimized_p, location)
		values (v_plugin_id, row.user_id, v_sort_order, ''f'', ''none'');
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- ------------------------------------------------------
-- Workflow Graph

SELECT	im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Workflow',				-- component_name - shown in menu
	'intranet-helpdesk',			-- package_name
	'right',				-- location
	'/intranet-helpdesk/new',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_workflow_graph_component -object_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Workflow "Ticket Workflow"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Workflow' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- move component to Ticket Menu Tab for all users
create or replace function inline_0 ()
returns integer as '
declare
	row			RECORD;
	v_plugin_id		integer;
	v_sort_order		integer;
BEGIN
	select plugin_id, sort_order into v_plugin_id, v_sort_order from im_component_plugins 
	where package_name = ''intranet-helpdesk'' and plugin_name = ''Workflow'';
	FOR row IN 
		select user_id from users_active au
		where 0 = (
			select count(*) from im_component_plugin_user_map cpum
			where cpum.user_id = au.user_id and cpum.plugin_id = v_plugin_id
		)
	LOOP
		insert into im_component_plugin_user_map (plugin_id, user_id, sort_order, minimized_p, location)
		values (v_plugin_id, row.user_id, v_sort_order, ''f'', ''none'');
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- ------------------------------------------------------
-- Journal on Absence View Page

SELECT	im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Journal',				-- component_name - shown in menu
	'intranet-helpdesk',			-- package_name
	'bottom',				-- location
	'/intranet-helpdesk/new',		-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_workflow_journal_component -object_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Journal "Ticket Journal"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Journal' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


-- move component to Ticket Menu Tab for all users
create or replace function inline_0 ()
returns integer as '
declare
	row			RECORD;
	v_plugin_id		integer;
	v_sort_order		integer;
BEGIN
	select plugin_id, sort_order into v_plugin_id, v_sort_order from im_component_plugins 
	where package_name = ''intranet-helpdesk'' and plugin_name = ''Journal'';
	FOR row IN 
		select user_id from users_active au
		where 0 = (
			select count(*) from im_component_plugin_user_map cpum
			where cpum.user_id = au.user_id and cpum.plugin_id = v_plugin_id
		)
	LOOP
		insert into im_component_plugin_user_map (plugin_id, user_id, sort_order, minimized_p, location)
		values (v_plugin_id, row.user_id, v_sort_order, ''f'', ''none'');
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- ------------------------------------------------------
-- Filestorage on Absence View Page

SELECT	im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Filestorage',				-- component_name - shown in menu
	'intranet-helpdesk',			-- package_name
	'bottom',				-- location
	'/intranet-helpdesk/new',		-- page_url
	null,					-- view_name
	110,					-- sort_order
	'im_filestorage_ticket_component $user_id $ticket_id $ticket_name $return_url', -- component_tcl
	'lang::message::lookup "" intranet-helpdesk.Ticket_Filestorage "Ticket Filestorage"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Filestorage' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

-- move component to Ticket Menu Tab for all users
create or replace function inline_0 ()
returns integer as '
declare
	row			RECORD;
	v_plugin_id		integer;
	v_sort_order		integer;
BEGIN
	select plugin_id, sort_order into v_plugin_id, v_sort_order from im_component_plugins 
	where package_name = ''intranet-helpdesk'' and plugin_name = ''Filestorage'';
	FOR row IN 
		select user_id from users_active au
		where 0 = (
			select count(*) from im_component_plugin_user_map cpum
			where cpum.user_id = au.user_id and cpum.plugin_id = v_plugin_id
		)
	LOOP
		insert into im_component_plugin_user_map (plugin_id, user_id, sort_order, minimized_p, location)
		values (v_plugin_id, row.user_id, v_sort_order, ''f'', ''none'');
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- ------------------------------------------------------
-- List of Tickets at the home page
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home Ticket Component',	-- plugin_name
	'intranet-helpdesk',		-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	20,				-- sort_order
	'im_helpdesk_home_component',
	'lang::message::lookup "" intranet-helpdesk.Home_Ticket_Component "Home Ticket Component"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Home Ticket Component' and package_name = 'intranet-helpdesk'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



-- ------------------------------------------------------
-- Workflow Actions in the object's View Page
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Actions',			-- plugin_name
	'intranet-helpdesk',		-- package_name
	'left',				-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	0,				-- sort_order
	'im_workflow_action_component -object_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Workflow_Actions "Ticket Workflow Actions"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins 
	 where plugin_name = 'Actions' and package_name = 'intranet-helpdesk'
	),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins 
	 where plugin_name = 'Actions' and package_name = 'intranet-helpdesk'
	),
        (select group_id from groups where group_name = 'Customers'),
        'read'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins 
	 where plugin_name = 'Actions' and package_name = 'intranet-helpdesk'),
        (select group_id from groups where group_name = 'Freelancers'),
        'read'
);



-- ------------------------------------------------------
-- Show the customer contacts information
-- to allow the helpdesk to contact the customer
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Customer Info',		-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_user_base_info_component -user_id $ticket_customer_contact_id',
	'lang::message::lookup "" intranet-helpdesk.Customer_Info "Customer Info"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Customer Info' and package_name = 'intranet-helpdesk'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



-- ------------------------------------------------------
-- Show related objects
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Ticket Related Objects',	-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	91,				-- sort_order
	'im_biz_object_related_objects_component -object_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Related_Objects "Ticket Related Objects"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Ticket Related Objects' and package_name = 'intranet-helpdesk'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


-- ------------------------------------------------------
-- Show users associated with ticket
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Ticket Members',		-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	80,				-- sort_order
        'im_group_member_component $ticket_id $current_user_id $user_admin_p $return_url "" "" 1',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Members "Ticket Members"'
);

SELECT acs_permission__grant_permission(
        (
		select plugin_id
		from im_component_plugins 
		where plugin_name = 'Ticket Members' and package_name = 'intranet-helpdesk'
	),
        (
		select group_id 
		from groups 
		where group_name = 'Employees'
	),
        'read'
);


-----------------------------------------------------------
-- Menu for Helpdesk
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_companies from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-helpdesk'',	-- package_name
		''helpdesk'',		-- label
		''Tickets'',		-- name
		''/intranet-helpdesk/'',	-- url
		75,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-----------------------------------------------------------
-- "Summary" Tab for ticket submenu
--

SELECT im_menu__new (
	null,				-- p_menu_id
	'im_menu',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'intranet-helpdesk',		-- package_name
	'helpdesk_summary',		-- label
	'Summary',			-- name
	'/intranet-helpdesk/new?form_mode=display',	-- url
	10,				-- sort_order
	(select menu_id from im_menus where label = 'helpdesk'),
	null				-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'helpdesk_summary'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




-----------------------------------------------------------
-- "Tickets" Section for reports
--

SELECT im_menu__new (
	null,				-- p_menu_id
	'im_menu',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'intranet-helpdesk',		-- package_name
	'reporting-tickets',		-- label
	'Tickets',			-- name
	'/intranet-helpdesk/index',	-- url
	100,				-- sort_order
	(select menu_id from im_menus where label = 'reporting'),
	null				-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'reporting-tickets'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




-----------------------------------------------------------
-- TicketListPage Main View
-----------------------------------------------------------

delete from im_view_columns where view_id = 270;
delete from im_views where view_id = 270;
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (270, 'ticket_list', 'view_tickets', 1400);

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27000,270,00, 'Prio','"$ticket_prio"');

delete from im_view_columns where column_id = 27010;
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27010,270,10, 'Nr','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_nr</a>\
<a href=/intranet-helpdesk/new?form_mode=edit&ticket_id=$ticket_id>[im_gif wrench]</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27020,270,20,'Name','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(270220,270,22,'Conf Item','"<A href=/intranet-confdb/new?form_mode=display&conf_item_id=$conf_item_id>$conf_item_name</a>"');

-- insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
-- (27025,270,25,'Queue','"<href=/intranet-helpdesk/queue/?queue_id=$ticket_queue_id>$ticket_queue_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27030,270,30,'Type','$ticket_type');
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27040,270,40,'Status','$ticket_status');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27050,270,50,'Customer','"<A href=/intranet/companies/view?company_id=$company_id>$company_name</A>"');
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27060,270,60,'Contact','"<A href=/intranet/users/view?user_id=$ticket_customer_contact_id>$ticket_customer_contact</a>"');

-- insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
-- (27070,270,70,'Assignee','"<A href=/intranet/users/view?user_id=$ticket_assignee_id>$ticket_assignee</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27080,270,80,'SLA','"<A href=/intranet/projects/view?project_id=$sla_id>$sla_name</a>"');

update im_view_columns set visible_for = 'im_permission $current_user_id "view_tickets_all"'
where column_id = 27080;

-- Add a "select all" checkbox to select all tickets in the list
delete from im_view_columns where column_id = 27099;
insert into im_view_columns (
        column_id, view_id, sort_order,
	column_name,
	column_render_tcl,
        visible_for
) values (
        27099,270,-1,
        '<input type=checkbox name=_dummy onclick="acs_ListCheckAll(''ticket'',this.checked)">',
        '$action_checkbox',
        ''
);

-- insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
-- (27030,270,70,'Start Date','$start_date_formatted');

-- insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
-- (27035,270,80,'Delivery Date','$end_date_formatted');



-----------------------------------------------------------
-- Home Personal Tickets
-----------------------------------------------------------

delete from im_view_columns where view_id = 271;
delete from im_views where view_id = 271;
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (271, 'ticket_personal_list', 'view_tickets', 1400);

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27100,271,00, 'Prio','"$ticket_prio"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27110,271,10, 'Nr','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_nr</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27120,271,20,'Name','"<href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27130,271,30,'Type','$ticket_type');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27140,271,40,'Status','$ticket_status');




-----------------------------------------------------------
-- Duplicate Ticket select view
-----------------------------------------------------------


delete from im_view_columns where view_id = 272;
delete from im_views where view_id = 272;
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (272, 'ticket_list_duplicates', '', 1400);

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27210,272,10, 'Nr','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_nr</a>"');
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27220,272,20,'Name','"<href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_name</A>"');
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27230,272,30,'Type','$ticket_type');
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27240,272,40,'Status','$ticket_status');

-- Add a "select" radio button to select one of the tickets from the list
delete from im_view_columns where column_id = 27299;
insert into im_view_columns (
        column_id, view_id, sort_order,
	column_name,
	column_render_tcl,
        visible_for
) values (
        27299,272,0,
        'Sel',
        '"<input type=radio name=ticket_id_from_search value=$ticket_id>"',
        ''
);



-----------------------------------------------------------
-- DynField Widgets
--


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_priority', 'Ticket Priority', 'Ticket Priority',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Ticket Priority"}}'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'telephony_request_type', 'Telephony Request Type', 'Telephony Request Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Ticket Telephony Request Type"}}'
);

-- 30600-30699
SELECT im_category_new (30600, 'New Telephony Line', 'Intranet Ticket Telephony Request Type');
SELECT im_category_new (30605, 'Additional Line', 'Intranet Ticket Telephony Request Type');
SELECT im_category_new (30610, 'Restriction Settings', 'Intranet Ticket Telephony Request Type');
SELECT im_category_new (30690, 'Other', 'Intranet Ticket Telephony Request Type');


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'customer_contact', 'Customer Contact', 'Customer Contacts',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id = 461 order by lower(im_name_from_user_id(u.user_id)) }}}'
);



SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_assignees', 'Ticket Assignees', 'Ticket Assignees',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, 
		group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id in (
			select group_id from groups where group_name = ''Helpdesk''
		) order by lower(im_name_from_user_id(u.user_id)) 
	}}}'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_queues', 'Ticket Queues', 'Ticket Queues',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	g.group_id, g.group_name
		from	groups g,
			acs_objects o
		where	o.object_type = ''im_ticket_queue'' and
			g.group_id = o.object_id
		order by lower(g.group_name)
	}}}'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_po_components', 'Ticket &#93;po&#91; Components', 'Ticket &#93;po&#91; Components',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
select	ci.conf_item_id,
	ci.conf_item_name
from	im_conf_items ci
where	ci.conf_item_parent_id in (
		select	conf_item_id
		from	im_conf_items
		where	conf_item_parent_id is null and
			conf_item_nr = ''po''
	)
order by
	ci.conf_item_nr

}}}');




SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'service_level_agreements', 'Service Level Agreements', 'Service Level Agreements',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	
			p.project_id,
			p.project_name
		from 
			im_projects p
		where 
			p.project_type_id = 2502 and
			p.project_status_id in (select * from im_sub_categories(76))
		order by 
			lower(project_name) 
	}}}'
);






-----------------------------------------------------------
-- Hard Coded DynFields
--
SELECT im_dynfield_attribute_new (
	'im_ticket', 'project_name', 'Name', 'textbox_medium', 'string', 'f', 0, 't', 'im_projects'
);
SELECT im_dynfield_attribute_new (
	'im_ticket', 'parent_id', 'Service Level Agreement', 'service_level_agreements', 
	'integer', 'f', 10, 't', 'im_projects'
);
SELECT im_dynfield_attribute_new (
	'im_ticket', 'ticket_status_id', 'Status', 'ticket_status', 'integer', 'f', 20, 't', 'im_tickets'
);
SELECT im_dynfield_attribute_new (
	'im_ticket', 'ticket_type_id', 'Type', 'ticket_type', 'integer', 'f', 30, 't', 'im_tickets'
);



-----------------------------------------------------------
-- Other fields
--

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_prio_id', 'Priority', 'ticket_priority', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_assignee_id', 'Assignee', 'ticket_assignees', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_note', 'Note', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_component_id', 'Software Component', 'ticket_po_components', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_conf_item_id', 'Hardware Component', 'conf_items_servers', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_description', 'Description', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_deadline', 'Desired Customer End Date', 'date', 'date', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quoted_days', 'Quoted Days', 'numeric', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quote_comment', 'Quote Comment', 'textarea_small_nospell', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_request_type_id', 'Telephony Request Type', 'telephony_request_type', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_old_number', 'Old Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_new_number', 'New Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_contact_id', 'Customer Contact', 'customer_contact', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_dept_id', 'Department', 'cost_centers', 'integer', 'f');


-----------------------------------------------------------
-- Unused fields
--

	-- ticket_service_id                | integer                  |
-- ticket_hardware_id               | integer                  |
-- ticket_application_id            | integer                  |
-- ticket_queue_id                  | integer                  |
-- ticket_alarm_date                | timestamp with time zone |
-- ticket_alarm_action              | text                     |
-- ticket_creation_date             | timestamp with time zone |
-- ticket_reaction_date             | timestamp with time zone |
-- ticket_confirmation_date         | timestamp with time zone |
-- ticket_done_date                 | timestamp with time zone |
-- ticket_signoff_date              | timestamp with time zone |
-- ocs_software_id                  | integer                  |



-----------------------------------------------------------
-- More files
-----------------------------------------------------------

\i intranet-helpdesk-notifications-create.sql


-----------------------------------------------------------
-- Workflows
-----------------------------------------------------------

-- Define default ticket workflows
\i workflow-feature_request_wf-create.sql
\i workflow-ticket_generic_wf-create.sql
