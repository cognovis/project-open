-- upgrade-4.0.3.0.8-4.0.3.0.9.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.8-4.0.3.0.9.sql','');


----------------------------------------------------------------
-- 
----------------------------------------------------------------

create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_gantt_assignments';
	IF v_count > 0 THEN return 1; END IF;

	create table im_gantt_assignments (
        rel_id                  integer
                                constraint im_gantt_assignments_pk primary key
                                constraint im_gantt_assignments_rel_fk
                                references im_biz_object_members,
        xml_elements            text
                                constraint im_gantt_persons_xml_elements_nn
                                not null
	);

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_gantt_assignment_timephases';
	IF v_count > 0 THEN return 1; END IF;

	create sequence im_gantt_assignments_timephased_seq;

	create table im_gantt_assignment_timephases (
	                                -- Unique ID, but not an object!
	        timephase_id            integer
	                                default nextval('im_gantt_assignments_timephased_seq')
	                                constraint im_gantt_assignment_timephases_pk
	                                primary key,
	                                -- Reference to the im_gantt_assignments base entry
	        rel_id                  integer
	                                constraint im_gantt_assignments_rel_fk
	                                references im_gantt_assignments,
	                                -- Data from MS-Project XML Export without interpretation
	        timephase_uid           integer,
	        timephase_type          integer,
	        timephase_start         timestamptz,
	        timephase_end           timestamptz,
	        timephase_unit          integer,
	        timephase_value         text
	);

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



