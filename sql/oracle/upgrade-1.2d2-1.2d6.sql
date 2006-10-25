-- Change CR keywords to be deleted after row in bt_projects to avoid
-- referentail constraint violation

create or replace package body bt_project
as
    procedure new (
        package_id      in integer
    )
    is
        v_count                 integer;
        v_instance_name         varchar(300);
        v_creation_user         integer;
        v_creation_ip           varchar(50);
        v_folder_id             integer;
        v_root_folder_id        integer;
        v_keyword_id            integer;
    begin
        select count (*)
        into v_count
        from bt_projects
        where project_id = new.package_id;

        if v_count > 0 then
            return;
        end if;

        -- get instance name for the content folder
        select p.instance_name, o.creation_user, o.creation_ip
        into   v_instance_name, v_creation_user, v_creation_ip
        from   apm_packages p,
               acs_objects o
        where  p.package_id = bt_project.new.package_id
        and    p.package_id = o.object_id;

        select content_item.get_root_folder
        into   v_root_folder_id
        from   dual;

        -- create a root CR folder
        v_folder_id := content_folder.new(
            name => 'bug_tracker_' || bt_project.new.package_id,
            label => v_instance_name,
            description => null,
            parent_id => v_root_folder_id
        );

        -- register our content type
        content_folder.register_content_type (
            folder_id =>        v_folder_id,
            content_type =>     'bt_bug_revision',
            include_subtypes => 't'
        );

        -- create the instance root keyword
        v_keyword_id := content_keyword.new(
            heading =>          v_instance_name,
            description =>      null,
            parent_id =>        null,
            keyword_id =>       null,
            creation_date =>    sysdate(),
            creation_user =>    v_creation_user,
            creation_ip =>      v_creation_ip,
            object_type =>      'content_keyword'
        );

        -- insert the row into bt_projects
        insert into bt_projects 
            (project_id, folder_id, root_keyword_id) 
        values 
            (bt_project.new.package_id, v_folder_id, v_keyword_id);

        -- Create a General component to start with
        insert into bt_components
            (component_id, project_id, component_name)
        values
            (acs_object_id_seq.nextval, bt_project.new.package_id, 'General');

        return;
    end new;

    procedure delete (
        project_id      in integer
    )
    is
        v_folder_id         integer;
        v_root_keyword_id   integer;
    begin

        -- get the content folder for this instance
        select folder_id, root_keyword_id
        into   v_folder_id, v_root_keyword_id
        from   bt_projects
        where  project_id = bt_project.delete.project_id;

        -- This get''s done in tcl before we are called ... for now
        -- Delete the bugs
        -- for rec in select item_id from cr_items where parent_id = v_folder_id
        -- loop
        --      bt_bug.delete(rec.item_id);
        -- end loop;

        -- Delete the patches
        for rec in (select patch_id from bt_patches where project_id = bt_project.delete.project_id)
        loop
             bt_patch.delete(rec.patch_id);
        end loop;

        -- delete the projects keywords
        bt_project.keywords_delete(
            project_id => project_id,
            delete_root_p => 't'
        );

        -- These tables should really be set up to cascade
        delete from bt_versions where project_id = bt_project.delete.project_id;
        delete from bt_components where project_id = bt_project.delete.project_id;
        delete from bt_user_prefs where project_id = bt_project.delete.project_id;      

        delete from bt_projects where project_id = bt_project.delete.project_id;   

        -- delete the content folder
        content_folder.delete(v_folder_id);

    end delete;

    procedure keywords_delete (
        project_id      in integer,
        delete_root_p   in varchar2 default 'f'
    )
    is
        v_root_keyword_id     integer;
        v_changed_p           char(1);
    begin
        -- get the content folder for this instance
        select root_keyword_id
        into   v_root_keyword_id
        from   bt_projects
        where  project_id = keywords_delete.project_id;

        -- if we are deleting the root, remove it from the project as well
        if delete_root_p = 't' then
            update bt_projects 
            set    root_keyword_id = null 
            where  project_id = keywords_delete.project_id;
        end if;

        -- delete the projects keywords

        -- Keep looping over all project keywords, deleting all
        -- leaf nodes, until everything has been deleted
        loop
            v_changed_p := 'f';
            for rec in 
              (select keyword_id
               from  (select  keyword_id
                      from    cr_keywords
                      start   with  keyword_id = v_root_keyword_id
                      connect by prior keyword_id = parent_id) q
               where  content_keyword.is_leaf(keyword_id) = 't')
            loop
                if (delete_root_p = 't') or (rec.keyword_id != v_root_keyword_id) then
                    content_keyword.delete(rec.keyword_id);
                    v_changed_p := 't';
                end if;
            end loop;
            
            exit when v_changed_p = 'f';
        end loop;

    end keywords_delete;

end bt_project;
/
show errors
