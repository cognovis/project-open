-- /packages/intranet-timesheet/sql/oracle/intranet-timesheet-create.sql
--
-- Copyright (C) 1999-2004 various parties
-- The code is based on ArsDigita ACS 3.4
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author      unknown@arsdigita.com
-- @author      frank.bergmann@project-open.com
-- @author	mai-bee@gmx.net

------------------------------------------------------------
-- Riskmanagement
--
-- We record project risks and represent them graphically.
--

create table im_risks (
        risk_id		        integer
                                constraint im_risks_pk
                                primary key,
                                -- constraint im_risks_risk_id_fk
                                -- references acs_objects,
	project_id              integer not null
                                constraint im_risks_project_id_fk
                                references im_projects,
	owner_id	        integer not null
				constraint im_risks_owner_id_fk
				references users,
        probability             number(5,2),
        impact	                number(7,0),
        title                   varchar(1000),
        description             text,
	type                    integer
				references im_categories
				constraint im_risks_risk_type_const not null
);

create index im_risks_project_id_idx on im_risks(project_id);
create index im_risks_title_idx on im_risks(title);

begin
    -- add_risks should only be allowed to project managers
    acs_privilege.create_privilege('add_risks','Add Risks','Add Risks');
    acs_privilege.add_child('admin', 'add_risks');
end;
/

begin
    -- view_risks depends on the company
    acs_privilege.create_privilege('view_risks','View Risks','View Risks');
    acs_privilege.add_child('admin', 'view_risks');
end;
/



------------------------------------------------------
-- Add Risks
---
BEGIN
    im_priv_create('add_risks',        'Accounting');
END;
/
BEGIN
    im_priv_create('add_risks',        'Employees');
END;
/
BEGIN
    im_priv_create('add_risks',        'P/O Admins');
END;
/
BEGIN
    im_priv_create('add_risks',        'Project Managers');
END;
/
BEGIN
    im_priv_create('add_risks',        'Sales');
END;
/
BEGIN
    im_priv_create('add_risks',        'Senior Managers');
END;
/


------------------------------------------------------
-- View Risks
---
BEGIN
    im_priv_create('view_risks',        'Accounting');
END;
/
BEGIN
    im_priv_create('view_risks',        'Employees');
END;
/
BEGIN
    im_priv_create('view_risks',        'P/O Admins');
END;
/
BEGIN
    im_priv_create('view_risks',        'Project Managers');
END;
/
BEGIN
    im_priv_create('view_risks',        'Sales');
END;
/
BEGIN
    im_priv_create('view_risks',        'Senior Managers');
END;
/


--------------
-- View in Project
--------------

create or replace view im_risk_types as
select category_id as risk_type_id, category as risk_type
from im_categories
where category_type = 'Intranet Risk Type';

-- 5100 - 5199 Absence types
delete from im_categories where category_id >= 5100 and category_id <= 5199;

insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values ('', 'f', '5100', 'Internal', 'Intranet Risk Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values ('', 'f', '5101', 'External', 'Intranet Risk Type');

-- views to "risk" items: 210-219
delete from im_view_columns where column_id >= 20100 and column_id < 20200;
delete from im_views where view_id >= 210 and view_id < 220;

insert into im_views (view_id, view_name, visible_for) values (210, 'risk_list_home', 'view_risks');

-- view_columns to "risks" items: 20100 - 20199
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20101,210,NULL,'Title',
'"<a href=\"/intranet-riskmanagement/view?risk_id=$risk_id\">$risk_title</a>"','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20102,210,NULL,'Type',
'"$risk_type_name"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20103,210,NULL,'Probability',
'"$risk_probability"','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20104,210,NULL,'Impact',
'"$risk_impact"','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20105,210,NULL,'Delete?',
'"<a href=\"/intranet-riskmanagement/delete?[export_url_vars risk_id project_id]\">Del</a>"','','',6,'');

commit;

---------------------------------------------------------
-- Register the component in the core TCL pages
--

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-riskmanagement');
END;
/
show errors

commit;

-- Show the forum component in project page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'Project Risk Component',
        package_name => 'intranet-riskmanagement',
        page_url =>     '/intranet/projects/view',
        location =>     'left',
        sort_order =>   30,
        component_tcl =>'im_risk_project_component $user_id $project_id'
    );
end;
/
show errors

commit;