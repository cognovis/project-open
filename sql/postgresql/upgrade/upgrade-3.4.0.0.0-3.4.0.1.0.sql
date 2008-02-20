-- upgrade-3.4.0.0.0-3.4.0.1.0.sql



create or replace function im_project_managers_enumerator (integer) 
returns setof integer as '
declare
	p_project_id		alias for $1;

	v_project_id		integer;
	v_parent_id		integer;
	v_project_lead_id	integer;
	v_count			integer;
BEGIN
	v_project_id := p_project_id;
	v_count := 100;

	WHILE (v_project_id is not null AND v_count > 0) LOOP
		select	parent_id, project_lead_id into v_parent_id, v_project_lead_id
		from	im_projects where project_id = v_project_id;

		IF v_project_lead_id is not null THEN RETURN NEXT v_project_lead_id; END IF;
		v_project_id := v_parent_id;
		v_count := v_count - 1;
	END LOOP;

	RETURN;
end;' language 'plpgsql';


CREATE OR REPLACE FUNCTION ad_group_member_p(integer, integer)
RETURNS character AS '
DECLARE
	p_user_id		alias for $1;
	p_group_id		alias for $2;

	ad_group_member_count	integer;
BEGIN
	select count(*)	into ad_group_member_count
	from	acs_rels r,
		membership_rels mr
	where
		r.rel_id = mr.rel_id
		and object_id_one = p_group_id
		and object_id_two = p_user_id
		and mr.member_state = ''approved''
	;

	if ad_group_member_count = 0 then
		return ''f'';
	else
		return ''t'';
	end if;
END;' LANGUAGE 'plpgsql';


-- ---------------------------------------------------------------
-- Find out the status and type of business objects in a generic way

CREATE OR REPLACE FUNCTION im_biz_object__get_type_id (integer)
RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;

	v_query			varchar;
	v_object_type		varchar;
	v_supertype		varchar;
	v_table			varchar;
	v_id_column		varchar;
	v_column		varchar;

	row			RECORD;
	v_result_id		integer;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.table_name, ot.id_column, ot.type_column
	into	v_object_type, v_supertype, v_table, v_id_column, v_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id
		and o.object_type = ot.object_type;

	-- Check if the object has a supertype and update table and id_column if necessary
	WHILE ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
	--	RAISE NOTICE ''im_biz_object__get_type_id: % has supertype %: '', v_object_type, v_supertype;
		select	ot.supertype, ot.table_name, ot.id_column
		into	v_supertype, v_table, v_id_column
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;


	IF v_table is null OR v_id_column is null OR v_column is null THEN
	--	RAISE NOTICE ''im_biz_object__get_type_id: Found null value for %: v_table=%, v_id_column=%, v_column=%'', 
	--	v_object_type, v_table, v_id_column, v_column;
		return 0;
	END IF;

	v_query := '' select '' || v_column || '' as result_id '' || '' from '' || v_table || 
		'' where '' || v_id_column || '' = '' || p_object_id;

	-- Funny way, but this is the only option to get a value from an EXECUTE in PG 8.0 and below.
	FOR row IN EXECUTE v_query
	LOOP
		v_result_id := row.result_id;
		EXIT;
	END LOOP;

	return v_result_id;
END;' language 'plpgsql';



CREATE OR REPLACE FUNCTION im_biz_object__get_status_id (integer)
RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;

	v_query			varchar;
	v_object_type		varchar;
	v_supertype		varchar;
	v_table			varchar;
	v_id_column		varchar;
	v_column		varchar;

	row			RECORD;
	v_result_id		integer;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.table_name, ot.id_column, ot.status_column
	into	v_object_type, v_supertype, v_table, v_id_column, v_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id
		and o.object_type = ot.object_type;

	-- Check if the object has a supertype and update table and id_column if necessary
	WHILE ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
	--	RAISE NOTICE ''im_biz_object__get_status_id: % has supertype %: '', v_object_type, v_supertype;
		select	ot.supertype, ot.table_name, ot.id_column
		into	v_supertype, v_table, v_id_column
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;


	IF v_table is null OR v_id_column is null OR v_column is null THEN
	--	RAISE NOTICE ''im_biz_object__get_status_id: Found null value for %: v_table=%, v_id_column=%, v_column=%'', 
	--	v_object_type, v_table, v_id_column, v_column;
		return 0;
	END IF;

	v_query := '' select '' || v_column || '' as result_id '' || '' from '' || v_table || 
		'' where '' || v_id_column || '' = '' || p_object_id;

	-- Funny way, but this is the only option to get a value from an EXECUTE in PG 8.0 and below.
	FOR row IN EXECUTE v_query
	LOOP
		v_result_id := row.result_id;
		EXIT;
	END LOOP;

	return v_result_id;
END;' language 'plpgsql';



-----------------------------------------------------------------------
-- Set the status of Biz Objects in a generic way


CREATE OR REPLACE FUNCTION im_biz_object__set_status_id (integer, integer) RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;
	p_status_id		alias for $2;
	v_object_type		varchar;
	v_supertype		varchar;	v_table			varchar;
	v_id_column		varchar;	v_column		varchar;
	row			RECORD;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.table_name, ot.id_column, ot.status_column
	into	v_object_type, v_supertype, v_table, v_id_column, v_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id
		and o.object_type = ot.object_type;

	-- Check if the object has a supertype and update table and id_column if necessary
	WHILE ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
		select	ot.supertype, ot.table_name, ot.id_column
		into	v_supertype, v_table, v_id_column
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;

	IF v_table is null OR v_id_column is null OR v_column is null THEN
		RAISE NOTICE ''im_biz_object__set_status_id: Bad metadata: Null value for %'',v_object_type;
		return 0;
	END IF;

	EXECUTE ''update ''||v_table||'' set ''||v_column||''=''||p_status_id||\
		'' where ''||v_id_column||''=''||p_object_id;
	return 0;
END;' language 'plpgsql';




create or replace function im_component_plugin__new (
	integer, varchar, timestamptz, integer, varchar, integer, 
	varchar, varchar, varchar, varchar, varchar, integer, varchar
) returns integer as '
declare
	p_plugin_id	alias for $1;	-- default null
	p_object_type	alias for $2;	-- default ''acs_object''
	p_creation_date	alias for $3;	-- default now()
	p_creation_user	alias for $4;	-- default null
	p_creation_ip	alias for $5;	-- default null
	p_context_id	alias for $6;	-- default null
	p_plugin_name	alias for $7;
	p_package_name	alias for $8;
	p_location	alias for $9;
	p_page_url	alias for $10;
	p_view_name	alias for $11;
	p_sort_order	alias for $12;
	p_component_tcl	alias for $13;
	v_plugin_id	integer;
begin
	v_plugin_id := im_component_plugin__new (
		p_plugin_id, p_object_type, p_creation_date,
		p_creation_user, p_creation_ip, p_context_id,
		p_plugin_name, p_package_name,
		p_location, p_page_url,
		p_view_name, p_sort_order,
		p_component_tcl, null
	);
	return v_plugin_id;
end;' language 'plpgsql';




create or replace function im_component_plugin__new (
	integer, varchar, timestamptz, integer, varchar, integer, 
	varchar, varchar, varchar, varchar, varchar, integer, 
	varchar, varchar
) returns integer as '
declare
	p_plugin_id	alias for $1;	-- default null
	p_object_type	alias for $2;	-- default ''acs_object''
	p_creation_date	alias for $3;	-- default now()
	p_creation_user	alias for $4;	-- default null
	p_creation_ip	alias for $5;	-- default null
	p_context_id	alias for $6;	-- default null

	p_plugin_name	alias for $7;
	p_package_name	alias for $8;
	p_location	alias for $9;
	p_page_url	alias for $10;
	p_view_name	alias for $11;	-- default null
	p_sort_order	alias for $12;
	p_component_tcl	alias for $13;
	p_title_tcl	alias for $14;

	v_plugin_id	im_component_plugins.plugin_id%TYPE;
	v_count		integer;
begin
	select count(*) into v_count
	from im_component_plugins
	where plugin_name = p_plugin_name;

	IF v_count > 0 THEN return 0; END IF;

	v_plugin_id := acs_object__new (
		p_plugin_id,	-- object_id
		p_object_type,	-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,	-- creation_ip
		p_context_id	-- context_id
	);

	insert into im_component_plugins (
		plugin_id, plugin_name, package_name, sort_order, 
		view_name, page_url, location, 
		component_tcl, title_tcl
	) values (
		v_plugin_id, p_plugin_name, p_package_name, p_sort_order, 
		p_view_name, p_page_url, p_location, 
		p_component_tcl, p_title_tcl
	);

	return v_plugin_id;
end;' language 'plpgsql';


create or replace function im_new_menu (varchar, varchar, varchar, varchar, integer, varchar, varchar) 
returns integer as '
declare
	p_package_name		alias for $1;
	p_label			alias for $2;
	p_name			alias for $3;
	p_url			alias for $4;
	p_sort_order		alias for $5;
	p_parent_menu_label	alias for $6;
	p_visible_tcl		alias for $7;

	v_menu_id		integer;
	v_parent_menu_id	integer;
begin
	-- Check for duplicates
	select	menu_id into v_menu_id
	from	im_menus m where m.label = p_label;
	IF v_menu_id is not null THEN return v_menu_id; END IF;

	-- Get parent menu
	select	menu_id into v_parent_menu_id
	from	im_menus m where m.label = p_parent_menu_label;

	v_menu_id := im_menu__new (
		null,					-- p_menu_id
		''im_menu'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		p_package_name,
		p_label,
		p_name,
		p_url,
		p_sort_order,
		v_parent_menu_id,
		p_visible_tcl
	);

	return v_menu_id;
end;' language 'plpgsql';

create or replace function im_new_menu_perms (varchar, varchar)
returns integer as '
declare
	p_label		alias for $1;
	p_group		alias for $2;
	v_menu_id		integer;
	v_group_id		integer;
begin
	select	menu_id into v_menu_id
	from	im_menus where label = p_label;

	select	group_id into v_group_id
	from	groups where lower(group_name) = lower(p_group);

	PERFORM acs_permission__grant_permission(v_menu_id, v_group_id, ''read'');
	return v_menu_id;
end;' language 'plpgsql';




CREATE OR REPLACE FUNCTION im_category_new (
	integer, varchar, varchar
) RETURNS integer as '
DECLARE
	p_category_id	alias for $1;
	p_category		alias for $2;
	p_category_type	alias for $3;
	v_count		integer;
BEGIN
	select	count(*) into v_count
	from	im_categories
	where	category = p_category and
		category_type = p_category_type;

	IF v_count > 0 THEN return 0; END IF;

	insert into im_categories(category_id, category, category_type)
	values (p_category_id, p_category, p_category_type);

	RETURN 0;
end;' language 'plpgsql';



CREATE OR REPLACE FUNCTION im_category_hierarchy_new (
	varchar, varchar, varchar
) RETURNS integer as '
DECLARE
	p_child			alias for $1;
	p_parent		alias for $2;
	p_cat_type		alias for $3;

	v_child_id		integer;
	v_parent_id		integer;
	v_count			integer;
BEGIN
	select	category_id into v_child_id from im_categories
	where	category = p_child and category_type = p_cat_type;
	IF v_child_id is null THEN RAISE NOTICE ''im_category_hierarchy_new: bad category 1: "%" '',p_child; END IF;

	select	category_id into v_parent_id from im_categories
	where	category = p_parent and category_type = p_cat_type;
	IF v_parent_id is null THEN RAISE NOTICE ''im_category_hierarchy_new: bad category 2: "%" '',p_parent; END IF;

	select	count(*) into v_count from im_category_hierarchy
	where	child_id = v_child_id and parent_id = v_parent_id;
	IF v_count > 0 THEN return 0; END IF;

	insert into im_category_hierarchy(child_id, parent_id)
	values (v_child_id, v_parent_id);

	RETURN 0;
end;' language 'plpgsql';




-- -------------------------------------------------------
-- Setup "components" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_components'',		-- label
		''Components'',			-- name
		''/intranet/admin/components/'', -- url
		90,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- -------------------------------------------------------
-- Setup "DynView" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_dynview'',		-- label
		''DynView'',			-- name
		''/intranet/admin/views/'',	-- url
		751,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "backup" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_backup'',		-- label
		''Backup'',			-- name
		''/intranet/admin/backup/'',	-- url
		11,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "Packages" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_packages'',		-- label
		''Packages'',			-- name
		''/acs-admin/apm/'',		-- url
		190,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "Workflow" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-workflow'',		-- package_name
		''admin_workflow'',		-- label
		''Workflow'',			-- name
		''/workflow/admin/'',		-- url
		1090,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "Flush Permission Cash" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_flush'',		-- label
		''Flush Cache'',		-- name
		''/intranet/admin/flush_cache'',	-- url
		11,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -------------------------------------------------------
-- Developer
-- -------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''main'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs'',			-- label
		''OpenACS'',			-- name
		''/acs-admin/'',		-- url
		1000,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -------------------------------------------------------
-- API-Doc

create or replace function inline_0 ()
returns integer as '
declare
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_api_doc'',		-- label
		''API Doc'',			-- name
		''/api-doc/'',			-- url
		10,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- API-Doc

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_developer'',		-- label
		''Developer Home'',		-- name
		''/acs-admin/developer'',	-- url
		20,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_l10n'',		-- label
		''Localization Home'',		-- name
		''/acs-lang/admin'',		-- url
		20,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_package_manager'',	-- label
		''Package Manager'',		-- name
		''/acs-admin/apm/'',		-- url
		30,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_sitemap'',		-- label
		''Sitemap'',			-- name
		''/admin/site-map/'',			-- url
		40,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_ds'',			-- label
		''SQL Profiling'',		-- name
		''/ds/'',			-- url
		50,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_shell'',		-- label
		''Interactive Shell'',		-- name
		''/ds/shell'',			-- url
		55,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_cache'',		-- label
		''Cache Status'',		-- name
		''/acs-admin/cache/'',		-- url
		60,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''openacs'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''openacs_auth'',		-- label
		''Authentication'',		-- name
		''/acs-admin/auth/'',			-- url
		80,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- -----------------------------------------------------
-- Auth Authorities
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';

	select menu_id into v_admin_menu
	from im_menus
	where label=''admin'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_auth_authorities'',	-- label
		''Auth Authorities'',		-- name
		''/acs-admin/auth/index'',	-- url
		120,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();

-- new ticket type for helpdesk
im_category_new(101, 'Ticket', 'Intranet Project Type');

