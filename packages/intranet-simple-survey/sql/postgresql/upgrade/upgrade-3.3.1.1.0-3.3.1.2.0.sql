-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

SELECT acs_log__debug('/packages/intranet-simple-survey/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.3.1.2.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''SURVSIMP_RESPONSES'' and column_name = ''RELATED_OBJECT_ID'';
	IF v_count > 0 THEN return 0; END IF;

	alter table survsimp_responses
	add related_object_id integer references acs_objects;
	create index im_survsimp_responses_object_id_idx
	on survsimp_responses (related_object_id);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''SURVSIMP_RESPONSES'' and column_name = ''RELATED_CONTEXT_ID'';
	IF v_count > 0 THEN return 0; END IF;

	alter table survsimp_responses
	add related_context_id integer references acs_objects;
	create index im_survsimp_responses_context_id_idx
	on survsimp_responses (related_context_id);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
