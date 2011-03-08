update im_categories set category = '1 - Lowest Priority' where category_id = 70000;
update im_categories set category = '2 - Very Low Priority' where category_id = 70002;
update im_categories set category = '3 - Low Priority' where category_id = 70004;
update im_categories set category = '4 - Medium Low Priority' where category_id = 70006;
update im_categories set category = '5 - Average Priority' where category_id = 70008;
update im_categories set category = '6 - Medium High Priority' where category_id = 70010;
update im_categories set category = '7 - High Priority' where category_id = 70012;
update im_categories set category = '8 - Very High Priority' where category_id = 70014;
update im_categories set category = '9 - Highest Priority' where category_id = 70016;

alter table im_projects drop constraint im_projects_project_priority_fk;

-- Add a "Strategic Priority" field to projects
--
alter table im_projects
add project_priority_st_id integer
constraint im_projects_project_priority_st_fk references im_categories;

SELECT im_dynfield_attribute_new ('im_project', 'project_priority_st_id', 'Strategic Priority', 'project_priority', 'integer', 'f');



---- st_id

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'write'
);


SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'write'
);

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92021,921,NULL,'Strategic Priority',
'"[im_category_from_id $project_priority_st_id]"','','',10,'','	dropdown project_priority_st_id { [im_category_get_key_value_list "Intranet Department Planner Project Priority"] } 1 1
');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92006,920,NULL,'Operational Priority',
'"[im_category_select -include_empty_p 1 {Intranet Department Planner Project Priority} project_priority_op_id.$project_id $project_priority_op_id]"','','',6,'','');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92007,920,NULL,'Strategic Priority',
'"[im_category_select -include_empty_p 1 {Intranet Department Planner Project Priority} project_priority_st_id.$project_id $project_priority_st_id]"','','',7,'','');

alter table im_projects drop column project_priority_id;

alter table im_projects add project_priority integer;
SELECT im_dynfield_attribute_new ('im_project', 'project_priority', 'Project Priority', 'integer', 'integer', 'f');

select im_dynfield_attribute__del((select attribute_id from im_dynfield_attributes where acs_attribute_id = (select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')));

