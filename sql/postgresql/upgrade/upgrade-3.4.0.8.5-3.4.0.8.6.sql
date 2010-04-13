-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');


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

