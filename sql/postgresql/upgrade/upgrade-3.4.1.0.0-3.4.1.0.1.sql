-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');



delete from im_view_columns where column_id = 91101;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91101, 911, NULL, '"Task Name"',
'"<nobr>$indent_short_html$gif_html<a href=$object_url>$task_name</a></nobr>"','','',1,'');


delete from im_view_columns where column_id = 91002;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91002,910,NULL,'"Task Name"',
'"<nobr>$indent_html$gif_html<a href=$object_url>$task_name</a></nobr>"','','',2,'');





-----------------------------------------------------------
-- Dynfield Widgets
--
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'project_status', 'Project Status', 'Projop Status',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Project Status"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'project_type', 'Project Type', 'Projop Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Project Type"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'units_of_measure', 'Units of Measure', 'Units of Measure',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet UoM"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'materials', 'Materials', 'Materials',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	m.material_id,
			m.material_name
		from	im_materials m
		where	m.material_status_id not in (select * from im_sub_categories(9102))
		order by 
			lower(material_name) 
	}}}'
);


CREATE or REPLACE FUNCTION im_project_level_spaces(integer)
RETURNS varchar as $body$
DECLARE
	p_level		alias for $1;
	v_result	varchar;
	i		integer;
BEGIN
	v_result := '';
	FOR i IN 1..p_level LOOP
		v_result := v_result || '    ';
	END LOOP;
	RETURN v_result;
END; $body$ LANGUAGE 'plpgsql';


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'open_projects', 'Open Projects', 'Open Projects',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	p.project_id,
			im_project_level_spaces(tree_level(p.tree_sortkey)) || p.project_name
		from	im_projects p
		where	p.project_status_id in (select * from im_sub_categories(76)) and
			p.project_type_id not in (select * from im_sub_categories(100)) and
			p.project_type_id not in (select * from im_sub_categories(101)) and
			p.project_type_id not in (select * from im_sub_categories(2510)) and
			p.project_type_id not in (select * from im_sub_categories(2502))
		order by 
			tree_sortkey
	}}}'
);



-----------------------------------------------------------
-- Hard coded fields
--
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'project_name', 'Name', 
'textbox_medium', 'string', 'f', 0, 't', 'im_projects');
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'project_nr', 'Nr', 
'textbox_medium', 'string', 'f', 10, 't', 'im_projects');

SELECT im_dynfield_attribute_new ('im_timesheet_task', 'parent_id', 'Super Project', 
'open_projects', 'integer', 'f', 20, 't', 'im_projects');

SELECT im_dynfield_attribute_new ('im_timesheet_task', 'project_status_id', 'Status', 
'project_status', 'integer', 'f', 30, 't', 'im_projects');
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'project_type_id', 'Type', 
'project_type', 'integer', 'f', 40, 't', 'im_projects');
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'uom_id', 'Unit of Measure', 
'units_of_measure', 'integer', 'f', 50, 't', 'im_timesheet_tasks');
SELECT im_dynfield_attribute_new ('im_timesheet_task', 'material_id', 'Material', 
'materials', 'integer', 'f', 60, 't', 'im_timesheet_tasks');

