-- Correcting the CR folders so they inherit permissions from the package
--
-- @author Lars Pind (lars@collaboraid.biz)

create or replace function inline_0 ()
returns integer as '
declare
  project_rec            record;
begin
    for project_rec in 
        select project_id, folder_id
        from   bt_projects
    loop
        update acs_objects
        set    context_id = project_rec.project_id
        where  object_id = project_rec.folder_id;
    end loop;
    
    return 0;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();


