-- upgrade-3.5.0.0.0-3.5.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.5.0.0.0-3.5.0.0.1.sql','');


create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

	select count(*) into v_count from information_schema.columns where 
		table_name = ''im_employees''
		and column_name = ''personnel_number'';

        IF v_count > 0 THEN return 1; END IF;

        alter table im_employees add column personnel_number character varying(10);
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
