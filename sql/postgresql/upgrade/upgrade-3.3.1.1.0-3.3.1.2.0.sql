-- upgrade-3.3.1.1.0-3.3.1.2.0.sql


-- ------------------------------------------------------
-- Setup status and type columns for im_user_absences
-- ------------------------------------------------------

update acs_object_types set 
	status_column = 'absence_status_id', 
	type_column='absence_type_id', 
	status_type_table='im_user_absences' 
where object_type = 'im_user_absence';





-- ------------------------------------------------------
-- Relax unique constraint
-- ------------------------------------------------------

alter table im_user_absences
drop constraint owner_and_start_date_unique;

alter table im_user_absences 
add constraint owner_and_start_date_unique unique (owner_id,absence_type_id,start_date);

-- ------------------------------------------------------
-- New privilege for those privileged users who can set an 
-- absence status manually (and thus override WF results).
-- ------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count
        from acs_privileges where privilege = ''edit_absence_status'';
        if v_count > 0 then return 0; end if;

        PERFORM acs_privilege__create_privilege(''edit_absence_status'',''Edit Absence Status'',''Edit Absence Status'');
        PERFORM acs_privilege__add_child(''admin'', ''edit_absence_status'');

        PERFORM im_priv_create(''edit_absence_status'', ''Accounting'');
        PERFORM im_priv_create(''edit_absence_status'', ''P/O Admins'');
        PERFORM im_priv_create(''edit_absence_status'', ''Project Managers'');
        PERFORM im_priv_create(''edit_absence_status'', ''Senior Managers'');

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






-- ------------------------------------------------------
-- Absence View Definition
-- ------------------------------------------------------

delete from im_view_columns where view_id = 200;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20001,200,NULL,'Name',
'"<a href=$absence_view_url>$absence_name_pretty</a>"','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20003,200,NULL,'Start',
'"$start_date_pretty"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20004,200,NULL,'End',
'"$end_date_pretty"','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20005,200,NULL,'User',
'"<a href=/intranet/users/view?user_id=$owner_id>$owner_name</a>"','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20007,200,NULL,'Type',
'"$absence_type"','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20009,200,NULL,'Status',
'"$absence_status"','','',9,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (20009,200,NULL,'Description',
-- '"$description_pretty"', '','',9,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (20011,200,NULL,'Contact',
-- '"$contact_info_pretty"','','',11,'');




-- ------------------------------------------------------
-- Set the default WF for each absence type
-- ------------------------------------------------------

update im_categories
set aux_string1 = 'vacation_approval_wf'
where category_id = 5000;

update im_categories
set aux_string1 = 'personal_approval_wf'
where category_id = 5001;

update im_categories
set aux_string1 = 'sick_approval_wf'
where category_id = 5002;

update im_categories
set aux_string1 = 'travel_approval_wf'
where category_id = 5003;




-- ------------------------------------------------------
-- Workflow graph on Absence View Page
-- ------------------------------------------------------

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Absence Workflow',			-- component_name
	'intranet-timesheet2',			-- package_name
	'right',				-- location
	'/intranet-timesheet2/absences/new',	-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_workflow_graph_component -object_id $absence_id'
);


-- ------------------------------------------------------
-- Journal on Absence View Page
-- ------------------------------------------------------

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Absence Journal',			-- component_name
	'intranet-timesheet2',			-- package_name
	'bottom',				-- location
	'/intranet-timesheet2/absences/new',	-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_workflow_journal_component -object_id $absence_id'
);


-- ------------------------------------------------------
-- Menus
-- ------------------------------------------------------

SELECT im_new_menu(
	'intranet-timesheet2',
	'timesheet2_absences_vacation',
	'New Vacation',
	'/intranet-timesheet2/absences/new?absence_type_id=5000',
	10,
	'timesheet2_absences', 
	null
);

SELECT im_new_menu(
	'intranet-timesheet2',
	'timesheet2_absences_personal',
	'New Personal Absence',
	'/intranet-timesheet2/absences/new?absence_type_id=5001',
	20,
	'timesheet2_absences', 
	null
);

SELECT im_new_menu(
	'intranet-timesheet2',
	'timesheet2_absences_sick',
	'New Sick Leave',
	'/intranet-timesheet2/absences/new?absence_type_id=5002',
	30,
	'timesheet2_absences', 
	null
);

SELECT im_new_menu(
	'intranet-timesheet2',
	'timesheet2_absences_travel',
	'New Travel Absence',
	'/intranet-timesheet2/absences/new?absence_type_id=5003',
	40,
	'timesheet2_absences', 
	null
);

SELECT im_new_menu(
	'intranet-timesheet2',
	'timesheet2_absences_bankholiday',
	'New Bank Holiday',
	'/intranet-timesheet2/absences/new?absence_type_id=5004',
	50,
	'timesheet2_absences', 
	null
);




-- ------------------------------------------------------
-- Add DynFields
-- ------------------------------------------------------
--
-- select im_dynfield_attribute__new (
-- 	null,				-- widget_id
-- 	'im_dynfield_attribute',	-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip	
-- 	null,				-- context_id
-- 
-- 	'im_user_absence',		-- attribute_object_type
-- 	'description',			-- attribute name
-- 	0,				-- min_n_values
-- 	1,				-- max_n_values
-- 	null,				-- default_value
-- 	'date',				-- ad_form_datatype
-- 	'#intranet-timesheet2.Description#',	-- pretty name
-- 	'#intranet-timesheet2.Description#',	-- pretty plural
-- 	'textarea_small',		-- widget_name
-- 	'f',				-- deprecated_p
-- 	't'				-- already_existed_p
-- );
-- 
-- update acs_attributes set sort_order = 50
-- where attribute_name = 'description' and object_type = 'im_user_absence';
-- 
-- 
-- Add DynFields
--
-- select im_dynfield_attribute__new (
-- 	null,				-- widget_id
-- 	'im_dynfield_attribute',	-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip	
-- 	null,				-- context_id
-- 
-- 	'im_user_absence',		-- attribute_object_type
-- 	'contact_info',			-- attribute name
-- 	0,				-- min_n_values
-- 	1,				-- max_n_values
-- 	null,				-- default_value
-- 	'date',				-- ad_form_datatype
-- 	'#intranet-timesheet2.Contact#',	-- pretty name
-- 	'#intranet-timesheet2.Contact#',	-- pretty plural
-- 	'textarea_small',		-- widget_name
-- 	'f',				-- deprecated_p
-- 	't'				-- already_existed_p
-- );
-- 
-- update acs_attributes set sort_order = 60
-- where attribute_name = 'contact_info' and object_type = 'im_user_absence';
