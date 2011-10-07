-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

SELECT acs_log__debug('/packages/intranet-freelance-rfqs/sql/postgresql/upgrade/upgrade-3.2.11.0.0-3.2.12.0.0.sql','');


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'general_rfq_accept',	-- widget_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'radio',		-- widget
	'integer',		-- sql_datatype
	'{options { {"#intranet-freelance-rfqs.Yes_I_can_do#" 1} {"#intranet-freelance-rfqs.No_I_decline#" 0} }}'
);




create or replace function im_insert_acs_object_type_tables (varchar, varchar, varchar)
returns integer as $body$
DECLARE
        p_object_type           alias for $1;
        p_table_name            alias for $2;
        p_id_column             alias for $3;

        v_count                 integer;
BEGIN
        -- Check for duplicates
        select  count(*) into v_count
        from    acs_object_type_tables
        where   object_type = p_object_type and
                table_name = p_table_name;
        IF v_count > 0 THEN return 1; END IF;

        -- Make sure the object_type exists
        select  count(*) into v_count
        from    acs_object_types
        where   object_type = p_object_type;
        IF v_count = 0 THEN return 2; END IF;

        insert into acs_object_type_tables (object_type, table_name, id_column)
        values (p_object_type, p_table_name, p_id_column);

        return 0;
end;$body$ language 'plpgsql';


SELECT im_insert_acs_object_type_tables('im_freelance_rfq','im_freelance_rfqs','rfq_id');
SELECT im_insert_acs_object_type_tables('im_freelance_rfq_answer','im_freelance_rfq_answers','answer_id');


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns 
	where	lower(table_name) = 'im_freelance_rfqs' and
		lower(column_name) = 'general_outcome';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_freelance_rfqs add general_outcome varchar;

	return 0;
end; $body$ language 'plpgsql';
SELECT inline_0();
drop function inline_0();




select im_dynfield_attribute__new (
	null,			-- widget_id
	'im_dynfield_attribute', -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id

	'im_freelance_rfq',	-- attribute_object_type
	'general_outcome',	-- attribute name
	1,
	1,
	null,
	'string',
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty plural
	'general_rfq_accept',
	't',
	't'
);

