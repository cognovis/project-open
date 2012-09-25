-- /packages/intranet-confdb/sql/postgres/intranet-confdb-create.sql
--
-- Copyright (c) 2007 ]project-open[
-- All rights reserved.
--
-- @author	frank.bergmann@project-open.com

-- ConfigurationItems
--
-- Each project can have any number of sub-confdb

select acs_object_type__create_type (
	'im_conf_item',			-- object_type
	'Configuration Item',		-- pretty_name
	'Configuration Items',		-- pretty_plural
	'im_biz_object',		-- supertype
	'im_conf_items',		-- table_name
	'conf_item_id',			-- id_column
	'intranet-confdb',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_conf_item__name'		-- name_method
);


insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_conf_item', 'im_conf_items', 'conf_item_id');

update acs_object_types set
	status_type_table = 'im_conf_items',
	status_column = 'conf_item_status_id',
	type_column = 'conf_item_type_id',
	type_category_type = 'Intranet Conf Item Type'
where object_type = 'im_conf_item';


-------------------------------------------------------------
-- Business Object URLs

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_conf_item','view','/intranet-confdb/new?form_mode=display&conf_item_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_conf_item','edit','/intranet-configuration_items/new?form_mode=edit&conf_item_id=');


create table im_conf_items (
	conf_item_id		integer
				constraint im_conf_items_pk
				primary key
				constraint im_conf_item_prj_fk
				references acs_objects,
	conf_item_name		text not null,
	conf_item_nr		text not null,
	conf_item_version	text,

	-- Unique code for label
	conf_item_code		text,

	-- Single "main" parent.
	conf_item_parent_id	integer
				constraint im_conf_items_parent_fk
				references im_conf_items,

	-- Cache for CI hierarchy
	tree_sortkey		varbit,
	max_child_sortkey	varbit,

	-- Where is the CI located in the company hierarchy?
	conf_item_cost_center_id integer
				constraint im_conf_items_cost_center_fk
				references im_cost_centers,

	-- Is there an owner? Takes the owner from parent if null.
	conf_item_owner_id	integer
				constraint im_conf_items_owner_fk
				references persons,

	-- Type - deeply nested...
	conf_item_type_id	integer not null
				constraint im_conf_items_type_fk
				references im_categories,
	conf_item_status_id	integer not null
				constraint im_conf_items_status_fk
				references im_categories,
	sort_order		integer,
	description		text,
	note			text,

	-- OCS Inventory NG fields
	ip_address		varchar(50),

	ocs_id			text,
	ocs_deviceid		text,
	ocs_username		text,
	ocs_last_update		timestamptz,

	os_name			text,
	os_version		text,
	os_comments		text,

	win_workgroup		text,
	win_userdomain		text,
	win_company		text,
	win_owner		text,
	win_product_id		text,
	win_product_key		text,

	processor_text		text,
	processor_speed		integer,
	processor_num		integer,

	sys_memory		integer,
	sys_swap		integer
);


create index im_conf_item_parent_id_idx on im_conf_items(conf_item_parent_id);
create index im_conf_item_treesort_idx on im_conf_items(tree_sortkey);
create index im_conf_item_status_id_idx on im_conf_items(conf_item_status_id);
create index im_conf_item_type_id_idx on im_conf_items(conf_item_type_id);
create unique index im_conf_item_conf_item_code_idx on im_conf_items(conf_item_code);

-- Dont allow the same name for the same parent
alter table im_conf_items add
	constraint im_conf_items_name_un
	unique(conf_item_name, conf_item_parent_id);

-- Dont allow the same conf_item_nr  for the same parent
alter table im_conf_items add
	constraint im_conf_items_nr_un
	unique(conf_item_nr, conf_item_parent_id);



-- This is the sortkey code
--
create or replace function im_conf_item_insert_tr ()
returns trigger as '
declare
	v_max_child_sortkey	im_conf_items.max_child_sortkey%TYPE;
	v_parent_sortkey	im_conf_items.tree_sortkey%TYPE;
begin
	IF new.conf_item_parent_id is null THEN
		new.tree_sortkey := int_to_tree_key(new.conf_item_id+1000);
	ELSE
		select tree_sortkey, tree_increment_key(max_child_sortkey)
		into v_parent_sortkey, v_max_child_sortkey
		from im_conf_items
		where conf_item_id = new.conf_item_parent_id
		for update;

		update im_conf_items
		set max_child_sortkey = v_max_child_sortkey
		where conf_item_id = new.conf_item_parent_id;

		new.tree_sortkey := v_parent_sortkey || v_max_child_sortkey;
	END IF;
	new.max_child_sortkey := null;
	return new;
end;' language 'plpgsql';

create trigger im_conf_item_insert_tr
before insert on im_conf_items
for each row
execute procedure im_conf_item_insert_tr();



create or replace function im_conf_items_update_tr () 
returns trigger as '
declare
	v_parent_sk	varbit default null;
	v_max_child_sortkey	varbit;
	v_old_parent_length	integer;
begin
	IF new.conf_item_id = old.conf_item_id
		and ((new.conf_item_parent_id = old.conf_item_parent_id)
		or (new.conf_item_parent_id is null and old.conf_item_parent_id is null)) THEN
		return new;
	END IF;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

	IF new.conf_item_parent_id is null THEN
		v_parent_sk := int_to_tree_key(new.conf_item_id+1000);
	ELSE
		SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
		INTO v_parent_sk, v_max_child_sortkey
		FROM im_conf_items
		WHERE conf_item_id = new.conf_item_parent_id
		FOR UPDATE;

		UPDATE im_conf_items
		SET max_child_sortkey = v_max_child_sortkey
		WHERE conf_item_id = new.conf_item_parent_id;

		v_parent_sk := v_parent_sk || v_max_child_sortkey;
	END IF;

	UPDATE im_conf_items
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

	return new;
end;' language 'plpgsql';

create trigger im_conf_items_update_tr after update
on im_conf_items
for each row
execute procedure im_conf_items_update_tr ();




-- ------------------------------------------------------------
-- ConfItem Package
-- ------------------------------------------------------------

create or replace function im_conf_item__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
DECLARE
	p_conf_item_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_conf_item_name	alias for $7;
	p_conf_item_nr		alias for $8;
	p_conf_item_parent_id	alias for $9;
	p_conf_item_type_id	alias for $10;
	p_conf_item_status_id	alias for $11;

	v_conf_item_id	integer;
BEGIN
	v_conf_item_id := acs_object__new (
		p_conf_item_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_conf_items (
		conf_item_id, conf_item_name, conf_item_nr,
		conf_item_parent_id, conf_item_type_id, conf_item_status_id
	) values (
		v_conf_item_id, p_conf_item_name, p_conf_item_nr,
		p_conf_item_parent_id, p_conf_item_type_id, p_conf_item_status_id
	);
	return v_conf_item_id;
end;' language 'plpgsql';

create or replace function im_conf_item__delete (integer) returns integer as '
DECLARE
	v_conf_item_id		alias for $1;
BEGIN
	-- Erase the im_conf_items item associated with the id
	delete from 	im_conf_items
	where		conf_item_id = v_conf_item_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_conf_item_id;

	PERFORM	acs_object__delete(v_conf_item_id);

	return 0;
end;' language 'plpgsql';

create or replace function im_conf_item__name (integer) returns varchar as '
DECLARE
	v_conf_item_id	alias for $1;
	v_name		varchar;
BEGIN
	select	conf_item_name
	into	v_name
	from	im_conf_items
	where	conf_item_id = v_conf_item_id;

	return v_name;
end;' language 'plpgsql';


-- Helper functions to make our queries easier to read
create or replace function im_conf_item_name_from_id (integer)
returns varchar as '
DECLARE
	p_conf_item_id		alias for $1;
	v_conf_item_name	text;
BEGIN
	select conf_item_name
	into v_conf_item_name
	from im_conf_items
	where conf_item_id = p_conf_item_id;

	return v_conf_item_name;
end;' language 'plpgsql';


create or replace function im_conf_item_nr_from_id (integer)
returns varchar as '
DECLARE
	p_conf_item_id	alias for $1;
	v_name		text;
BEGIN
	select conf_item_nr
	into v_name
	from im_conf_items
	where conf_item_id = p_conf_item_id;

	return v_name;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Full-Text Search for Conf Items
-----------------------------------------------------------


insert into im_search_object_types values (9, 'im_conf_item', 0.8);


create or replace function im_conf_items_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select	coalesce(c.conf_item_code, '''') || '' '' ||
		coalesce(c.conf_item_name, '''') || '' '' ||
		coalesce(c.conf_item_nr, '''') || '' '' ||
		coalesce(c.conf_item_version, '''') || '' '' ||
		coalesce(c.description, '''') || '' '' ||
		coalesce(c.ip_address, '''') || '' '' ||
		coalesce(c.note, '''') || '' '' ||
		coalesce(c.ocs_deviceid, '''') || '' '' ||
		coalesce(c.ocs_id, '''') || '' '' ||
		coalesce(c.ocs_username, '''') || '' '' ||
		coalesce(c.os_comments, '''') || '' '' ||
		coalesce(c.os_name, '''') || '' '' ||
		coalesce(c.os_version, '''') || '' '' ||
		coalesce(c.processor_text, '''') || '' '' ||
		coalesce(c.win_company, '''') || '' '' ||
		coalesce(c.win_owner, '''') || '' '' ||
		coalesce(c.win_product_id, '''') || '' '' ||
		coalesce(c.win_product_key, '''') || '' '' ||
		coalesce(c.win_userdomain, '''') || '' '' ||
		coalesce(c.win_workgroup, '''')
	into    v_string
	from    im_conf_items c
	where   c.conf_item_id = new.conf_item_id;

	perform im_search_update(new.conf_item_id, ''im_conf_item'', new.conf_item_id, v_string);

	return new;
end;' language 'plpgsql';


CREATE TRIGGER im_conf_items_tsearch_tr
AFTER INSERT or UPDATE
ON im_conf_items
FOR EACH ROW
EXECUTE PROCEDURE im_conf_items_tsearch();




-- ------------------------------------------------------------
-- Categories
-- ------------------------------------------------------------

-- 11700-11799	Intranet Conf Item Status
-- 11800-11999	Intranet Conf Item Type
-- 12000-12999  Intranet ConfDB


-- ---------------------------------------------------------
-- Conf Item Status


-- 11700-11799	Intranet Conf Item Status
SELECT im_category_new(11700, 'Active', 'Intranet Conf Item Status');
SELECT im_category_new(11702, 'Preactive', 'Intranet Conf Item Status');
SELECT im_category_new(11716, 'Archived', 'Intranet Conf Item Status');
SELECT im_category_new(11718, 'Zombie', 'Intranet Conf Item Status');
SELECT im_category_new(11720, 'Inactive', 'Intranet Conf Item Status');
-- reserved to 11799


create or replace view im_conf_item_status as
select category_id as conf_item_status_id, category as conf_item_status
from im_categories
where category_type = 'Intranet Conf Item Status';



-- ---------------------------------------------------------
-- Conf Item Type

-- Top-level "ontology" of CIs
SELECT im_category_new(11800, 'Hardware', 'Intranet Conf Item Type');
SELECT im_category_new(11802, 'Software', 'Intranet Conf Item Type');
SELECT im_category_new(11804, 'Process', 'Intranet Conf Item Type');
SELECT im_category_new(11806, 'License', 'Intranet Conf Item Type');
SELECT im_category_new(11808, 'Specs', 'Intranet Conf Item Type');
SELECT im_category_new(11810, 'Service', 'Intranet Conf Item Type');
update im_categories set enabled_p = 'f' where category_id in (11804, 11808);
-- reserved to 11849


-- OCS Hardware Types
SELECT im_category_new(11850, 'Personal Computer', 'Intranet Conf Item Type'); 
SELECT im_category_new(11852, 'Workstation', 'Intranet Conf Item Type'); 
SELECT im_category_new(11854, 'Laptop', 'Intranet Conf Item Type'); 
SELECT im_category_new(11856, 'Server', 'Intranet Conf Item Type'); 
SELECT im_category_new(11858, 'Host', 'Intranet Conf Item Type'); 
SELECT im_category_new(11860, 'Mainframe', 'Intranet Conf Item Type'); 
SELECT im_category_new(11862, 'Network Device', 'Intranet Conf Item Type'); 

SELECT im_category_hierarchy_new('Personal Computer','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Workstation','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Laptop','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Server','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Host','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Mainframe','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Network Device','Hardware','Intranet Conf Item Type');
-- reserved to 11899

-- Hardware Components
SELECT im_category_new(11900, 'Hardware Component', 'Intranet Conf Item Type'); 
SELECT im_category_new(11902, 'Computer Bios', 'Intranet Conf Item Type'); 
SELECT im_category_new(11904, 'Computer Controller', 'Intranet Conf Item Type'); 
SELECT im_category_new(11906, 'Computer Drive', 'Intranet Conf Item Type'); 
SELECT im_category_new(11908, 'Computer File', 'Intranet Conf Item Type'); 
SELECT im_category_new(11910, 'Computer Input Device', 'Intranet Conf Item Type'); 
SELECT im_category_new(11912, 'Computer Lock', 'Intranet Conf Item Type'); 
SELECT im_category_new(11914, 'Computer Memory', 'Intranet Conf Item Type'); 
SELECT im_category_new(11916, 'Computer Modem', 'Intranet Conf Item Type'); 
SELECT im_category_new(11918, 'Computer Monitor', 'Intranet Conf Item Type'); 
SELECT im_category_new(11920, 'Computer Network Device', 'Intranet Conf Item Type'); 
SELECT im_category_new(11922, 'Computer Port', 'Intranet Conf Item Type'); 
SELECT im_category_new(11924, 'Computer Printer Driver', 'Intranet Conf Item Type'); 
SELECT im_category_new(11926, 'Computer Slot', 'Intranet Conf Item Type'); 
SELECT im_category_new(11928, 'Computer Sound Device', 'Intranet Conf Item Type'); 
SELECT im_category_new(11930, 'Computer Storage Device', 'Intranet Conf Item Type'); 
SELECT im_category_new(11932, 'Computer Video Device', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('Hardware Component','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Bios','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Controller','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Drive','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer File','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Input Device','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Lock','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Memory','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Modem','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Monitor','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Network Device','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Port','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Printer Driver','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Slot','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Sound Device','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Storage Device','Hardware Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Video Device','Hardware Component','Intranet Conf Item Type');
-- reserved to 11979


-- Host stuff
SELECT im_category_new(11980, 'Host Table', 'Intranet Conf Item Type');
SELECT im_category_new(11982, 'Host Program', 'Intranet Conf Item Type');
SELECT im_category_new(11984, 'Host Screen', 'Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Host Table','Software','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Host Program','Software','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Host Screen','Software','Intranet Conf Item Type');
-- reserved to 11999



----------------------------------------------------
-- 12000-12999  Intranet ConfDB (1000)

-- Software
SELECT im_category_new(12000, 'Software Component', 'Intranet Conf Item Type'); 
SELECT im_category_new(12002, 'Computer Software Package', 'Intranet Conf Item Type'); 
SELECT im_category_new(12004, 'Computer Driver', 'Intranet Conf Item Type'); 
SELECT im_category_new(12006, 'Software Application', 'Intranet Conf Item Type'); 
SELECT im_category_new(12008, 'Project Open Package', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('Software Component','Software','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Software Package','Software Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Computer Driver','Software Component','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Software Application','Software','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Project Open Package','Software','Intranet Conf Item Type');
-- reserved to 12099


-- Network Hardware
SELECT im_category_new(12100, 'Network Router', 'Intranet Conf Item Type'); 
SELECT im_category_new(12102, 'Network Switch', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('Network Router','Hardware','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Network Switch','Hardware','Intranet Conf Item Type');
-- reserved to 12199

-- IPs & Network
SELECT im_category_new(12200, 'Netmap', 'Intranet Conf Item Type'); 
SELECT im_category_new(12202, 'Subnet', 'Intranet Conf Item Type'); 
SELECT im_category_new(12204, 'Network', 'Intranet Conf Item Type'); 
-- reserved to 12299

-- Types of Processes
SELECT im_category_new(12300, 'Project Open Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12302, 'PostgreSQL Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12304, 'Postfix Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12306, 'Pound Process', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('Project Open Server','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('PostgreSQL Process','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Postfix Process','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Pound Process','Process','Intranet Conf Item Type');
-- reserved to 12399


-- Types of Services
SELECT im_category_new(12400, 'CVS Repository', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('CVS Repository','Service','Intranet Conf Item Type');
-- reserved to 12499




create or replace view im_conf_item_type as
select category_id as conf_item_type_id, category as conf_item_type
from im_categories
where category_type = 'Intranet Conf Item Type';


-----------------------------------------------------------
-- Permissions & Privileges
-----------------------------------------------------------

select acs_privilege__create_privilege('view_conf_items','View Conf Items','');
select acs_privilege__add_child('admin', 'view_conf_items');

select acs_privilege__create_privilege('view_conf_items_all','View all Conf Items','');
select acs_privilege__add_child('admin', 'view_conf_items_all');

select acs_privilege__create_privilege('add_conf_items','Add new Conf Items','');
select acs_privilege__add_child('admin', 'add_conf_items');


select im_priv_create('view_conf_items', 'P/O Admins');
select im_priv_create('view_conf_items', 'Senior Managers');
select im_priv_create('view_conf_items', 'Project Managers');
select im_priv_create('view_conf_items', 'Employees');

select im_priv_create('view_conf_items_all', 'P/O Admins');
select im_priv_create('view_conf_items_all', 'Senior Managers');
select im_priv_create('view_conf_items_all', 'Project Managers');
select im_priv_create('view_conf_items_all', 'Employees');

select im_priv_create('add_conf_items', 'P/O Admins');
select im_priv_create('add_conf_items', 'Senior Managers');
select im_priv_create('add_conf_items', 'Project Managers');
select im_priv_create('add_conf_items', 'Employees');



--------------------------------------------------------------
-- Business Object Roles

-- Setup the list of roles that a user can take with
-- respect to a company:
--      Full Member (1300) and
--      ToDo: Rename: Key Account Manager (1302)
--
insert into im_biz_object_role_map values ('im_conf_item',85,1300);
-- insert into im_biz_object_role_map values ('im_company',85,1302);



-----------------------------------------------------------
-- Relationship with projects
-----------------------------------------------------------



-- --------------------------------------------------------
-- Conf Item - Relationship between projects and Conf Items
--
-- This relationship connects Projects with "Conf Item"s


create table im_conf_item_project_rels (
	rel_id			integer
				constraint im_conf_item_project_rels_rel_fk
				references acs_rels (rel_id)
				constraint im_conf_item_project_rels_rel_pk
				primary key,
	sort_order		integer
);

select acs_rel_type__create_type (
   'im_conf_item_project_rel',	-- relationship (object) name
   'Conf Item Project Rel',	-- pretty name
   'Conf Item Project Rels',	-- pretty plural
   'relationship',		-- supertype
   'im_conf_item_project_rels',	-- table_name
   'rel_id',			-- id_column
   'intranet-conf-item-rel',	-- package_name
   'im_project',		-- object_type_one
   'member',			-- role_one
    0,				-- min_n_rels_one
    null,			-- max_n_rels_one
   'im_conf_item',		-- object_type_two
   'member',			-- role_two
   0,				-- min_n_rels_two
   null				-- max_n_rels_two
);


create or replace function im_conf_item_project_rel__new (
integer, varchar, integer, integer, integer, integer, varchar, integer)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_conf_item_project_rel
	p_project_id		alias for $3;
	p_conf_item_id		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_sort_order		alias for $8;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_project_id,
		p_conf_item_id,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_conf_item_project_rels (
	       rel_id, sort_order
	) values (
	       v_rel_id, p_sort_order
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_conf_item_project_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_conf_item_project_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_conf_item_project_rel__delete (integer, integer)
returns integer as '
DECLARE
        p_project_id	alias for $1;
	p_conf_item_id	alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_project_id
		and object_id_two = p_conf_item_id;

	PERFORM im_conf_item_project_rel__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';



-- -------------------------------------------------------------------
-- ConfItem List Page Configuration
-- -------------------------------------------------------------------

--
-- 940-949              intranet-confdb
--
--
-- Wide View in ConfItemListPage, including Description
--
delete from im_view_columns where view_id = 940;
delete from im_views where view_id = 940;
--
insert into im_views (view_id, view_name, visible_for) values (940, 'im_conf_item_list', 'view_conf_items');



--
-- short view for ticket and project pages
--
delete from im_view_columns where view_id = 941;
delete from im_views where view_id = 941;
--
insert into im_views (view_id, view_name, visible_for) values (941, 'im_conf_item_list_short', 'view_conf_items');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (94101,941,NULL, 
'"[im_gif del "Delete"]"', '"<input type=checkbox name=conf_item_id.$conf_item_id>"', '', '', 1, '');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (94105, 941, NULL, '"Name"',
'"<nobr>$indent_short_html$gif_html<a href=$object_url>$conf_item_name</a></nobr>"','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (94110, 941, NULL, '"Type"',
'"<nobr>$conf_item_type</nobr>"','','',10,'');





-----------------------------------------------------------
-- Components & Menus
-----------------------------------------------------------

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Configuration Items',	-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_conf_item_list_component -object_id $project_id'	-- component_tcl
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Configuration Items',	-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_conf_item_list_component -object_id $user_id'	-- component_tcl
);


-- Show the list of user's configuration items in the Ticket page
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Customer Configuration Items',	-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet-helpdesk/new',		-- page_url
	null,				-- view_name
	150,				-- sort_order
	'im_conf_item_list_component -owner_id $ticket_customer_contact_id'	-- component_tcl
);






-----------------------------------------------------------
-- Menu for Conf Items
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

	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_main_menu 
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-confdb'',	-- package_name
		''conf_items'',		-- label
		''Conf Items'',		-- name
		''/intranet-confdb/index'',   -- url
		95,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-----------------------------------------------------------
-- Member component for CIs
-----------------------------------------------------------

SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	'Conf Item Members',		-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet-confdb/new',		-- page_url
	null,				-- view_name	
	20,				-- sort_order
	'im_group_member_component $conf_item_id $current_user_id $user_admin_p $return_url "" "" 1'
);


-- ------------------------------------------------------
-- Show related objects
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Conf Item Related Objects',	-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet-confdb/new',		-- page_url
	null,				-- view_name
	91,				-- sort_order
	'im_conf_item_related_objects_component -conf_item_id $conf_item_id',
	'lang::message::lookup "" intranet-confdb.Conf_Item_Related_Objects "Conf Item Related Objects"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Conf Item Related Objects' and package_name = 'intranet-confdb'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);






-----------------------------------------------------------
-- DynFields
-----------------------------------------------------------


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'conf_items_servers', 'Server Conf Items', 'Server Conf Items',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
select
	ci.conf_item_id,
	ci.conf_item_name
from
	im_conf_items ci
where
	ci.conf_item_parent_id is null and
	(''t'' = acs_permission__permission_p([subsite::main_site_id], [ad_get_user_id], ''view_conf_items_all'') OR
	conf_item_id in (
		-- User is explicit member of conf item
		select  ci.conf_item_id
		from    im_conf_items ci,
			acs_rels r
		where   r.object_id_two = [ad_get_user_id] and
			r.object_id_one = ci.conf_item_id
	UNION
		-- User belongs to project that belongs to conf item
		select  ci.conf_item_id
		from    im_conf_items ci,
			im_projects p,
			acs_rels r1,
			acs_rels r2
		where   r1.object_id_two = [ad_get_user_id] and
			r1.object_id_one = p.project_id and
			r2.object_id_two = ci.conf_item_id and
			r2.object_id_one = p.project_id
	UNION
		-- User belongs to a company which is the customer of project that belongs to conf item
		select  ci.conf_item_id
		from    im_companies c,
			im_conf_items ci,
			im_projects p,
			acs_rels r1,
			acs_rels r2
		where   r1.object_id_two = [ad_get_user_id] and
			r1.object_id_one = c.company_id and
			p.company_id = c.company_id and
			r2.object_id_two = ci.conf_item_id and
			r2.object_id_one = p.project_id
	))
order by
	ci.conf_item_name
}}}');





-----------------------------------------------------------
-- ]po[ Component

alter table im_conf_items add conf_item_customer_id integer;
SELECT im_dynfield_attribute_new ('im_conf_item', 'conf_item_customer_id', 'Customer', 'customers_active', 'integer', 'f');





-----------------------------------------------------------
-- OCS Inventory DynFields

SELECT im_dynfield_attribute_new ('im_conf_item', 'ip_address', 'IP Address', 'textbox_medium', 'string', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'os_name', 'OS Name', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'os_version', 'OS Version', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'os_comments', 'OS Comments', 'textarea_small_nospell', 'string', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'win_workgroup', 'Win Workgroup', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_userdomain', 'Win Userdomain', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_company', 'Win Company', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_owner', 'Win Owner', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_product_id', 'Win Product ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_product_key', 'Win Product Key', 'textbox_medium', 'string', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_text', 'Proc Text', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_speed', 'Proc Speed', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_num', 'Proc Num', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'sys_memory', 'Sys Memory', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'sys_swap', 'Sys Swap', 'textbox_medium', 'integer', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_id', 'OCS ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_deviceid', 'OCS Device ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_username', 'OCS Username', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_last_update', 'OCS Last Update', 'textbox_medium', 'string', 'f');

