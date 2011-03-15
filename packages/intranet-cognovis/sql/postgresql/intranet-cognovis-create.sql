-- intranet-cognovis-create.sql                                                                                                                           

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/intranet-cognovis-create.sql','');



-- Project Base Data Component                                                                                                                              
SELECT im_component_plugin__new (
       null, 
       'acs_object', 
       now(), 
       null, 
       null, 
       null, 
       'Project Base Data Cognovis', 
       'intranet-cognovis', 
       'left', 
       '/intranet/projects/view', 
       null, 
       10, 
       'im_project_base_data_cognovis_component -project_id $project_id -return_url $return_url'
);


-- Project Hierarchy Component.
-- Update sort order
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE
	v_component_id integer;
BEGIN
	SELECT plugin_id INTO v_component_id 
	FROM im_component_plugins 
	WHERE plugin_name = ''Project Hierarchy''
	AND package_name = ''intranet-core''
	AND page_url = ''/intranet/projects/view'';

	UPDATE im_component_plugins 
	SET location = ''right'', menu_sort_order = 0
	WHERE plugin_id = v_component_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


-- Dynfield Widgets and Attributes. 
-- object_type:im_project

-- create project_nr widget
SELECT im_dynfield_widget__new(
       null,				-- widget_id
       'im_dynfield_widget',		-- object_type
       now(),				-- creation_date
       null,				-- creation_user
       null,				-- creation_ip
       null,				-- context_id
       'project_nr',			-- widget_name
       '#intranet-core.Project_Nr#',	-- pretty_name
       '#intranet-core.Project_Nr#',	-- pretty_plural
       10007,				-- storage_type_id
       'string',			-- acs_datatype
       'text',				-- widget
       'text',				-- sql_datatype 
       '{html {size 15 maxlength 20}}', -- parameter
       'im_name_from_id'		-- deref_plpgsql_function
);


-- create dynfield attributes
-- project_name 
SELECT im_dynfield_attribute_new (
       'im_project',			-- object_type
       'project_name',			-- column_name
       '#intranet-core.Project_Name#',	-- pretty_name
       'textbox_medium',		-- widget_name
       'string',			-- acs_datatype
       't',				-- required_p
       1,				-- pos y
       'f',				-- also_hard_coded
       'im_projects'  			-- table_name
      );


SELECT im_dynfield_attribute_new (
       'im_project',			-- object_type
       'project_nr',			-- column_name
       '#intranet-core.Project_Nr#',	-- pretty_name
       'textbox_medium',		-- widget_name
       'string',			-- acs_datatype
       't',				-- required_p
       2,				-- pos y
       'f',				-- also_hard_coded
       'im_projects'  			-- table_name
);

SELECT im_dynfield_attribute_new (
       'im_project',			-- object_type
       'parent_id',		 	-- column_name
       '#intranet-core.Parent_Project#',-- pretty_name
       'project_parent_options',	-- widget_name
       'integer',			-- acs_datatype
       'f',				-- required_p   
       3,				-- pos y
       'f',				-- also_hard_coded
       'im_projects'			-- table_name
);


SELECT im_dynfield_attribute_new (
       'im_project',
       'project_path',
       '#intranet-core.Project_Path#',
       'textbox_medium',
       'string',
       't',
       4,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'company_id',
       '#intranet-core.Company#',
       'customers',
       'integer',
       't',
       5,
       'f',
       'im_projects'
      );


SELECT im_dynfield_attribute_new (
       'im_project',
       'project_lead_id',
       '#intranet-core.Project_Manager#',
       'project_leads',
       'integer',
       't',
       6,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'project_type_id',
       '#intranet-core.Project_Type#',
       'project_type',
       'integer',
       't',
       7,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'project_status_id',
       '#intranet-core.Project_Status#',
       'project_status',
       'integer',
       't',
       8,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'start_date',
       '#intranet-core.Start_Date#',
       'date',
       'timestamp',
       't',
       9,
       'f',
       'im_projects'
);


-- Add javascript calendar buton on date widget
UPDATE im_dynfield_widgets set parameters = '{format "YYYY-MM-DD"} {after_html {<input type="button" style="height:23px; width:23px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" ></b>}}' where widget_name = 'date';

SELECT im_dynfield_attribute_new (
       'im_project',
       'end_date',
       '#intranet-core.End_Date#',
       'date',
       'date',
       't',
       10,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'on_track_status_id',
       '#intranet-core.On_Track_Status#',
       'on_track_status',
       'integer',
       'f',
       11,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'percent_completed',
       '#intranet-core.Percent_Completed#',
       'numeric',
       'float',
       'f',
       12,
       'f',
       'im_projects'
);
   
SELECT im_dynfield_attribute_new (
       'im_project',
       'project_budget_hours',
       '#intranet-core.Project_Budget_Hours#',
       'numeric',
       'float',
       'f',
       13,
       'f',
       'im_projects'
);
       
SELECT im_dynfield_attribute_new (
       'im_project',
       'project_budget',
       '#intranet-core.Project_Budget#',
       'numeric',
       'float',
       'f',
       14,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'project_budget_currency',
       '#intranet-core.Project_Budget_Currency#',
       'currencies',
       'string',
       'f',
       15,
       'f',
       'im_projects'
);

SELECT im_dynfield_attribute_new (
       'im_project',
       'company_project_nr',
       '#intranet-core.Company_Project_Nr#',
       'textbox_small',
       'string',
       'f',
       16,
       'f',
       'im_projects'
);

       
SELECT im_dynfield_attribute_new (
       'im_project',
       'description',
       '#intranet-core.Description#',
       'richtext',
       'text',
       'f',
       17,
       'f',
       'im_projects'
);








-- Deactivate Original Component: Project Base Data and Project Hierarchy
-- it needs to add a flush memory in the end of this function

create or replace function inline_0 () 
returns integer as '
DECLARE 
	v_plugin_id integer;

BEGIN
	SELECT plugin_id into v_plugin_id
	FROM im_component_plugins
	WHERE plugin_name = ''Project Base Data'' 
	AND package_name = ''intranet-core'' 
	AND page_url = ''/intranet/projects/view'';

	UPDATE im_component_plugins 
	SET enabled_p = ''f'' 
	WHERE plugin_id = v_plugin_id;

	DELETE FROM im_component_plugin_user_map 
	WHERE plugin_id = v_plugin_id;


	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();	


-- Timesheet Task Components

-- Home Task Component
SELECT im_component_plugin__new (
       null,				-- plugin_id
       'acs_object', 			-- object_type
       now(), 				-- creation_date
       null, 				-- creation_user
       null, 				-- creation_ip
       null, 				-- context_id
       'Home Task Component',	   	-- plugin_name
       'intranet-cognovis',		-- package_name
       'right',				-- location
       '/intranet/index', 		-- page_url
       null,				-- view_name
       16,				-- sort_order
       'im_timesheet_task_home_component -page_size 20 -restrict_to_status_id 76 -return_url $return_url' --component_tcl
);

-- Right Side Components

-- Timesheet Task Members Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Task Members Cognovis',
       'intranet-core', 
       'right',
       '/intranet-cognovis/tasks/view',
       null,
       20,
       'im_group_member_component $task_id $current_user_id $project_write $return_url "" "" 1');


-- Project Timesheet Tasks Information
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Timesheet Task Project Information Cognovis',
       'intranet-timesheet2-tasks',
       'right',
       '/intranet-cognovis/tasks/view',
       null,
       '50',
       'im_timesheet_task_info_component $project_id $task_id $return_url');


-- Timesheet Task Resources
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Task Resources Cognovis',
       'intranet-timesheet2-tasks',
       'right',
       '/intranet-cognovis/tasks/view',
       null, 
       '50', 'im_timesheet_task_members_component $project_id $task_id $return_url');


-- Timesheet Tasks Forum Component
SELECT im_component_plugin__new (
        null,                           -- plugin_id
	'acs_object',                   -- object_type
        now(),                          -- creation_date
	null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Timesheet Task Forum',		-- plugin_name
        'intranet-forum',               -- package_name
        'right',                        -- location
        '/intranet-cognovis/tasks/view', -- page_url
        null,                           -- view_name
        10,                             -- sort_order
	'im_forum_component -user_id $user_id -forum_object_id $task_id -current_page_url $return_url -return_url $return_url -forum_type "task" -export_var_list [list task_id forum_start_idx forum_order_by forum_how_many forum_view_name] -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p "f" -restrict_to_new_topics 0',
	'im_forum_create_bar "<B><nobr>[_ intranet-forum.Forum_Items]</nobr></B>" $task_id $return_url');

-- Left Side Components

-- Timesheet Task Info Component 
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Timesheet Task Info Component',
       'intranet-timesheet2-tasks',
       'left', 
       '/intranet-cognovis/tasks/view', 
       null,
       1,
       'im_timesheet_task_info_cognovis_component $task_id $return_url');


-- Timesheet Tasks Dynfield Attributes
-- add timesheet2-tasks dynfield attributes


-- project_name
CREATE OR REPLACE FUNCTION inline_1 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
BEGIN
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''project_name'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Task'', min_n_values = 1, sort_order = 1 WHERE attribute_id = v_attribute_id;
	 
	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;
	 
	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
	''im_timesheet_task'',
	''project_name'',
	''Task'',
	''textbox_medium'',
	''string'',
	''t'',
	1,
	''f'',
	''im_projects''
	);
  

      RETURN 1;
END;' language 'plpgsql';

SELECT inline_1 ();
DROP FUNCTION inline_1 ();


--project_nr
CREATE OR REPLACE FUNCTION inline_2 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''project_nr'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Task Nr.'', min_n_values = 1, sort_order = 2 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''project_nr'',
       ''Task Nr.'', 
       ''textbox_medium'',
       ''string'',
       ''t'',
       2,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';

SELECT inline_2 ();
DROP FUNCTION inline_2 ();


-- parent_id
CREATE OR REPLACE FUNCTION inline_3 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''parent_id'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Project'', min_n_values = 0, sort_order = 3 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''parent_id'',
       ''Project ID'',
       ''open_projects'',
       ''integer'',
       ''t'',
       3,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_3 ();
DROP FUNCTION inline_3 ();


--task_status
CREATE OR REPLACE FUNCTION inline_4 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      PERFORM im_dynfield_widget__new (
       null,
       ''im_dynfield_widget'', 
       now(), 
       null,
       null, 
       null, 
       ''task_status'',
       ''Task Status'',
       ''Task Status'',
       10007,
       ''integer'',
       ''generic_tcl'',
       ''integer'',
       ''{custom {tcl {im_timesheet_task_status_options -include_empty 1}}}'',
       ''im_name_from_id''
       );


      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''project_status_id'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Task Status'', pretty_plural = ''Task Status'', min_n_values = 1, sort_order = 4 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET widget_name = ''task_status'', also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

       PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''project_status_id'',
       ''Status'',
       ''task_status'',
       ''integer'',
       ''t'',
       4,
       ''f'',
       ''im_projects''
       );


      RETURN 1;
END;' language 'plpgsql';


SELECT inline_4 ();
DROP FUNCTION inline_4 ();

-- task_type_id
CREATE OR REPLACE FUNCTION inline_5 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
		
BEGIN 
      PERFORM im_dynfield_widget__new (
       null,
      ''im_dynfield_widget'', 
       now(),
       null,
       null,
       null,
       ''task_type'',
       ''Task Type'',
       ''Task Types'',
       10007,
       ''integer'',
       ''generic_tcl'',
       ''integer'',
       ''{custom {tcl {im_timesheet_task_type_options -include_empty 1}}}'',
       ''im_name_from_id''
       );

      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''project_type_id'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Task Type'', pretty_plural = ''Task Type'', min_n_values = 1, sort_order = 5 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET widget_name = ''task_type'', also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

       PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''project_type_id'',
       ''Type'',
       ''task_type'',
       ''integer'',
       ''f'',
       5,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_5 ();
DROP FUNCTION inline_5 ();


-- uom_id
CREATE OR REPLACE FUNCTION inline_6 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''uom_id'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 6 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
	''im_timesheet_task'',
	''uom_id'',
	''Unit of Measures'',
	''units_of_measure'',
	''integer'',
	''f'',
	6,
	''f'',
	''im_timesheet_tasks''
	);

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_6 ();
DROP FUNCTION inline_6 ();


-- cost_center
CREATE OR REPLACE FUNCTION inline_7 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''cost_center_id'';

      IF v_attribute_id > 0 THEN

     	 UPDATE acs_attributes SET min_n_values = 1, sort_order = 7 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''cost_center_id'',
       ''Cost Center'',
       ''cost_centers'',
       ''integer'',
       ''t'',
       7,
       ''f'',
       ''im_timesheet_tasks''       
       );
      
      RETURN 1;
END;' language 'plpgsql';


SELECT inline_7 ();
DROP FUNCTION inline_7 ();



-- material_id
CREATE OR REPLACE FUNCTION inline_8 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''material_id'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 8 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''material_id'',
       ''Material'',
       ''select_material_id'',
       ''integer'',
       ''f'',
       8,
       ''f'',
       ''im_timesheet_tasks''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_8 ();
DROP FUNCTION inline_8 ();


-- planned_units
CREATE OR REPLACE FUNCTION inline_9 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''planned_units'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 9 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''planned_units'',
       ''Planned Units'',
       ''numeric'',
       ''float'',
       ''f'',
       9,
       ''f'',
       ''im_timesheet_tasks''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_9 ();
DROP FUNCTION inline_9 ();

-- billable_units
CREATE OR REPLACE FUNCTION inline_10 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''billable_units'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 10 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''billable_units'',
       ''Billable Units'',
       ''numeric'',
       ''float'',
       ''f'',
       10,
       ''f'',
       ''im_timesheet_tasks''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_10 ();
DROP FUNCTION inline_10 ();


-- percent_completed
CREATE OR REPLACE FUNCTION inline_11 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''percent_completed'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 11 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''percent_completed'',
       ''Percent Completed'',
       ''numeric'',
       ''float'',
       ''f'',
       11,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_11 ();
DROP FUNCTION inline_11 ();


-- start_date
CREATE OR REPLACE FUNCTION inline_12 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''start_date'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 12 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''start_date'',
       ''Start Date'',
       ''date'',
       ''timestamp'',
       ''f'',
       12,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_12 ();
DROP FUNCTION inline_12 ();




-- end_date
CREATE OR REPLACE FUNCTION inline_13 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''end_date'';

      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 13 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''end_date'',
       ''End Date'',
       ''date'',
       ''timestamp'',
       ''f'',
       13,
       ''f'',
       ''im_projects''
       );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_13 ();
DROP FUNCTION inline_13 ();


-- description
CREATE OR REPLACE FUNCTION inline_15 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	
BEGIN 
      SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_timesheet_task'' AND attribute_name = ''description'';

      IF v_attribute_id > 0 THEN

      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 15 WHERE attribute_id = v_attribute_id;

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE acs_attribute_id = v_attribute_id;

	 RETURN 0;
      END IF;

      PERFORM im_dynfield_attribute_new (
       ''im_timesheet_task'',
       ''description'',
       ''Task Description'',
       ''richtext'',
       ''text'',
       ''f'',
       15,
       ''f'',
       ''im_projects''
      );

      RETURN 1;
END;' language 'plpgsql';


SELECT inline_15 ();
DROP FUNCTION inline_15 ();


-- User Components

-- User Basic Info Component                                                                                                                                
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Basic Information',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_user_basic_info_component $user_id $return_url');

-- User Contact Infor Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Contact Information',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_user_contact_info_component $user_id $return_url');

-- User Skin Component                                                                                                                                     
-- SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Skin Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_skin_info_component $user_id $return_url');                                                                                                 

SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Skin Information',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_skin_select_html $user_id $return_url');

-- User Administration Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Admin Information',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_user_admin_info_component $user_id $return_url');

-- User Localization Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Locale',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_user_localization_component $user_id $return_url');

-- User Portrait Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Portrait',
       'intranet-core',
       'right',
       '/intranet/users/view',
       null,
       0,
       'im_portrait_component $user_id_from_search $return_url $read $write $admin');


-- Company Components
-- Company Info
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Company Information',
       'intranet-core',
       'left',
       '/intranet/companies/view',
       null,
       0,
       'im_company_info_component $company_id $return_url');

-- Company Projects
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Company Projects',
       'intranet-core',
       'right',
       '/intranet/companies/view',
       null,
       0,
       'im_company_projects_component $company_id $return_url');


-- Company Members
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Company Employees',
       'intranet-core',
       'right',
       '/intranet/companies/view',
       null,
       0,
       'im_company_employees_component $company_id $return_url');

-- Company Contacts
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Company Contacts',
       'intranet-core',
       'right',
       '/intranet/companies/view',
       null,
       0,
       'im_company_contacts_component $company_id $return_url');

-- update project_parent_options widget
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_widget_id integer;

BEGIN                                                                                                                                                       

        SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''project_parent_options'';

        UPDATE im_dynfield_widgets 
	SET parameters = ''{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -exclude_tasks_p 1 -project_id $super_project_id} switch_p 1 global_var super_project_id}}'' 
	WHERE widget_id = v_widget_id;

	RETURN 0;                                                                                                                                           
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- update open_projects widget
create or replace FUNCTION inline_0 ()
returns integer as '
DECLARE
	v_widget_id integer;

BEGIN
	SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''open_projects'';
	
	UPDATE im_dynfield_widgets 
	SET parameters = ''{custom {tcl {im_project_options -include_empty 1 -project_status_id [im_project_status_open] -exclude_tasks_p 1} switch_p 1}}'', widget = ''generic_tcl'' WHERE widget_id = v_widget_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();






CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id		integer;
BEGIN
	-- source_language_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''source_language_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);
	
	-- bt_fix_for_version_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_fix_for_version_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- bt_found_in_version_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_found_in_version_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- bt_project_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_project_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- confirm_date
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''confirm_date'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- milestone_p
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''milestone_p'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);
	
	-- presales_probability
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''presales_probability'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- presales_value
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''presales_value'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- program_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''program_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- release_item_p
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''release_item_p'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);


	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();
