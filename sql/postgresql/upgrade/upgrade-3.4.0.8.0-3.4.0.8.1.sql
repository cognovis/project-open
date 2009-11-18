-- upgrade-3.4.0.8.0-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.8.0-3.4.0.8.1.sql','');

-- Disable "Active or Potential" company status
update im_categories set enabled_p = 'f' where category_id = 40;





-----------------------------------------------------------
-- Store information about the open/closed status of 
-- hierarchical business objects including projects etc.
--

-- Store the o=open/c=closed status for business objects
-- at certain page URLs.
--
CREATE TABLE im_biz_object_hierarchy_status (
		object_id	integer
				constraint im_biz_object_hierarchy_status_object_nn 
				not null
				constraint im_biz_object_hierarchy_status_object_fk
				references acs_objects on delete cascade,
		user_id		integer
				constraint im_biz_object_hierarchy_status_user_nn 
				not null
				constraint im_biz_object_hierarchy_status_user_fk
				references persons on delete cascade,
		page_url	text
				constraint im_biz_object_hierarchy_status_page_nn 
				not null,

		open_p		char(1)
				constraint im_biz_object_hierarchy_status_open_ck
				CHECK (open_p = 'o'::bpchar OR open_p = 'c'::bpchar),
		last_modified	timestamptz,

	primary key  (object_id, user_id, page_url)
);


-----------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_projects'' and lower(column_name) = ''presales_probability'';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects add presales_probability numeric(5,2);
	alter table im_projects add presales_value numeric(12,2);

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_dynfield_attribute_new ('im_project', 'presales_probability', 'Presales Probability', 'integer', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_project', 'presales_value', 'Presales Value', 'integer', 'integer', 'f');



-- reported_days_cache for controlling per day.
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_projects'' and lower(column_name) = ''reportd_days_cache'';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects add reported_days_cache numeric(12,2) default 0;

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- -------------------------------------------------------
-- Setup "templates" menu 
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
		''admin_templates'',		-- label
		''Templates'',			-- name
		''/intranet/admin/templates/'',	-- url
		2601,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	update im_menus set menu_gif_small = ''arrow_right''
	where menu_id = v_admin_menu;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



