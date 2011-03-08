-- Convenient script for dropping all workflow data (but not the datamodel)
 
-- Delete workflow data first
create function inline_0 ()
returns integer as '
declare
        row     record;
begin
        for row in select workflow_id from workflows
        loop
                perform workflow__delete(row.workflow_id);
        end loop;

        return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();
