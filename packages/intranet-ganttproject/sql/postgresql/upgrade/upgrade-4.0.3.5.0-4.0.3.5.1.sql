-- upgrade-4.0.3.5.0-4.0.3.5.1.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.5.0-4.0.3.5.1.sql','');


----------------------------------------------------------------
-- Update the im_gantt_projects from varchar(1000) to text
----------------------------------------------------------------

create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
	sql			varchar;
	row			RECORD;
begin
	FOR row IN
		select	column_name, 
			data_type, 
			character_maximum_length
		from	information_schema.columns
		where	table_name = 'im_gantt_projects' and
			data_type = 'character varying'
	LOOP
		sql := 'alter table im_gantt_projects alter column ' || row.column_name ||' type text';
		EXECUTE sql;

	END LOOP;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
	sql			varchar;
	row			RECORD;
begin
	FOR row IN
		select	column_name, 
			data_type, 
			character_maximum_length
		from	information_schema.columns
		where	table_name = 'im_gantt_persons' and
			data_type = 'character varying'
	LOOP
		sql := 'alter table im_gantt_persons alter column ' || row.column_name ||' type text';
		EXECUTE sql;

	END LOOP;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
	sql			varchar;
	row			RECORD;
begin
	FOR row IN
		select	column_name, 
			data_type, 
			character_maximum_length
		from	information_schema.columns
		where	table_name = 'im_gantt_assignments' and
			data_type = 'character varying'
	LOOP
		sql := 'alter table im_gantt_assignments alter column ' || row.column_name ||' type text';
		EXECUTE sql;

	END LOOP;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



