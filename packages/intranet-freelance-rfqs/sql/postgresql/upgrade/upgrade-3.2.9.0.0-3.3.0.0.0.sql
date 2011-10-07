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


