-- upgrade-3.2.9.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-freelance-rfqs/sql/postgresql/upgrade/upgrade-3.2.9.0.0-3.3.0.0.0.sql','');

\i ../../../../intranet-core/sql/postgresql/upgrade/upgrade-3.0.0.0.first.sql


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where table_name = ''im_freelance_rfq_answers'';
	IF v_count > 0 THEN return 0; END IF;

	select count(*) into v_count from acs_object_types
	where object_type = ''im_freelance_rfq_answer'';
	IF v_count = 0 THEN return 0; END IF;

	insert into acs_object_type_tables (
		object_type,
		table_name,
		id_column
	) values (
		''im_freelance_rfq_answer'',
		''im_freelance_rfq_answers'',
		''rfq_id''
	);

	return v_count;
end;' language 'plpgsql';
SELECT inline_0();
DROP FUNCTION inline_0();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_freelance_rfq_answers'' and lower(column_name) = ''general_outcome'';
	IF v_count > 0 THEN return 0; END IF;

	select count(*) into v_count from acs_object_types
	where object_type = ''im_freelance_rfq_answer'';
	IF v_count = 0 THEN return 0; END IF;

	alter table im_freelance_rfq_answers add general_outcome varchar;

	return v_count;
end;' language 'plpgsql';
SELECT inline_0();
DROP FUNCTION inline_0();



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


select im_dynfield_attribute__new (
	null,				-- widget_id
	'im_dynfield_attribute',	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip	
	null,				-- context_id

	'im_freelance_rfq_answer',	-- attribute_object_type
	'general_outcome',		-- attribute name
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

