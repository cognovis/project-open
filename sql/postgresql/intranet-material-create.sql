-- /packages/intranet-material/sql/postgresql/intranet-material-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Materials
--
-- Materials are split in a separate table (not implemented
-- via im_categories) because we expect that there will be
-- many additional information to them.
-- However, the material_type_id links them into a Material
-- Type which forms a hierarchy.

select acs_object_type__create_type (
	'im_material',		-- object_type
	'Material',		-- pretty_name
	'Materials',		-- pretty_plural
	'acs_object',		-- supertype
	'im_materials',		-- table_name
	'material_id',		-- id_column
	'intranet-material',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_material.name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_material', 'im_materials', 'material_id');

update acs_object_types set
        status_type_table = 'im_materials',
        status_column = 'material_status_id',
        type_column = 'material_type_id'
where object_type = 'im_material';


create table im_materials (
	material_id		integer
				constraint im_material_pk 
				primary key
				constraint im_material_id_fk
				references acs_objects,
	material_name		text,
	material_nr		text,
	material_type_id	integer not null
				constraint im_materials_material_type_fk
				references im_categories,
	material_status_id	integer
				constraint im_materials_material_status_fk
				references im_categories,
	material_uom_id		integer
				constraint im_materials_material_uom_fk
				references im_categories,
	material_billable_p	char(1) default 't'
				constraint im_materials_billable_ck
				check (material_billable_p in ('t','f')),
	description		text
);
create unique index im_material_material_nr_idx on im_materials (material_nr);
create index im_material_material_type_id_idx on im_materials (material_type_id);
create index im_material_material_status_id_idx on im_materials (material_status_id);


------------------------------------------------------
-- Permissions and Privileges
--

select acs_privilege__create_privilege('view_materials','View Materials','View Materials');
select acs_privilege__add_child('admin', 'view_materials');

select acs_privilege__create_privilege('add_materials','Add Materials','Add Materials');
select acs_privilege__add_child('admin', 'add_materials');


select im_priv_create('view_materials','Accounting');
select im_priv_create('view_materials','P/O Admins');
select im_priv_create('view_materials','Senior Managers');

select im_priv_create('add_materials','Accounting');
select im_priv_create('add_materials','P/O Admins');
select im_priv_create('add_materials','Senior Managers');



---------------------------------------------------------
-- Material Object Type

create or replace function im_material__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer, varchar
) returns integer as '
declare
	p_material_id		alias for $1;		-- material_id default null
	p_object_type		alias for $2;		-- object_type default ''im_material''
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_material_name		alias for $7;	
	p_material_nr		alias for $8;	
	p_material_type_id	alias for $9;
	p_material_status_id	alias for $10;
	p_material_uom_id	alias for $11;
	p_description		alias for $12;

	v_material_id		integer;
    begin
 	v_material_id := acs_object__new (
                p_material_id,            -- object_id
                p_object_type,            -- object_type
                p_creation_date,          -- creation_date
                p_creation_user,          -- creation_user
                p_creation_ip,            -- creation_ip
                p_context_id,             -- context_id
                ''t''                     -- security_inherit_p
        );

	insert into im_materials (
		material_id,
		material_name, material_nr,
		material_type_id, material_status_id,
		material_uom_id, description
	) values (
		p_material_id,
		p_material_name, p_material_nr,
		p_material_type_id, p_material_status_id,
		p_material_uom_id, p_description
	);

	return v_material_id;
end;' language 'plpgsql';



-- Delete a single material (if we know its ID...)
create or replace function  im_material__delete (integer)
returns integer as '
declare
	p_material_id alias for $1;	-- material_id
begin
	-- Erase the material
	delete from 	im_materials
	where		material_id = p_material_id;

        -- Erase the object
        PERFORM acs_object__delete(p_material_id);
        return 0;
end;' language 'plpgsql';


create or replace function im_material__name (integer)
returns varchar as '
declare
	p_material_id alias for $1;	-- material_id
	v_name	varchar;
begin
	select	material_nr
	into	v_name
	from	im_materials
	where	material_id = p_material_id;
	return v_name;
end;' language 'plpgsql';



-- -------------------------------------------------------------
-- Helper function

create or replace function im_material_nr_from_id (integer)
returns varchar as '
DECLARE
        p_id    alias for $1;
        v_name  varchar;
BEGIN
        select m.material_nr
        into v_name
        from im_materials m
        where material_id = p_id;

        return v_name;
end;' language 'plpgsql';


create or replace function im_material_name_from_id (integer)
returns varchar as '
DECLARE
        p_id    alias for $1;
        v_name  varchar;
BEGIN
        select m.material_name
        into v_name
        from im_materials m
        where material_id = p_id;

        return v_name;
end;' language 'plpgsql';





---------------------------------------------------------
-- Register component
--

-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...
select im_component_plugin__del_module('intranet-material');
select im_menu__del_module('intranet-material');



---------------------------------------------------------
-- Setup the "Materials" main menu entry
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_main_menu		integer;
	v_admin_menu		integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
BEGIN

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-material'',	-- package_name
        ''material'',   	-- label
        ''Materials'',   -- name
        ''/intranet-material/'', -- url
        75,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();






----------------------------------------------------------
-- Material Cateogries
--
-- 9000-9999    Intranet Material Reserved Range


-------------------------------
-- Material Types
-- delete from im_categories where category_type = 'Intranet Material Type';

SELECT im_category_new(9000, 'Other', 'Intranet Material Type');
SELECT im_category_new(9002, 'Maintenance', 'Intranet Material Type');
SELECT im_category_new(9004, 'Licenses', 'Intranet Material Type');
SELECT im_category_new(9006, 'Consulting', 'Intranet Material Type');
SELECT im_category_new(9008, 'Software Dev.', 'Intranet Material Type');
SELECT im_category_new(9010, 'Web Site Dev.', 'Intranet Material Type');
SELECT im_category_new(9012, 'Generic PM', 'Intranet Material Type');
SELECT im_category_new(9014, 'Translation', 'Intranet Material Type');

-- reserved until 9099



create or replace view im_material_types as 
select 
	category_id as material_type_id, 
	category as material_type
from im_categories 
where category_type = 'Intranet Material Type';



-------------------------------
-- Intranet Material Status
delete from im_categories where category_type = 'Intranet Material Status';

INSERT INTO im_categories VALUES (9100,'Active',
'','Intranet Material Status','category','t','f');

INSERT INTO im_categories VALUES (9102,'Inactive',
'','Intranet Material Status','category','t','f');

-- reserved until 9199


create or replace view im_material_status as 
select 	category_id as material_status_id, 
	category as material_status
from im_categories 
where category_type = 'Intranet Material Status';
	

create or replace view im_material_status_active as 
select 	category_id as material_status_id, 
	category as material_status
from im_categories 
where	category_type = 'Intranet Material Status'
	and category_id not in (9102);


--------------------------------------------------------------
-- views to "material" items: 900-999
insert into im_views (view_id, view_name, visible_for) values (900, 'material_list', 'view_materials');


-- MaterialList
--
delete from im_view_columns where column_id >= 90000 and column_id < 90099;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90000,900,NULL,'Nr',
'"<a href=/intranet-material/new?[export_url_vars material_id return_url]>$material_nr</a>"',
'','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90002,900,NULL,'Name',
'"<a href=/intranet-material/new?[export_url_vars material_id return_url]>$material_name</a>"',
'','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90004,900,NULL,'Type',
'$material_type','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90006,900,NULL,'Status',
'$material_status','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90008,900,NULL,'UoM',
'$uom','','',8,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90009,900,NULL,'Bill',
'$material_billable_p','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (90010,900,NULL,
'Description', '$description', '','',10,'');






-- Create one default material - so that the Material
-- select box in TaskNewPage isnt empty
select im_material__new (
	 acs_object_id_seq.nextval::integer, 'im_material', now(), null, '0.0.0.0', null,
	'Default Material', 'default', 9000, 9100, 320, 'Default Material'
);
