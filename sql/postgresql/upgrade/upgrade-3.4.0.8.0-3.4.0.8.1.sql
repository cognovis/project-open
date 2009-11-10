-- upgrade-3.4.0.8.0-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2/sql/postgresql/upgrade/upgrade-3.4.0.8.0-3.4.0.8.1.sql','');


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''IM_USER_ABSENCES'' and column_name = ''GROUP_ID'';
        if v_count > 0 then return 0; end if;

	alter table im_user_absences add group_id integer
	constraint im_user_absences_group_fk references groups;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

