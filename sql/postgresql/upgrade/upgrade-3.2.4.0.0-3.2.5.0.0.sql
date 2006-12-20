-- upgrade-3.2.4.0.0-3.2.5.0.0.sql


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    user_tab_columns
        where   lower(table_name) = ''im_fs_files''
                and lower(column_name) = ''last_modified'';

        if v_count = 1 then
            return 0;
        end if;

	alter table im_fs_files
	add last_modified varchar(30);

	alter table im_fs_files
	add last_updated timestamptz;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



