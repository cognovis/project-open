
create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) 
	into v_count 
	from user_tab_columns 
	where lower(table_name)='bt_bugs' 
		and lower(column_name)='bug_container_project_id';

        if v_count > 0 then
            return 0;
        end if;

	alter table bt_bugs add bug_container_project_id integer;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
