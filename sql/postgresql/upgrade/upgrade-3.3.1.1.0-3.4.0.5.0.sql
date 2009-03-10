-- upgrade-3.3.1.1.0-3.4.0.5.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.4.0.5.0.sql','');


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
	add billable_units_interco  numeric(12,1);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




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


