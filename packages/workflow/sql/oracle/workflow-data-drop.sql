-- Convenient script for dropping all data (but not the datamodel)

declare
  foo integer;
begin
  for row in (select workflow_id from workflows)
  loop
    foo := workflow.del(row.workflow_id);
  end loop;
end;
/
show errors
