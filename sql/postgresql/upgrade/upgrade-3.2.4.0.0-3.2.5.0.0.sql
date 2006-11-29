-- upgrade-3.2.4.0.0-3.2.5.0.0.sql

-- Add a "Username" field to the users view page


delete from im_view_columns where column_id=1107;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1107,11,NULL,'Username',
'$username','','',4,
'parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersUsernameP -default 0');


-- Make all Categories "enabled", after introducing an enabled_p
-- sensitive CategoryWidget
update im_categories set enabled_p = 't';


-- Weaken the project_path_un constraint so that it isnt global
-- anymore, just local (wrt to parent_id)

alter table im_projects
drop constraint im_projects_path_un;

alter table im_projects
add constraint im_projects_path_un UNIQUE (project_nr, company_id, parent_id);


