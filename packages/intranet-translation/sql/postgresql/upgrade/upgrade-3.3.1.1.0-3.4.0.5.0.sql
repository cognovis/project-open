-- upgrade-3.3.1.1.0-3.4.0.5.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.4.0.5.0.sql','');


-- Translation TasksListPage columns
--
delete from im_view_columns where view_id = 90;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9001,90,NULL,'Task Name','$task_name_splitted','','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9003,90,NULL,'Target Lang','$target_language','','',30,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9004,90,NULL,'XTr','$match_x','','',40,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9005,90,NULL,'Rep','$match_rep','','',50,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9006,90,NULL,'100 %','$match100','','',60,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9007,90,NULL,'95 %','$match95','','',70,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9008,90,NULL,'85 %','$match85','','',80,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9009,90,NULL,'75 %','$match75','','',90,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9010,90,NULL,'50 %','$match50','','',100,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9011,90,NULL,'0 %','$match0','','',110,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9012,90,NULL,'Units','$task_units $uom_name','','',120,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9013,90,NULL,'Bill. Units','$billable_items_input','','',130,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9014,90,NULL,'Bill. Units Interco','$billable_items_input_interco','','',140,'expr $project_write && interco_p');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9015,90,NULL,'End Date','$end_date_formatted','','',160,'expr !$project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9016,90,NULL,'End Date','$end_date_input','','',160,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9017,90,NULL,'Task Type','$type_select','','',170,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9019,90,NULL,'Task Status','$status_select','','',190,'expr $project_write');

insert into im_view_columns (
        column_id, view_id, group_id, column_name,
        column_render_tcl, extra_select, extra_where,
        sort_order, visible_for
) values (
        9021,90,NULL,
        '<input type=checkbox name=_dummy onclick=\\"acs_ListCheckAll(''task'',this.checked)\\">',
        '$del_checkbox','','',
        210,'expr $project_write'
);

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9023,90,NULL,'Assigned','$assignments','','',230,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9025,90,NULL,'Message','$message','','',250,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9027,90,NULL,'[im_gif save "Download files"]','$download_link','','',270,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) 
values (9029,90,NULL,'[im_gif open "Upload files"]','$upload_link','','',290,'');


update im_view_columns set visible_for = 'expr $project_write && $interco_p' 
where column_id = 9014;


-- Add an "InterCo" billable units fields for different invoicing
-- towards an internal customer
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_trans_tasks''
		and lower(column_name) = ''billable_units_interco'';
	if v_count > 0 then return 0; end if;

	alter table im_trans_tasks
	add billable_units_interco  numeric(12,2);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar
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
		storage_type_id, acs_datatype, widget, sql_datatype, parameters
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters
	);
	return v_widget_id;
end;' language 'plpgsql';




select im_dynfield_widget__new (
        null,                                   -- widget_id
        'im_dynfield_widget',                   -- object_type
        now(),                                  -- creation_date
        null,                                   -- creation_user
        null,                                   -- creation_ip
        null,                                   -- context_id
        'translation_languages',                -- widget_name
        '#intranet-translation.Trans_Langs#',   -- pretty_name
        '#intranet-translation.Trans_Langs#',   -- pretty_plural
        10007,                                  -- storage_type_id
        'integer',                              -- acs_datatype
        'im_category_tree',                     -- widget
        'integer',                              -- sql_datatype
        '{custom {category_type "Intranet Translation Language"}}' -- parameters
);




create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attribute_object_type	alias for $7;
	p_attribute_name	alias for $8;
	p_min_n_values		alias for $9;
	p_max_n_values		alias for $10;
	p_default_value		alias for $11;

	p_datatype		alias for $12;
	p_pretty_name		alias for $13;
	p_pretty_plural		alias for $14;
	p_widget_name		alias for $15;
	p_deprecated_p		alias for $16;
	p_already_existed_p	alias for $17;

	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_table_name		varchar;
BEGIN
	-- Check for duplicate
	select	da.attribute_id into v_attribute_id
	from	acs_attributes aa, im_dynfield_attributes da 
	where	aa.attribute_id = da.acs_attribute_id and
		aa.attribute_name = p_attribute_name and aa.object_type = p_attribute_object_type;
	if v_attribute_id is not null then return v_attribute_id; end if;

	select table_name into v_table_name
	from acs_object_types where object_type = p_attribute_object_type;

	v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		v_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
	);

	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);

	-- By default show the field for all object types
	insert into im_dynfield_type_attribute_map (attribute_id, object_type_id, display_mode)
	select	ida.attribute_id,
		c.category_id,
		''edit''
	from	im_dynfield_attributes ida,
		acs_attributes aa,
		acs_object_types aot,
		im_categories c
	where	ida.acs_attribute_id = aa.attribute_id and
		aa.object_type = aot.object_type and
		aot.type_category_type = c.category_type and
		aot.object_type = p_attribute_object_type and
		aa.attribute_name = p_attribute_name;

	return v_attribute_id;
end;' language 'plpgsql';






create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char, char
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attribute_object_type	alias for $7;
	p_attribute_name	alias for $8;
	p_min_n_values		alias for $9;
	p_max_n_values		alias for $10;
	p_default_value		alias for $11;

	p_datatype		alias for $12;
	p_pretty_name		alias for $13;
	p_pretty_plural		alias for $14;
	p_widget_name		alias for $15;
	p_deprecated_p		alias for $16;
	p_already_existed_p	alias for $17;

	p_table_name		alias for $18;

	v_acs_attribute_id	integer;
	v_attribute_id		integer;

BEGIN
	-- Check for duplicate
	select	da.attribute_id into v_attribute_id
	from	acs_attributes aa, im_dynfield_attributes da 
	where	aa.attribute_id = da.acs_attribute_id and
		aa.attribute_name = p_attribute_name and aa.object_type = p_attribute_object_type;
	if v_attribute_id is not null then return v_attribute_id; end if;

	v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		p_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
	);

	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);

	-- By default show the field for all object types
	insert into im_dynfield_type_attribute_map (attribute_id, object_type_id, display_mode)
	select	ida.attribute_id,
		c.category_id,
		''edit''
	from	im_dynfield_attributes ida,
		acs_attributes aa,
		acs_object_types aot,
		im_categories c
	where	ida.acs_attribute_id = aa.attribute_id and
		aa.object_type = aot.object_type and
		aot.type_category_type = c.category_type and
		aot.object_type = p_attribute_object_type and
		aa.attribute_name = p_attribute_name;

	return v_attribute_id;
end;' language 'plpgsql';





-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1)
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;
	p_pos_y			alias for $7;
	p_also_hard_coded_p	alias for $8;

	v_dynfield_id		integer;
	v_widget_id		integer;
	v_type_category		varchar;
	row			RECORD;
	v_count			integer;
	v_min_n_value		integer;
BEGIN
	select	widget_id into v_widget_id from im_dynfield_widgets
	where	widget_name = p_widget_name;
	IF v_widget_id is null THEN return 1; END IF;

	select	count(*) from im_dynfield_attributes into v_count
	where	acs_attribute_id in (
			select	attribute_id 
			from	acs_attributes 
			where	attribute_name = p_column_name and
				object_type = p_object_type
		);
	IF v_count > 0 THEN return 1; END IF;

	v_min_n_value := 0;
	IF p_required_p = ''t'' THEN  v_min_n_value := 1; END IF;

	v_dynfield_id := im_dynfield_attribute__new (
		null, ''im_dynfield_attribute'', now(), 0, ''0.0.0.0'', null,
		p_object_type, p_column_name, v_min_n_value, 1, null,
		p_datatype, p_pretty_name, p_pretty_name, p_widget_name,
		''f'', ''f''
	);

	update im_dynfield_attributes set also_hard_coded_p = p_also_hard_coded_p
	where attribute_id = v_dynfield_id;

	insert into im_dynfield_layout (
		attribute_id, page_url, pos_y, label_style
	) values (
		v_dynfield_id, ''default'', p_pos_y, ''table''
	);

	-- set all im_dynfield_type_attribute_map to "edit"
	select type_category_type into v_type_category from acs_object_types
	where object_type = p_object_type;
	FOR row IN
		select	category_id
		from	im_categories
		where	category_type = v_type_category
	LOOP
		select	count(*) into v_count from im_dynfield_type_attribute_map
		where	object_type_id = row.category_id and attribute_id = v_dynfield_id;
		IF 0 = v_count THEN
			insert into im_dynfield_type_attribute_map (
				attribute_id, object_type_id, display_mode
			) values (
				v_dynfield_id, row.category_id, ''edit''
			);
		END IF;
	END LOOP;

	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''write'');

	RETURN v_dynfield_id;
END;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1)
) RETURNS integer as '
BEGIN
	RETURN im_dynfield_attribute_new($1,$2,$3,$4,$5,$6,null,''f'');
END;' language 'plpgsql';



SELECT im_dynfield_attribute_new (
	'im_project',
	'source_language_id',
	'Source Lang',
	'translation_languages',
	'integer',
	'f',
	'99',
	't'
);



-- extend accuracy for translation units 
ALTER TABLE im_trans_tasks ALTER COLUMN task_units TYPE numeric(12,2);
ALTER TABLE im_trans_tasks ALTER COLUMN billable_units TYPE numeric(12,2);
