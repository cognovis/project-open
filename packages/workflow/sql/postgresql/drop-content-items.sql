-- Convenient script for dropping all workflow data (but not the datamodel)
 
-- Delete workflow data first
create function inline_0 ()
returns integer as '
declare
        row     record;
begin
        for row in select item_id from cr_items where content_type = ''workflow_case_log_entry''
        loop
                perform content_item__delete(row.item_id);
        end loop;

        return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();
