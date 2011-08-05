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


-- Fix the acs_attributes missing table_name for im_project object_type
create or replace function inline_0() 
returns integer as '
BEGIN
       update acs_attributes set table_name = ''im_projects'' 
       where object_type = ''im_project'' and table_name is null;

       return 0;
END;' language 'plpgsql';

SELECT inline_0();

DROP FUNCTION inline_0();


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


create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar, varchar
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
	p_deref_plpgsql_function alias for $15;

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
		storage_type_id, acs_datatype, widget, sql_datatype, parameters, deref_plpgsql_function
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters, p_deref_plpgsql_function
	);
	return v_widget_id;
end;' language 'plpgsql';

create or replace function im_dynfield_widget__del (integer) returns integer as '
DECLARE
	p_widget_id		alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__delete(p_widget_id);
	return 0;
end;' language 'plpgsql';

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'customers',		-- widget_name
		'#intranet-core.Customer#',	-- pretty_name
		'#intranet-core.Customers#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_company_options -include_empty_p 0 -status "Active or Potential" -type "CustOrIntl"} switch_p 1}}', 
		'im_name_from_id'
);


SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'project_leads',		-- widget_name
		'#intranet-core.Project_Manager#',	-- pretty_name
		'#intranet-core.Project_Managers#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_project_manager_options -include_empty 0} switch_p 1}}', -- -
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'project_parent_options',		-- widget_name
		'Parent Project List',	-- pretty_name
		'Parent Project List',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -project_id $super_project_id} switch_p 1 global_var super_project_id}}', -- -
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'timestamp',		-- widget_name
		'#intranet-core.Timestamp#',	-- pretty_name
		'#intranet-core.Timestamps#',	-- pretty_plural
		10007,			-- storage_type_id
		'date',		-- acs_datatype
		'date',		-- widget
		'date',		-- sql_datatype
		'{format "YYYY-MM-DD HH24:MM"}', 
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'on_track_status',		-- widget_name
		'#intranet-core.On_Track_Status#',	-- pretty_name
		'#intranet-core.On_Track_Status#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'im_category_tree',		-- widget
		'integer',		-- sql_datatype
		'{custom {category_type "Intranet Project On Track Status"}}', 
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'percent',		-- widget_name
		'#intranet-core.On_Track_Status#',	-- pretty_name
		'#intranet-core.On_Track_Status#',	-- pretty_plural
		10007,			-- storage_type_id
		'float',		-- acs_datatype
		'text',		-- widget
		'float',		-- sql_datatype
		'', 
		'im_percent_from_number'
);


-- create dynfield attributes of object_type im_project
-- project_name
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_name'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_name'',			-- column_name
		 ''#intranet-core.Project_Name#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 1,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- project_nr
CREATE OR REPLACE FUNCTION inline_1 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_nr'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_nr'',			-- column_name
		 ''#intranet-core.Project_Nr#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 2,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_1 ();
DROP FUNCTION inline_1 ();


-- parent_id
CREATE OR REPLACE FUNCTION inline_2 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''parent_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_parent_options'',		-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''parent_id'',				-- column_name
		 ''#intranet-core.Parent_Project#'',	-- pretty_name
		 ''project_parent_options'',		-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 3,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_2 ();
DROP FUNCTION inline_2 ();

-- project_path
CREATE OR REPLACE FUNCTION inline_3 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_path'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_path'',			-- column_name
		 ''#intranet-core.Project_Path#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 4,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_3 ();
DROP FUNCTION inline_3 ();



-- company_id
CREATE OR REPLACE FUNCTION inline_4 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''company_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''customers'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''company_id'',			-- column_name
		 ''#intranet-core.Company#'',		-- pretty_name
		 ''customers'',				-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 5,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_4 ();
DROP FUNCTION inline_4 ();

-- project_lead_id
CREATE OR REPLACE FUNCTION inline_5 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_lead_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_leads'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_lead_id'',			-- column_name
		 ''#intranet-core.Project_Manager#'',	-- pretty_name
		 ''project_leads'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 6,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_5 ();
DROP FUNCTION inline_5 ();


-- project_type_id
CREATE OR REPLACE FUNCTION inline_6 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_type_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_type'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_type_id'',			-- column_name
		 ''#intranet-core.Project_Type#'',	-- pretty_name
		 ''project_type'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 7,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_6 ();
DROP FUNCTION inline_6 ();


-- project_status_id
CREATE OR REPLACE FUNCTION inline_7 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_status_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_status'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_status_id'',			-- column_name
		 ''#intranet-core.Project_Status#'',	-- pretty_name
		 ''project_status'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 8,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_7 ();
DROP FUNCTION inline_7 ();

-- start_date
CREATE OR REPLACE FUNCTION inline_8 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''start_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''start_date'',			-- column_name
		 ''#intranet-core.Start_Date#'',	-- pretty_name
		 ''date'',				-- widget_name
		 ''date'',				-- acs_datatype
		 ''t'',					-- required_p   
		 9,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_8 ();
DROP FUNCTION inline_8 ();

-- Add javascript calendar buton on date widget
UPDATE im_dynfield_widgets set parameters = '{format "YYYY-MM-DD"} {after_html {<input type="button" style="height:23px; width:23px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" ></b>}}' where widget_name = 'date';

-- end_date
CREATE OR REPLACE FUNCTION inline_9 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''end_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''end_date'',				-- column_name
		 ''#intranet-core.End_Date#'',		-- pretty_name
		 ''date'',				-- widget_name
		 ''date'',				-- acs_datatype
		 ''t'',					-- required_p   
		 10,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_9 ();
DROP FUNCTION inline_9 ();


-- on_track_status_id
CREATE OR REPLACE FUNCTION inline_10 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''on_track_status_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''on_track_status'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''on_track_status_id'',		-- column_name
		 ''#intranet-core.On_Track_Status#'',	-- pretty_name
		 ''on_track_status'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 11,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_10 ();
DROP FUNCTION inline_10 ();

-- percent_completed
CREATE OR REPLACE FUNCTION inline_11 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''percent_completed'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''percent_completed'',			-- column_name
		 ''#intranet-core.Percent_Completed#'',	-- pretty_name
		 ''numeric'',				-- widget_name
		 ''float'',				-- acs_datatype
		 ''f'',					-- required_p   
		 12,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_11 ();
DROP FUNCTION inline_11 ();


-- project_budget_hours
CREATE OR REPLACE FUNCTION inline_12 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget_hours'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''project_budget_hours'',		   	-- column_name
		 ''#intranet-core.Project_Budget_Hours#'', 	-- pretty_name
		 ''numeric'',					-- widget_name
		 ''float'',					-- acs_datatype
		 ''f'',						-- required_p   
		 13,					   	-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_12 ();
DROP FUNCTION inline_12 ();


-- project_budget
CREATE OR REPLACE FUNCTION inline_13 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_budget'',			-- column_name
		 ''#intranet-core.Project_Budget#'',	-- pretty_name
		 ''numeric'',				-- widget_name
		 ''float'',				-- acs_datatype
		 ''f'',					-- required_p   
		 14,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_13 ();
DROP FUNCTION inline_13 ();

--project_budget_currency
CREATE OR REPLACE FUNCTION inline_14 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget_currency'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''currencies'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''project_budget_currency'',			-- column_name
		 ''#intranet-core.Project_Budget_Currency#'',	-- pretty_name
		 ''currencies'',				-- widget_name
		 ''string'',					-- acs_datatype
		 ''f'',						-- required_p   
		 15,						-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );
	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_14 ();
DROP FUNCTION inline_14 ();

-- company_project_nr
CREATE OR REPLACE FUNCTION inline_15 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''company_project_nr'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''company_project_nr'',			-- column_name
		 ''#intranet-core.Company_Project_Nr#'',	-- pretty_name
		 ''textbox_medium'',				-- widget_name
		 ''string'',					-- acs_datatype
		 ''f'',						-- required_p   
		 16,						-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_15 ();
DROP FUNCTION inline_15 ();

-- description
CREATE OR REPLACE FUNCTION inline_16 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''description'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''richtext'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t''					-- already_existed_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''description'',			-- column_name
		 ''#intranet-core.Description#'',	-- pretty_name
		 ''richtext'',				-- widget_name
		 ''text'',				-- acs_datatype
		 ''f'',					-- required_p   
		 17,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_16 ();
DROP FUNCTION inline_16 ();




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

-- Create im_view for timesheet_tasks
insert into im_views (view_id, view_name, visible_for) values (950, 'im_timesheet_task_home_list', 'view_projects');


-- Task_id
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92100,950,NULL, 'TaskID','<center>@tasks.task_id;noquote@</center>','','',0,'');

-- Task Name
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92101,950,NULL,'Name','<nobr>@tasks.gif_html;noquote@<a href=@tasks.object_url;noquote@>@tasks.task_name;noquote@</a></nobr>','','',1,'');

-- Planned Units
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92102,950,NULL,'PLN','<center><a href=@tasks.object_url;noquote@>@tasks.planned_units;noquote@</a></center>','','',2,'');

-- Start Date
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92103,950,NULL,'Start', '<center>@tasks.start_date;noquote@</center>','','',3,'');

-- End Date
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92104,950,NULL,'End', '<center>@tasks.end_date;noquote@</center>','','',4,'');

-- Log Hours
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92105,950,NULL,'Log','<center><a href=@tasks.timesheet_report_url;noquote@">@tasks.logged_hours;noquote@</a></center>','','',5,'');

-- Task Prio
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92106,950,NULL, 'Prio','<center>@tasks.task_prio;noquote@</center>','','',6,'');

-- Checkbox
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92107,950,NULL,'<input type=checkbox name=_dummy onclick=acs_ListCheckAll(\"tasks\",this.checked)>','<input type=checkbox name=task_id.@tasks.task_id@ id=tasks,@tasks.task_id@>', '', '', 7, '');



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
	v_count	       integer;

BEGIN
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_name'';
     
      IF v_attribute_id > 0 THEN

      	 UPDATE acs_attributes SET pretty_name = ''Task'', min_n_values = 1, sort_order = 1 
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;

      ELSE
	 v_attribute_id :=  im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''t'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''t'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;

      RETURN 0;
END;' language 'plpgsql';

SELECT inline_1 ();
DROP FUNCTION inline_1 ();


--project_nr
CREATE OR REPLACE FUNCTION inline_2 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
	
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_nr'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET pretty_name = ''Task Nr.'', min_n_values = 1, sort_order = 2 
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);
	 
      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
	v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''t'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''t'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';

SELECT inline_2 ();
DROP FUNCTION inline_2 ();


-- parent_id
CREATE OR REPLACE FUNCTION inline_3 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;

BEGIN
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''parent_id'';
     
      IF v_attribute_id > 0 THEN

      	 UPDATE acs_attributes SET pretty_name = ''Project'', min_n_values = 0, sort_order = 3
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
        ''im_timesheet_task'',
        ''parent_id'',
        ''Project ID'',
        ''project_parent_options'',
        ''integer'',
        ''t'',
        3,
        ''f'',
        ''im_projects''
        );
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;



      RETURN 0;
END;' language 'plpgsql';


SELECT inline_3 ();
DROP FUNCTION inline_3 ();


-- uom_id
CREATE OR REPLACE FUNCTION inline_6 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
	
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''uom_id'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 6
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

     	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''none'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_6 ();
DROP FUNCTION inline_6 ();


-- cost_center
CREATE OR REPLACE FUNCTION inline_7 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
	
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''cost_center_id'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 1, sort_order = 7
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);


     	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''none'',null,null,null,''t'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'', required_p = ''t'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_7 ();
DROP FUNCTION inline_7 ();



-- material_id
CREATE OR REPLACE FUNCTION inline_8 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''material_id'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 8
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE 
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''none'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_8 ();
DROP FUNCTION inline_8 ();


-- planned_units
CREATE OR REPLACE FUNCTION inline_9 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
	
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''planned_units'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 9
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

     	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;

      RETURN 0;
END;' language 'plpgsql';


SELECT inline_9 ();
DROP FUNCTION inline_9 ();

-- billable_units
CREATE OR REPLACE FUNCTION inline_10 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;
		
BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''billable_units'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 10
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;

      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;
      
      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_10 ();
DROP FUNCTION inline_10 ();


-- percent_completed
CREATE OR REPLACE FUNCTION inline_11 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;

BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''percent_completed'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 11
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

    	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_11 ();
DROP FUNCTION inline_11 ();


-- start_date
CREATE OR REPLACE FUNCTION inline_12 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;

BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''start_date'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 12
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);


      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
        ''im_timesheet_task'',
        ''start_date'',
        ''Start Date'',
        ''date'',
        ''date'',
        ''f'',
        12,
        ''f'',
        ''im_projects''
        );
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''t'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''t'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_12 ();
DROP FUNCTION inline_12 ();




-- end_date
CREATE OR REPLACE FUNCTION inline_13 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;

BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''end_date'';
     
      IF v_attribute_id > 0 THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 13 
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

      	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
        ''im_timesheet_task'',
        ''end_date'',
        ''End Date'',
        ''date'',
        ''date'',
        ''f'',
        13,
        ''f'',
        ''im_projects''
        );
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''t'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''t'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
END;' language 'plpgsql';


SELECT inline_13 ();
DROP FUNCTION inline_13 ();


-- description
CREATE OR REPLACE FUNCTION inline_15 ()
RETURNS integer AS '
DECLARE 
	v_attribute_id integer;
	v_count	       integer;

BEGIN 
      SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa 
      WHERE ida.acs_attribute_id = aa.attribute_id AND aa.object_type = ''im_timesheet_task'' AND aa.attribute_name = ''description'';
     
      IF v_attribute_id IS NOT NULL THEN
      	 UPDATE acs_attributes SET min_n_values = 0, sort_order = 14 
	 WHERE attribute_id = (SELECT acs_attribute_id FROM im_dynfield_attributes WHERE attribute_id = v_attribute_id);

     	 UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
      ELSE
        v_attribute_id := im_dynfield_attribute_new (
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
      END IF;

      SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      IF v_count = 0 THEN
      	 INSERT INTO im_dynfield_type_attribute_map
	 	(attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	 VALUES
		(v_attribute_id, 100,''edit'',null,null,null,''f'');
      ELSE
	 UPDATE im_dynfield_type_attribute_map SET display_mode = ''display'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
      END IF;


      RETURN 0;
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

-- Make sure User Locale Component is readable for anybody
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	row		RECORD;
	v_object_id	INTEGER;

BEGIN

 	SELECT o.object_id INTO v_object_id 
	FROM im_component_plugins c, acs_objects o
	WHERE o.object_id = c.plugin_id
	AND package_name = ''intranet-core''
	AND plugin_name = ''User Locale'';

	FOR row IN 
		SELECT DISTINCT g.group_id
		FROM acs_objects o, groups g, im_profiles p
		WHERE g.group_id = o.object_id
		AND g.group_id = p.profile_id
		AND o.object_type = ''im_profile''
	LOOP
	
		PERFORM im_grant_permission(v_object_id,row.group_id,''read'');

	END LOOP;

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

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
	SET parameters = ''{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -exclude_tasks_p 1} switch_p 1}}'', widget = ''generic_tcl'' WHERE widget_id = v_widget_id;

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




-- Add more html tags in the acs-kernel parameter
UPDATE apm_parameter_values SET attr_value = 'A ADDRESS B BLOCKQUOTE BR CODE DIV DD DL DT EM FONT HR I LI OL P PRE SPAN STRIKE STRONG SUB SUP TABLE TBODY TD TR TT U UL EMAIL FIRST_NAMES LAST_NAME GROUP_NAME H1 H2 H3 H4 H5 H6' WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = 'AllowedTag');

UPDATE apm_parameter_values SET attr_value = 'align alt border cellpadding cellspacing color face height href hspace id name size src style target title valign vspace width' WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = 'AllowedAttribute');

UPDATE apm_parameter_values SET attr_value = 1 WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = 'UseHtmlAreaForRichtextP');

-- Update Notes for tasks
alter table im_projects alter column note type text;

-- Make sure we can upgrade existing notes for tasks to use richtext
update im_projects set note = '{' || note || '} text/html' where project_id in (select task_id from im_timesheet_tasks) and note not like '%text/html';

-- New functions to return the correct values
create or replace function im_percent_from_number (float)
returns varchar as '
DECLARE                                                                                                                                                      
        p_percent        alias for $1;
		v_percent	varchar;
BEGIN                           
		select to_char(p_percent,''90D99'') || '' %'' into v_percent;
        return v_percent;
END;' language 'plpgsql';

create or replace function im_numeric_from_id(float)
returns varchar as '
DECLARE                                                                                                                                                      
        v_result        alias for $1;
BEGIN                                                                                                                                                        
        return v_result::varchar;
END;' language 'plpgsql';

update im_dynfield_widgets set deref_plpgsql_function = 'im_numeric_from_id' where widget_name ='numeric';

-- Update the timesheet views
delete from im_biz_object_urls
where object_type = 'im_timesheet_task';

insert into im_biz_object_urls (object_type, url_type, url) values ('im_timesheet_task','view','/intranet-cognovis/tasks/view?task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values ('im_timesheet_task','edit','/intranet-cognovis/tasks/view?form_mode=edit&task_id=');



update im_view_columns set column_render_tcl = '"<nobr>$indent_html$gif_html<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a></nobr>"' where column_id = 91101;

update im_view_columns set column_render_tcl = '"<nobr>$indent_html$gif_html<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a></nobr>"' where column_id = 91002;


-- Disable components
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_plugin_id	integer;
	row		record;

BEGIN
    -- Disable the project wiki component (for projects)

    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Wiki Component'';

    UPDATE im_component_plugins SET enabled_p = ''f'' WHERE plugin_id = v_plugin_id;

    -- Disable the project conf component (for projects)

    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Configuration Items'';

    UPDATE im_component_plugins SET enabled_p = ''f'' WHERE plugin_id = v_plugin_id;

    -- Disable the ]project-open[ news component from the home screen.
    FOR row IN 
        SELECT plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/index'' AND plugin_name = ''Home &#93;po&#91; News''
    LOOP
        UPDATE im_component_plugins SET enabled_p = ''f'' WHERE plugin_id = row.plugin_id;
    END LOOP;

    -- Disable the intranet-filestorage components
    FOR row IN
        SELECT plugin_id FROM im_component_plugins WHERE package_name = ''intranet-filestorage''
    LOOP
        UPDATE im_component_plugins SET enabled_p = ''f'' WHERE plugin_id = row.plugin_id;
    END LOOP;

    -- Disable the project note component.
    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Notes'';

    UPDATE im_component_plugins SET enabled_p = ''f'' WHERE plugin_id = v_plugin_id;

    RETURN 0;
    
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

alter table im_projects alter column description type text;
-- --------------------------------------------------------
-- Projects Trigger
-- --------------------------------------------------------

drop trigger im_projects_calendar_update_tr on im_projects;
drop function im_projects_calendar_update_tr();

create or replace function im_projects_calendar_update_tr () returns trigger as '
declare
	v_cal_item_id		integer;	

	v_timespan_id		integer;
	v_interval_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;
begin
	-- -------------- Skip if start or end date are null ------------
	IF new.start_date is null OR new.end_date is null THEN
		return new;
	END IF;

	-- -------------- Check if the entry already exists ------------
	v_cal_item_id := null;

	SELECT	event_id
	INTO	v_cal_item_id
	FROM	acs_events
	WHERE	related_object_id = new.project_id
		and related_object_type = ''im_project'';

	-- --------------------- Create entry if it isnt there -------------
	IF v_cal_item_id is null THEN

		v_timespan_id := timespan__new(new.end_date, new.end_date);
		RAISE NOTICE ''im_projects_calendar_update_tr: timespan_id=%'', v_timespan_id;
	
		v_activity_id := acs_activity__new(
			null, 
			new.project_name,
			new.description, 
			''f'', 
			'''', 
			''acs_activity'', now(), null, ''0.0.0.0'', null
		);
		RAISE NOTICE ''im_projects_calendar_update_tr: v_activity_id=%'', v_activity_id;
	
		SELECT	min(calendar_id)
		INTO 	v_calendar_id
		FROM	calendars
		WHERE	private_p = ''f'';
	
		v_recurrence_id := NULL;
		v_cal_item_id := cal_item__new (
			null,			-- cal_item_id
			v_calendar_id,		-- on_which_calendar
			new.project_name,	-- name
			new.description,	-- description
			''f'',			-- html_p
			'''',			-- status_summary
			v_timespan_id,		-- timespan_id
			v_activity_id,		-- activity_id
			v_recurrence_id,	-- recurrence_id
			''cal_item'', null, now(), null, ''0.0.0.0''	
		);
		RAISE NOTICE ''im_projects_calendar_update_tr: cal_id=%'', v_cal_item_id;

	END IF;

	-- --------------------- Update the entry --------------------
	SELECT	activity_id	INTO v_activity_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	timespan_id	INTO v_timespan_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	recurrence_id	INTO v_recurrence_id	FROM acs_events	WHERE	event_id = v_cal_item_id;

	-- Update the event
	UPDATE	acs_events 
	SET	name = new.project_name,
		description = new.description,
		related_object_id = new.project_id,
		related_object_type = ''im_project'',
		related_link_url = ''/intranet/projects/view?project_id=''||new.project_id,
		related_link_text = new.project_name || '' Project'',
		redirect_to_rel_link_p = ''t''
	WHERE	event_id = v_cal_item_id;

	-- Update the activity - same as event
	UPDATE	acs_activities
	SET	name = new.project_name,
		description = new.description
	WHERE	activity_id = v_activity_id;

	-- Update the timespan. Make sure there is only one interval
	-- in this timespan (there may be multiples)
	SELECT	interval_id	INTO v_interval_id	FROM timespans	WHERE	timespan_id = v_timespan_id;

	RAISE NOTICE ''cal_update_tr: cal_item:%, activity:%, timespan:%, recurrence:%, interval:%'', 
			v_cal_item_id, v_activity_id, v_timespan_id, v_recurrence_id, v_interval_id;

	UPDATE	time_intervals
	SET	start_date = new.end_date,
		end_date = new.end_date
	WHERE	interval_id = v_interval_id;

	return new;
end;' language 'plpgsql';

create trigger im_projects_calendar_update_tr after insert or update
on im_projects for each row
execute procedure im_projects_calendar_update_tr ();

-- Set the defaults for project dynfields
update im_dynfield_type_attribute_map set default_value = 76 where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'project_status_id' and object_type ='im_project');

update im_dynfield_type_attribute_map set default_value = 85 where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'project_type_id' and object_type ='im_project');

update im_dynfield_type_attribute_map set default_value = 'tcl im_project_on_track_status_green' where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'on_track_status_id' and object_type ='im_project');

update im_dynfield_type_attribute_map set default_value = 0 where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'percent_completed' and object_type ='im_project');

update im_dynfield_type_attribute_map set default_value = 'tcl {ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"}' where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'project_budget_currency' and object_type ='im_project');

update im_dynfield_type_attribute_map set default_value = 'tcl {ad_conn user_id}' where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'project_lead_id' and object_type ='im_project');


-- Make all components visible/readable to employees and p/o admins
CREATE OR REPLACE FUNCTION inline_0()
RETURNS integer AS '
DECLARE
	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;
BEGIN

	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	-- Project Base Data Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Project Base Data Cognovis'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Home Task Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Home Task Component'' AND page_url = ''/intranet/index'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Task Member Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Task Members Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Timesheet Task Project Information Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Project Information Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');





	-- Timesheet Task Resources
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Task Resources Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Timesheet Task Forum Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Forum'' AND page_url = ''/intranet-timesheet2-tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- Timesheet Task Info Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Info Component'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');



	-- User Basic Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Basic Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- User Contact Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Contact Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Skin Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Skin Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Administration Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Admin Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Localization Compoenent
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Locale'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- User Portrait
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Portrait'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	
	-- Company Info
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Information'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Company Projects
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Projects'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Company Members
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Employees'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Company Contacts
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Contacts'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();
	

	
	
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
BEGIN

	UPDATE im_component_plugins SET package_name = ''intranet-cognovis'' WHERE package_name = ''intranet-core'' AND page_url = ''intranet-cognovis/tasks/view'' AND plugin_name = ''Timesheet Task Info Component'';

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- Disable Project Translation Wizard Component
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 

	v_plugin_id	integer;
BEGIN
	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Project Translation Wizard'' AND page_url = ''/intranet/projects/view'';

	SELECT im_component_plugin__delete(v_plugin_id);

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
	v_min_n_values	integer;
	v_count		integer;
	v_required_p	char;
	
BEGIN
	-- Task
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_name'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	-- Task Nr.
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_nr'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	-- Project
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''parent_id''; 

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Task Status
        	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_status_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Task Type
        	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_type_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Unit of Measure
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''uom_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Cost Center
       	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''cost_center_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Material ID
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''material_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Planned Units
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''planned_units'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

 
	-- Billable Units
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''billable_units'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Percent Completed
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''percent_completed'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Start Date
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''start_date'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''display'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''display'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- End Date
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''end_date'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Description
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''description'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

alter table im_projects alter column description type text;

create or replace FUNCTION inline_0 ()
returns integer as '
DECLARE
	v_widget_id integer;

BEGIN
	SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''open_projects'';
	
	UPDATE im_dynfield_widgets 
	SET parameters = ''{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -exclude_tasks_p 1} switch_p 1}}'', widget = ''generic_tcl'' WHERE widget_id = v_widget_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

update acs_attributes set datatype='date' where attribute_name = 'end_date';
update acs_attributes set datatype='date' where attribute_name = 'start_date';

-- create dynfield attributes of object_type im_project
-- ticket_name
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''project_name'');

	UPDATE acs_attributes SET min_n_values = 1 WHERE object_type = ''im_ticket'' AND attribute_name = ''project_name'';

	UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
	
	UPDATE im_dynfield_layout SET pos_y = 0 WHERE attribute_id = v_attribute_id;
		
	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- project_nr
SELECT im_dynfield_attribute_new (
       'im_ticket',		        -- object_type
       'project_nr',			-- column_name
       '#intranet-helpdesk.Ticket_Nr#',	-- pretty_name
       'textbox_medium',	 	-- widget_name
       'string',			-- acs_datatype
       't',				-- required_p   
       1,				-- pos y
       'f',				-- also_hard_coded
       'im_projects'			-- table_name
);


-- parent_id/ticket_sla_id
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''parent_id'');

	
	UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;

	UPDATE im_dynfield_layout SET pos_y = 2 WHERE attribute_id = v_attribute_id;
	
	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- ticket_customer_contact_id
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_customer_contact_id'');

	
	UPDATE im_dynfield_layout SET pos_y = 3 WHERE attribute_id = v_attribute_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- ticket_type_id
SELECT im_dynfield_widget__new (
       null,
      'im_dynfield_widget', 
       now(),
       null,
       null,
       null,
       'ticket_type',
       'Ticket Type',
       'Ticket Types',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Type"}}',
       'im_name_from_id'
 );


SELECT im_dynfield_attribute_new (
       'im_ticket',				-- object_type
       'ticket_type_id',			-- column_name
       '#intranet-helpdesk.Ticket_Type#',	-- pretty_name
       'ticket_type',				-- widget_name
       'integer',				-- acs_datatype
       't',					-- required_p   
       4,					-- pos y
       'f',					-- also_hard_coded
       'im_tickets'				-- table_name
);



-- ticket_status_id
SELECT im_dynfield_widget__new (
       null,
       'im_dynfield_widget', 
       now(), 
       null,
       null, 
       null, 
       'ticket_status',
       'Ticket Status',
       'Ticket Status',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Status"}}',
       'im_name_from_id'
       );


SELECT im_dynfield_attribute_new (
       'im_ticket',				-- object_type
       'ticket_status_id',			-- column_name
       '#intranet-helpdesk.Ticket_Status#',	-- pretty_name
       'ticket_status',				-- widget_name
       'integer',				-- acs_datatype
       't',					-- required_p
       5,					-- pos y
       'f',					-- also_hard_coded
       'im_tickets'				-- table_name
);




-- Ticket Info Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Ticket Info Component',
       'intranet-helpdesk',
       'left', 
       '/intranet-cognovis/tickets/view', 
       null,
       1,
       'im_ticket_info_cognovis_component $ticket_id $return_url');

update im_component_plugins set page_url = '/intranet-cognovis/tickets/view' where page_url = '/intranet-helpdesk/new';
update im_component_plugins set enabled_p = 'f' where plugin_name = 'Filestorage' and page_url = '/intranet-cognovis/tickets/view';

\i notifications-create.sql;