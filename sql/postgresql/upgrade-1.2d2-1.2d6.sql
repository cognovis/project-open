-- Change CR keywords to be deleted after row in bt_projects to avoid
-- referentail constraint violation

create or replace function bt_project__delete(
    integer                 -- project_id
) returns integer
as '
declare
    p_project_id          alias for $1;
    v_folder_id           integer;
    v_root_keyword_id     integer;
    rec                   record;
begin
    -- get the content folder for this instance
    select folder_id, root_keyword_id
    into   v_folder_id, v_root_keyword_id
    from   bt_projects
    where  project_id = p_project_id;

    -- This gets done in tcl before we are called ... for now
    --  Delete the bugs
    -- for rec in select item_id from cr_items where parent_id = v_folder_id
    -- loop
    --     perform bt_bug__delete(rec.item_id);
    -- end loop;

    -- Delete the patches
    for rec in select patch_id from bt_patches where project_id = p_project_id
    loop
         perform bt_patch__delete(rec.patch_id);
    end loop;

    -- delete the projects keywords
    perform bt_projects__keywords_delete(p_project_id, ''t'');

    -- These tables should really be set up to cascade
    delete from bt_versions where project_id = p_project_id;
    delete from bt_components where project_id = p_project_id;
    delete from bt_user_prefs where project_id = p_project_id;      

    delete from bt_projects where project_id = p_project_id;   

    -- delete the content folder
    raise notice ''about to delete content_folder.'';
    perform content_folder__delete(v_folder_id);

    return 0;
end;
' language 'plpgsql';
