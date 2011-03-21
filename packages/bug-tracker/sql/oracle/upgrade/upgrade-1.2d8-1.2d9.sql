-- Correcting the CR folders so they inherit permissions from the package
--
-- @author Lars Pind (lars@collaboraid.biz)

declare
    cursor project_cur is
    	select project_id, folder_id from bt_projects;
begin
    for project_rec in project_cur
    loop
        update acs_objects
        set    context_id = project_rec.project_id
        where  object_id = project_rec.folder_id;
    end loop;
end;
/
show errors
