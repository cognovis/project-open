-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');


-- Make sure we got the new version with duplicate detection
create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar
) returns integer as '
DECLARE
	p_widget_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_widget_name		alias for $7;
	p_pretty_name		alias for $8;
	p_pretty_plural		alias for $9;
	p_storage_type_id	alias for $10;
	p_acs_datatype		alias for $11;
	p_widget		alias for $12;
	p_sql_datatype		alias for $13;
	p_parameters		alias for $14;

	v_widget_id		integer;
BEGIN
	select widget_id into v_widget_id from im_dynfield_widgets
	where widget_name = p_widget_name;
	if v_widget_id is not null then return v_widget_id; end if;

	v_widget_id := acs_object__new (
		p_widget_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_widgets (
		widget_id, widget_name, pretty_name, pretty_plural,
		storage_type_id, acs_datatype, widget, sql_datatype, parameters
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters
	);
	return v_widget_id;
end;' language 'plpgsql';






SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'program_projects', 'Program Projects', 'Program Projects',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
select p.project_id, p.project_name
from im_projects p
where project_type_id = 2510
order by lower(project_name)
	}}}'
);



SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'program_projects', 'integer', 'f');


SELECT im_menu__new (
	null,								-- p_menu_id
	'im_menu',							-- object_type
	now(),								-- creation_date
	null,								-- creation_user
	null,								-- creation_ip
	null,								-- context_id
	'intranet-dynfield',						-- package_name
	'dynfield_otype_material',					-- label
	'Material',							-- name
	'/intranet-dynfield/object-type?object_type=im_material',	-- url
	143,								-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null								-- p_visible_tcl
);



-- "Numeric" widget

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'numeric', 'Numeric', 'Numeric',
	10007, 'float', 'text', 'float',''
);




-- Fix the widget and datatype for presales variables
update acs_attributes set 
	datatype = 'float' 
where 
	attribute_id in (
		select attribute_id
		from acs_attributes
		where attribute_name in ('presales_value','presales_probability')
	);

update im_dynfield_attributes 
	set widget_name = 'numeric' 
where
	acs_attribute_id in (
		select attribute_id 
		from acs_attributes
		where attribute_name in ('presales_value','presales_probability')
	);

