
-------------------------------------------------------------
-- Updates to upgrade to the "unified" V3.2 model where
-- Task is a subclass of Project.
-------------------------------------------------------------

-- Drop the generic uniquentess constraint on project_nr.
alter table im_projects drop constraint im_projects_nr_un;

-- Create a new constraing that makes sure that the project_nr
-- are unique per parent-project.
-- Project with parent_id != null don't have a filestorage...
--


-- alter table im_projects drop constraint im_projects_nr_un;

-- Dont allow the same project_nr  for the same company+level
alter table im_projects add
        constraint im_projects_nr_un
        unique(project_nr, company_id, parent_id);


-- Add a new category for the project_type.
-- Puff, difficult to find one while maintaining compatible
-- the the fixed IDs from ACS 3.4 Intranet...
--
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE) 
values ('84', 'Project Task', 'Intranet Project Type');


-------------------------------------------------------------
-- Add a "sort order" field to Projects
--
alter table im_projects add sort_order integer;


-------------------------------------------------------------
-- Add a "title_tcl" field to Components
--
alter table im_component_plugins add title_tcl varchar(4000);

-- Set the default value for title_tcl as the localization
-- of the package name
update im_component_plugins 
set title_tcl = 
	'lang::message::lookup "" "' || package_name || '.' || 
	plugin_name || '" "' || plugin_name || '"'
where title_tcl is null;


-- Manually set some components title_tcl




update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Offices "Offices"' 
where plugin_name = 'Company Offices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Project_Members "Project Members"' 
where plugin_name = 'Project Members';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Recent_Registrations "Recent Registrations"' 
where plugin_name = 'Recent Registrations';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Members "Members"' 
where plugin_name = 'Office Members';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Project_Wiki "Project_Wiki"' 
where plugin_name = 'Project Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Home_Page_Help "Home Page Help"' 
where plugin_name = 'Home Page Help Blurb';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.HomeWiki "Home Wiki"' 
where plugin_name = 'Home Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet2-tasks.Timesheet_Tasks "Timesheet Tasks"' 
where plugin_name = 'Project Timesheet Tasks';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet2-invoices.Price_List "Price List"' 
where plugin_name = 'Company Timesheet Prices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-hr.Employee_Information "Employee Information"' 
where plugin_name = 'User Employee Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-ganttproject.Scheduling "Scheduling"' 
where plugin_name = 'Project GanttProject Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Offices "Offices"' 
where plugin_name = 'User Offices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance_Summary "Finance Summary"' 
where plugin_name = 'Project Finance Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"'
where plugin_name = 'Home Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Users Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet.Timesheet "Timesheet"' 
where plugin_name = 'Project Timesheet Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Sales_Filestorage "Sales Filestorage"' 
where plugin_name = 'Project Sales Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Project Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost "Finance"' 
where plugin_name = 'Project Cost Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Projects "Projects"' 
where plugin_name = 'Home Page Project Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Random_Portrait "Random Portrait"' 
where plugin_name = 'Home Random Portrait';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Home Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.User_Wiki "User Wiki"' 
where plugin_name = 'User Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Office_Wiki "Office Wiki"' 
where plugin_name = 'Office Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet.Timesheet "Timesheet"' 
where plugin_name = 'Home Timesheet Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance_Summary "Finance Summary"' 
where plugin_name = 'Project Finance Summary Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-security-update-client.Security_Updates "Security Updates"' 
where plugin_name = 'Security Update Client Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Project Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Companies Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance "Finance"' 
where plugin_name = 'Company Cost Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Companies Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Company_Wiki "Company Wiki"' 
where plugin_name = 'Company Wiki Component';






-------------------------------------------------------------
-- Update the .new for plugins
drop function im_component_plugin__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, varchar, varchar, varchar, integer,
        varchar);


create or replace function im_component_plugin__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, varchar, varchar, varchar, integer,
        varchar, varchar
) returns integer as '
declare
        p_plugin_id     alias for $1;   -- default null
        p_object_type   alias for $2;   -- default ''acs_object''
        p_creation_date alias for $3;   -- default now()
        p_creation_user alias for $4;   -- default null
        p_creation_ip   alias for $5;   -- default null
        p_context_id    alias for $6;   -- default null

        p_plugin_name   alias for $7;
        p_package_name  alias for $8;
        p_location      alias for $9;
        p_page_url      alias for $10;
        p_view_name     alias for $11;  -- default null
        p_sort_order    alias for $12;
        p_component_tcl alias for $13;
        p_title_tcl     alias for $14;

        v_plugin_id     im_component_plugins.plugin_id%TYPE;
begin
        v_plugin_id := acs_object__new (
                p_plugin_id,    -- object_id
                p_object_type,  -- object_type
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip,  -- creation_ip
                p_context_id    -- context_id
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


