-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

-- Change the way the absence_url is shown

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

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (20011,200,NULL,'Contact',
'"$contact_info_pretty"','','',11,'');




-- Add DynFields
--
select im_dynfield_attribute__new (
	null,				-- widget_id
	'im_dynfield_attribute',	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip	
	null,				-- context_id

	'im_user_absence',		-- attribute_object_type
	'description',			-- attribute name
	0,				-- min_n_values
	1,				-- max_n_values
	null,				-- default_value
	'date',				-- ad_form_datatype
	'#intranet-timesheet2.Description#',	-- pretty name
	'#intranet-timesheet2.Description#',	-- pretty plural
	'textarea_small',		-- widget_name
	'f',				-- deprecated_p
	't'				-- already_existed_p
);

update acs_attributes set sort_order = 50
where attribute_name = 'description' and object_type = 'im_user_absence';


-- Add DynFields
--
select im_dynfield_attribute__new (
	null,				-- widget_id
	'im_dynfield_attribute',	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip	
	null,				-- context_id

	'im_user_absence',		-- attribute_object_type
	'contact_info',			-- attribute name
	0,				-- min_n_values
	1,				-- max_n_values
	null,				-- default_value
	'date',				-- ad_form_datatype
	'#intranet-timesheet2.Contact#',	-- pretty name
	'#intranet-timesheet2.Contact#',	-- pretty plural
	'textarea_small',		-- widget_name
	'f',				-- deprecated_p
	't'				-- already_existed_p
);

update acs_attributes set sort_order = 60
where attribute_name = 'contact_info' and object_type = 'im_user_absence';
