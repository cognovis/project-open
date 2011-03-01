-- /packages/intranet-release-mgmt/sql/postgresql/intranet-release-mgmt-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- --------------------------------------------------------
-- Release Item - Release Releationship
--
-- This relationship connects "Release" projects with other 
-- "Release Item" projects. The release_status_id determines
-- the readyness for the item in the parent release.
-- --------------------------------------------------------

create table im_release_items (
	rel_id			integer
				constraint im_release_items_rel_fk
				references acs_rels (rel_id)
				constraint im_release_items_rel_pk
				primary key,
	release_status_id	integer not null
				constraint im_release_items_role_fk
				references im_categories,
	sort_order		integer
);

select acs_rel_type__create_type (
   'im_release_item',		-- relationship (object) name
   'Release Member',		-- pretty name
   'Release Members',		-- pretty plural
   'relationship',		-- supertype
   'im_release_items',		-- table_name
   'rel_id',			-- id_column
   'intranet-release-mgmt',	-- package_name
   'im_project',		-- object_type_one
   'member',			-- role_one
    0,				-- min_n_rels_one
    null,			-- max_n_rels_one
   'acs_object',		-- object_type_two
   'member',			-- role_two
   0,				-- min_n_rels_two
   null				-- max_n_rels_two
);

-- ------------------------------------------------------------
-- Project Membership Packages
-- ------------------------------------------------------------

create or replace function im_release_item__new (
integer, varchar, integer, integer, integer, integer, varchar, integer, integer)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_release_item
	p_release_id		alias for $3;
	p_item_id		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_release_status_id	alias for $8;
	p_sort_order		alias for $9;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_release_id,
		p_item_id,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_release_items (
	       rel_id, release_status_id, sort_order
	) values (
	       v_rel_id, p_release_status_id, p_sort_order
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_release_item__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_release_items
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_release_item__delete (integer, integer)
returns integer as '
DECLARE
        p_object_id       alias for $1;
	p_user_id	  alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_object_id
		and object_id_two = p_user_id;

	PERFORM im_release_item__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';




---------------------------------------------------------
-- Release-Mgmt Component
--

-- Show the forum component in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Release Items Component',	-- plugin_name
	'intranet-release-mgmt',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	30,				-- sort_order
	'im_release_mgmt_project_component -project_id $project_id -return_url $return_url',
	'lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"'
);

-- Journal component below the Release Items component
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Release Items Journal',	-- plugin_name
	'intranet-release-mgmt',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	31,				-- sort_order
	'im_release_mgmt_journal_component -project_id $project_id -return_url $return_url',
	'lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"'
);


-- Task Board component
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Task Board',			-- plugin_name
	'intranet-release-mgmt',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order - top one of the "bottom" portlets
	'im_release_mgmt_task_board_component -project_id $project_id',
	'lang::message::lookup "" intranet-release-mgmt.Task_Board "Task Board"'
);


SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Task Board' and package_name = 'intranet-release-mgmt'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



---------------------------------------------------------
-- Add category types
---------------------------------------------------------

-- 27000-27999  Intranet Release Management (1000)
-- 27000-27099	Intranet Release Status (100)
-- 27100-27999	still free

SELECT im_category_new(27000, '0-Developing', 'Intranet Release Status',null);
SELECT im_category_new(27040, '1-Ready for Review', 'Intranet Release Status',null);
SELECT im_category_new(27050, '2-Ready for Integration', 'Intranet Release Status',null);
SELECT im_category_new(27060, '3-Ready for Integration Test', 'Intranet Release Status',null);
SELECT im_category_new(27070, '4-Ready for Acceptance Test', 'Intranet Release Status',null);
SELECT im_category_new(27085, '5-Ready for Production', 'Intranet Release Status',null);
SELECT im_category_new(27090, '6-Ready to be closed', 'Intranet Release Status',null);
SELECT im_category_new(27095, '7-Closed', 'Intranet Release Status',null);



create or replace view im_release_status as
select category_id as status_id, category as status
from im_categories
where category_type = 'Intranet Release Status';


---------------------------------------------------------
-- New Object Type for Releases
---------------------------------------------------------

INSERT INTO im_categories (category_id, category, category_type, enabled_p) 
VALUES (4599,'Software Release','Intranet Project Type', 't');

INSERT INTO im_categories (category_id, category, category_type, enabled_p) 
VALUES (4597,'Software Release Item','Intranet Project Type', 'f');


---------------------------------------------------------
-- DynField to mark release items
---------------------------------------------------------
create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_acs_attrib_id		integer;
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := ''release_item_p'';
	v_attrib_pretty := ''Release Item'';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		''im_project'',
		v_attrib_name,
		''boolean'',
		v_attrib_pretty,
		v_attrib_pretty,
		''im_projects'',
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	alter table im_projects add release_item_p varchar(1);
	v_attrib_id := acs_object__new (
		 null,
		 ''im_dynfield_attribute'',
		 now(),
		 null, null, null
	);
	insert into im_dynfield_attributes
	(attribute_id, acs_attribute_id, widget_name, deprecated_p) values
	( v_attrib_id, v_acs_attrib_id, ''checkbox'', ''f'');

	insert into im_dynfield_type_attribute_map (
		 attribute_id, object_type_id, display_mode
	) values (
		v_attrib_id, 4599, ''edit''
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();
