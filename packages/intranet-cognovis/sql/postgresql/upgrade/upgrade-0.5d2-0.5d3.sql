-- upgrade-0.5d2-0.5d3.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d2-0.5d3.sql','');

create or replace function inline_0() 
returns integer as '
BEGIN
       update acs_attributes set table_name = ''im_projects'' 
       where object_type = ''im_project'' and table_name is null;

       return 0;
END;' language 'plpgsql';

SELECT inline_0();
DROP FUNCTION inline_0();


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