-- We were missing an upgrade script to fix the cr_folder permissions inheritance problem.
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- $Id$



-- recreate this function

create or replace function bt_project__new(
    integer                      -- package_id
) returns integer 
as '
declare
    p_package_id                alias for $1;
    v_count                     integer;
    v_instance_name             varchar;
    v_creation_user             integer;
    v_creation_ip               varchar;
    v_folder_id                 integer;
    v_keyword_id                integer;
begin
    select count(*)
    into   v_count
    from   bt_projects
    where  project_id = p_package_id;

    if v_count > 0 then
        return 0;
    end if;

    -- get instance name for the content folder
    select p.instance_name, o.creation_user, o.creation_ip
    into   v_instance_name, v_creation_user, v_creation_ip
    from   apm_packages p join acs_objects o on (p.package_id = o.object_id)
    where  p.package_id = p_package_id;

    -- create a root CR folder
    v_folder_id := content_folder__new(
        ''bug_tracker_''||p_package_id,        -- name
        v_instance_name,                       -- label
        null,                                  -- description
        content_item_globals.c_root_folder_id, -- parent_id
        p_package_id,                          -- context_id
        null,                                  -- folder_id
        now(),                                 -- creation_date
        v_creation_user,                       -- creation_user
        v_creation_ip,                         -- creation_ip,
        ''t''                                  -- security_inherit_p
    );

    -- Set package_id column. Oddly enoguh, there is no API to set it
    update cr_folders set package_id = p_package_id where folder_id = v_folder_id;

    -- register our content type
    PERFORM content_folder__register_content_type (
        v_folder_id,          -- folder_id
        ''bt_bug_revision'',  -- content_type
        ''t''                 -- include_subtypes
    );

    -- create the instance root keyword
    v_keyword_id := content_keyword__new(
        v_instance_name,                -- heading
        null,                           -- description
        null,                           -- parent_id
        null,                           -- keyword_id
        current_timestamp,              -- creation_date
        v_creation_user,                -- creation_user
        v_creation_ip,                  -- creation_ip
        ''content_keyword''             -- object_type
    );

    -- insert the row into bt_projects
    insert into bt_projects 
        (project_id, folder_id, root_keyword_id) 
    values 
        (p_package_id, v_folder_id, v_keyword_id);

    -- Create a General component to start with
    insert into bt_components (component_id, project_id, component_name)
    select acs_object_id_seq.nextval, p_package_id, ''General'';

    return 0;
end;
' language 'plpgsql';



-- update context_id, package_id of existing folders

create or replace function inline_0(
) returns integer 
as '
declare
    rec                   record;
begin
    -- change context_id of bug-tracker root folders to be package instance

    for rec in 
        select project_id, folder_id from bt_projects
    loop
        update acs_objects set context_id = rec.project_id where object_id = rec.folder_id;
        update cr_folders set package_id = rec.project_id where folder_id = rec.folder_id;
    end loop;

    return 0;
end;
' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
