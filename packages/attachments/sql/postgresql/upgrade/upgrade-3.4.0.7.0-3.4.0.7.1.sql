-- upgrade-3.4.0.7.0-3.4.0.7.1.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.4.0.7.0-3.4.0.7.1.sql','');



update im_component_plugins set 
	plugin_name = 'Freelance List Component' 
where
	plugin_name = 'freelance list Component'
;


create or replace function im_report_new (
	varchar, varchar, varchar, integer, integer, varchar
) returns integer as '
DECLARE
	p_report_name		alias for $1;
	p_report_code		alias for $2;
	p_package_name		alias for $3;
	p_report_sort_order	alias for $4;
	p_parent_menu_id	alias for $5;
	p_report_sql		alias for $6;

	v_menu_id		integer;
	v_report_id		integer;
	v_report_url		varchar;
	v_count			integer;
BEGIN
	select count(*) into v_count from im_reports
	where report_name = p_report_name;
	if v_count > 0 then 
		return (select report_id from im_reports where report_name = p_report_name); 
	end if;

	-- default URL. Later we need to update it.
	v_report_url := '''';

	v_menu_id := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now()::timestamptz,	-- creation_date
		null,			-- creation_user
		''0.0.0.0'',		-- creation_ip
		null,			-- context_id

		p_package_name,		-- package_name
		p_report_code,		-- label
		p_report_name,		-- name
		v_report_url,		-- url
		p_report_sort_order,	-- sort_order
		p_parent_menu_id,	-- parent_menu_id
		null			-- p_visible_tcl
	);

	v_report_id := im_report__new (
		null,			-- report_id
		''im_report'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		''0.0.0.0'',		-- creation_ip
		null,			-- context_id
	
		p_report_name,		-- report_name
		p_report_code,		-- report_code		
		15100,			-- p_report_type_id	
		15000,			-- report_status_id	
		v_menu_id,		-- report_menu_id	
		p_report_sql		-- report_sql
	);

	-- Update the final URL
	update im_menus set
		url = ''/intranet-reporting/view?report_id='' || v_report_id
	where menu_id = v_menu_id;

	return v_report_id;
END;' language 'plpgsql';

-- Create freelance report
SELECT im_report_new (
	'Freelance Skills',		-- report_name
	'reporting-freelance-skills',	-- report_code
	'intranet-freelance',		-- package_key
	100,				-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-other'),	-- parent_menu_id
	'
	select	''<a href=/intranet/users/view?user_id='' || user_id || ''>'' ||
		im_name_from_user_id(s.user_id) || ''</a>'' as user_name,
		im_category_from_id(s.skill_type_id) as skill_type,
		im_category_from_id(s.skill_id) as skill,
		im_category_from_id(s.confirmed_experience_id) as level
	from	im_freelance_skills s,
		persons p
	where	p.person_id = s.user_id
	order by
		last_name, first_names, skill_type, skill
	'
);

