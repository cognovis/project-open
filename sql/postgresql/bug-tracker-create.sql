--
-- A "project" is one instance of the bug-tracker.
--

create table bt_projects (
  project_id                    integer not null
                                constraint bt_projects_apm_packages_fk
                                references apm_packages(package_id) 
                                on delete cascade
                                constraint bt_projects_pk 
                                primary key,
  description                   text,
  -- short string will be included in the subject line of emails                                                                
  email_subject_name            text,
  maintainer                    integer 
                                constraint bt_projects_maintainer_fk
                                references users(user_id),
  folder_id                     integer
                                constraint bt_projects_folder_fk
                                references cr_folders(folder_id),
  root_keyword_id               integer
                                constraint bt_projects_keyword_fk
                                references cr_keywords(keyword_id)
);

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

    -- delete the content folder
    raise notice ''about to delete content_folder.'';
    perform content_folder__delete(v_folder_id);

    -- delete the projects keywords
    perform bt_project__keywords_delete(p_project_id, ''t'');

    -- These tables should really be set up to cascade
    delete from bt_versions where project_id = p_project_id;
    delete from bt_components where project_id = p_project_id;
    delete from bt_user_prefs where project_id = p_project_id;      

    delete from bt_projects where project_id = p_project_id;   

    return 0;
end;
' language 'plpgsql';

create or replace function bt_project__keywords_delete(
    integer,                 -- project_id
    bool                     -- delete_root_p
) returns integer
as '
declare
    p_project_id          alias for $1;
    p_delete_root_p       alias for $1;
    v_root_keyword_id     integer;
    rec                   record;
begin
    -- get the content folder for this instance
    select root_keyword_id
    into   v_root_keyword_id
    from   bt_projects
    where  project_id = p_project_id;

    -- if we are deleting the root, remove it from the project as well
    if p_delete_root_p = 1 then
        update bt_projects 
        set    root_keyword_id = null 
        where  project_id = p_project_id;
    end if;

    -- delete the projects keywords
    for rec in 
        select k2.keyword_id
        from   cr_keywords k1, cr_keywords k2
        where  k1.keyword_id = v_root_keyword_id
        and    k2.tree_sortkey between k1.tree_sortkey and tree_right(k1.tree_sortkey)
        order  by length(k2.tree_sortkey) desc
    loop
        if (p_delete_root_p = 1) or (rec.keyword_id != v_root_keyword_id) then
            perform content_keyword__delete(rec.keyword_id);
        end if;
    end loop;

    return 0;
end;
' language 'plpgsql';


create table bt_versions (
  version_id                    integer not null
                                constraint bt_versions_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_versions_projects_fk
                                references bt_projects(project_id),
  -- Like apm_package_versions.version_name
  -- But can also be a human-readable name like "Future", "Milestone 3", etc.
  version_name                  varchar(500) not null,
  description                   text,
  anticipated_freeze_date       date,
  actual_freeze_date            date,
  anticipated_release_date      date,
  actual_release_date           date,
  maintainer                    integer 
                                constraint bt_versions_maintainer_fk
                                references users(user_id),
  supported_platforms           varchar(1000),
  active_version_p              char(1) not null
                                constraint bt_versions_active_version_p_ck
                                check (active_version_p in ('t','f'))
                                default 'f',
  -- Can we assign bugs to be fixed for this version?
  assignable_p                  char(1)
                                constraint bt_versions_assignable_p_ck
                                check (assignable_p in ('t','f'))
);

-- should probably have a trigger to ensure that there's only one active version.

-- but we just make a stored function that alters the active version

create or replace function bt_version__set_active (
   integer                       -- active_version_id
) returns integer 
as '
declare
    new__active_version_id alias for $1;
    v_project_id integer;
begin
    select project_id
    into   v_project_id
    from   bt_versions 
    where  version_id = new__active_version_id;

    if found then
        update bt_versions set active_version_p=''f'' where project_id = v_project_id;
    end if;
    update bt_versions set active_version_p=''t'' where version_id = new__active_version_id;
    return 0;
end;
' language 'plpgsql';

create table bt_components (
  component_id                  integer not null
                                constraint bt_components_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_components_projects_fk 
                                references bt_projects(project_id),
  component_name                varchar(500) not null,
  description                   text,
  -- This is what the component can be referred to in the URL
  url_name                      text,
  -- a component can be without maintainer, in which case we just default to the project maintainer
  maintainer                    integer 
                                constraint bt_components_maintainer_fk
                                references users(user_id)
);

-- default keywords per keyword parent
-- e.g. default priority, default severity, etc.

create table bt_default_keywords (
  project_id                    integer not null
                                constraint bt_default_keywords_project_fk
                                references bt_projects(project_id)
                                on delete cascade,
  parent_id                     integer not null
                                constraint bt_default_keyw_parent_keyw_fk
                                references cr_keywords(keyword_id)
                                on delete cascade,
  keyword_id                    integer not null
                                constraint bt_default_keyw_keyword_fk
                                references cr_keywords(keyword_id)
                                on delete cascade,
  constraint bt_default_keywords_prj_par_un
  unique (project_id, parent_id)
);

create index bt_default_keyw_parent_id_idx on bt_default_keywords(parent_id);
create index bt_default_keyw_keyword_id_idx on bt_default_keywords(keyword_id);

-- content_item subtype
create table bt_bugs(
  bug_id                        integer
                                constraint bt_bug_pk
                                primary key
                                constraint bt_bug_bt_bug_fk
                                references cr_items(item_id)
                                on delete cascade,
  -- this is the only column we really add here
  bug_number                    integer,
  -- the comment from the initial action
  -- denormalized from a far-fetched workflow join
  comment_content               text,
  comment_format                varchar(200),
  -- denormalized from cr_items
  parent_id                     integer,
  live_revision_id              integer,
  -- denormalized from cr_revisions.title
  summary                       varchar(1000),
  -- denormalized from bt_projects
  project_id                    integer,
  -- denormalized from bt_bug_revisions
  component_id                  integer,
  resolution                    varchar(50),
  user_agent                    varchar(500),
  found_in_version              integer,
  fix_for_version               integer,
  fixed_in_version              integer,
  -- denormalized from acs_objects
  creation_date                 timestamptz,
  creation_user                 integer,
  -- constraint
  constraint bt_bug_parent_id_bug_number_un
  unique (parent_id, bug_number)
);

-- LARS:
-- we need to figure out which ones of these will be used by the query optimizer

create index bt_bugs_proj_id_bug_number_idx on bt_bugs(project_id, bug_number);
create index bt_bugs_bug_number_idx on bt_bugs(bug_number);

create index bt_bugs_proj_id_fix_for_idx on bt_bugs(project_id, fix_for_version);
create index bt_bugs_fix_for_version_idx on bt_bugs(fix_for_version);

create index bt_bugs_proj_id_crea_date_idx on bt_bugs(project_id, creation_date);
create index bt_bugs_creation_date_idx on bt_bugs(creation_date);

-- Create the bug content item object type

select acs_object_type__create_type (
    'bt_bug',
    'Bug',
    'Bugs',
    'acs_object',
    'bt_bugs',
    'bug_id',
    null,
    'f',
    null,
    null
);


-- content_revision specialization
create table bt_bug_revisions (
  bug_revision_id               integer 
                                constraint bt_bug_rev_pk
                                primary key
                                constraint bt_bug_rev_bug_id_fk
                                references cr_revisions(revision_id)
                                on delete cascade,
  component_id                  integer 
                                constraint bt_bug_rev_components_fk
                                references bt_components(component_id),
  resolution                    varchar(50)
                                constraint bt_bug_rev_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro','needinfo')),
  user_agent                    varchar(500),
  found_in_version              integer
                                constraint bt_bug_rev_found_in_version_fk   
                                references bt_versions(version_id), 
  fix_for_version               integer
                                constraint bt_bug_rev_fix_for_version_fk   
                                references bt_versions(version_id), 
  fixed_in_version              integer
                                constraint bt_bug_rev_fixed_in_version_fk   
                                references bt_versions(version_id)
);

-- Create the bug revision content type

select content_type__create_type (
    'bt_bug_revision',
    'content_revision',
    'Bug Revision',
    'Bug Revisions',
    'btbug_revisions',
    'bug_revision_id',
    'content_revision.revision_name'
);

select define_function_args ('bt_bug__new','bug_id,bug_number,package_id,component_id,found_in_version,summary,user_agent,comment_content,comment_formt,creation_date,creation_user,creation_ip,fix_for_version,item_subtype;bt_bug,content_type;bt_bug_revision');

create or replace function bt_bug__new(
    integer,     -- bug_id
    integer,     -- bug_number
    integer,     -- package_id
    integer,     -- component_id
    integer,     -- found_in_version
    varchar,     -- summary
    varchar,     -- user_agent
    text,        -- comment_content
    varchar,     -- comment_format
    timestamptz, -- creation_date
    integer,     -- creation_user
    varchar,     -- creation_ip
    integer,	-- fix_for_version	 
    varchar,     -- item_subtype
    varchar      -- content_type
) returns int
as '
declare
    p_bug_id                    alias for $1;
    p_bug_number                alias for $2;
    p_package_id                alias for $3;
    p_component_id              alias for $4;
    p_found_in_version          alias for $5;
    p_summary                   alias for $6;
    p_user_agent                alias for $7;
    p_comment_content           alias for $8;
    p_comment_format            alias for $9;
    p_creation_date             alias for $10;
    p_creation_user             alias for $11;
    p_creation_ip               alias for $12;
    p_fix_for_version		alias for $13;
    p_item_subtype              alias for $14;	
    p_content_type              alias for $15;
    
    v_bug_id                    integer;
    v_revision_id               integer;
    v_bug_number                integer;
    v_folder_id                 integer;
begin
    -- get the content folder for this instance
    select folder_id
    into   v_folder_id
    from   bt_projects
    where  project_id = p_package_id;

    -- get bug_number
    if p_bug_number is null then
      select coalesce(max(bug_number),0) + 1
      into   v_bug_number
      from   bt_bugs
      where  parent_id = v_folder_id;
    else
      v_bug_number := p_bug_number;
    end if;

    -- create the content item
    v_bug_id := content_item__new(
        v_bug_number::varchar,     -- name
        v_folder_id,               -- parent_id
        p_bug_id,                  -- item_id
        null,                      -- locale        
        p_creation_date,           -- creation_date
        p_creation_user,           -- creation_user
        v_folder_id,               -- context_id
        p_creation_ip,             -- creation_ip
        p_item_subtype,            -- item_subtype
        p_content_type,            -- content_type
        null,                      -- title
        null,                      -- description
        null,                      -- mime_type
        null,                      -- nls_language
        null                       -- data
    );

    -- create the item type row
    insert into bt_bugs
        (bug_id, bug_number, comment_content, comment_format, parent_id, project_id, creation_date, creation_user, fix_for_version)
    values
        (v_bug_id, v_bug_number, p_comment_content, p_comment_format, v_folder_id, p_package_id, p_creation_date, p_creation_user, p_fix_for_version);

    -- create the initial revision
    v_revision_id := bt_bug_revision__new(
        null,                      -- bug_revision_id
        v_bug_id,                  -- bug_id
        p_component_id,            -- component_id
        p_found_in_version,        -- found_in_version
        p_fix_for_version,         -- fix_for_version
        null,                      -- fixed_in_version
        null,                      -- resolution
        p_user_agent,              -- user_agent
        p_summary,                 -- summary
        p_creation_date,           -- creation_date
        p_creation_user,           -- creation_user
        p_creation_ip             -- creation_ip
    );

    return v_bug_id;
end;
' language 'plpgsql';


create or replace function bt_bug__delete(
   integer                      -- bug_id
) returns integer
as '
declare
    p_bug_id                    alias for $1;
    v_case_id                   integer;
    rec                         record;
begin
    -- Every bug is associated with a workflow case
    select case_id 
    into   v_case_id 
    from   workflow_cases 
    where  object_id = p_bug_id;

    perform workflow_case_pkg__delete(v_case_id);

    -- Every bug may have notifications attached to it
    -- and there is one column in the notificaitons datamodel that doesn''t
    -- cascade
    for rec in select notification_id from notifications 
               where response_id = p_bug_id loop

        perform notification__delete (rec.notification_id);
    end loop;

    -- unset live & latest revision
--    update cr_items
--    set    live_revision = null,
--           latest_revision = null
--    where  item_id = p_bug_id;

    perform content_item__delete(p_bug_id);

    return 0;
end;
' language 'plpgsql';




create or replace function bt_bug_revision__new(
    integer,        -- bug_revision_id
    integer,        -- bug_id
    integer,        -- component_id
    integer,        -- found_in_version
    integer,        -- fix_for_version
    integer,        -- fixed_in_version
    varchar,        -- resolution
    varchar,        -- user_agent
    varchar,        -- summary
    timestamptz,    -- creation_date
    integer,        -- creation_user
    varchar        -- creation_ip
) returns int
as '
declare
    p_bug_revision_id       alias for $1;
    p_bug_id                alias for $2;
    p_component_id          alias for $3;
    p_found_in_version      alias for $4;
    p_fix_for_version       alias for $5;
    p_fixed_in_version      alias for $6;
    p_resolution            alias for $7;
    p_user_agent            alias for $8;
    p_summary               alias for $9;
    p_creation_date         alias for $10;
    p_creation_user         alias for $11;
    p_creation_ip           alias for $12;

    v_revision_id               integer;
begin
    -- create the initial revision
    v_revision_id := content_revision__new(
        p_summary,              -- title
        null,                   -- description
        current_timestamp,      -- publish_date
        null,                   -- mime_type
        null,                   -- nls_language        
        null,                   -- new_data
        p_bug_id,               -- item_id
        p_bug_revision_id,      -- revision_id
        p_creation_date,        -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip           -- creation_ip
    );

    -- insert into the bug-specific revision table
    insert into bt_bug_revisions 
        (bug_revision_id, component_id, resolution, user_agent, found_in_version, fix_for_version, fixed_in_version)
    values
        (v_revision_id, p_component_id, p_resolution, p_user_agent, p_found_in_version, p_fix_for_version, p_fixed_in_version);

    -- make this revision live
    PERFORM content_item__set_live_revision(v_revision_id);

    -- update the cache
    update bt_bugs
    set    live_revision_id = v_revision_id,
           summary = p_summary,
           component_id = p_component_id,
           resolution = p_resolution,
           user_agent = p_user_agent,
           found_in_version = p_found_in_version,
           fix_for_version = p_fix_for_version,
           fixed_in_version = p_fixed_in_version
    where  bug_id = p_bug_id;

    return v_revision_id;
end;
' language 'plpgsql';




create table bt_user_prefs (
  user_id                       integer not null
                                constraint bt_user_prefs_user_id_fk
                                references users(user_id),
  project_id                    integer not null
                                constraint bt_user_prefs_project_fk
                                references bt_projects(project_id),
  user_version                  integer
                                constraint bt_user_prefs_current_version_fk
                                references bt_versions(version_id),
  constraint bt_user_prefs_pk
  primary key (user_id, project_id)
);


create table bt_patches (
  patch_id                 integer 
                           constraint bt_patches_pk
                           primary key
                           constraint bt_patches_pid_fk
                           references acs_objects(object_id),
  patch_number             integer not null,
  project_id               integer
                           constraint bt_patches_projects_fk
                           references bt_projects(project_id),
  component_id             integer
                           constraint bt_patches_components_fk
                           references bt_components(component_id),
  summary                  text,
  content                  text,
  generated_from_version   integer
                           constraint bt_patches_vid_fk
                           references bt_versions(version_id),
  apply_to_version         integer
                           constraint bt_patchs_apply_to_version_fk   
                           references bt_versions(version_id), 
  applied_to_version       integer
                           constraint bt_patchs_applied_to_version_fk   
                           references bt_versions(version_id), 
  status                   varchar(50) not null
                           constraint bt_patchs_status_ck
                           check (status in ('open', 'accepted', 'refused', 'deleted'))
                           default 'open',
  constraint bt_patches_un
  unique(patch_number, project_id)
);

create table bt_patch_actions (
  action_id                integer not null
                           constraint bt_patch_actions_pk
                           primary key,
  patch_id                 integer not null
                           constraint bt_patch_actions_patch_fk
                           references bt_patches(patch_id)
                           on delete cascade,
  action                   varchar(50)
                           constraint bt_patch_actions_action_ck
                           check (action in ('open', 'edit', 'comment', 'accept', 
                                             'reopen', 'refuse', 'delete')) 
                           default 'open',
  actor                    integer not null
                           constraint bt_patch_actions_actor_fk
                           references users(user_id),
  action_date              timestamptz not null
                           default current_timestamp,
  comment_text             text,
  comment_format           varchar(30) default 'plain' not null
                           constraint  bt_patch_actions_comment_format_ck
                           check (comment_format in ('html', 'plain', 'pre'))
);

-- Create the bt_patch object type
select acs_object_type__create_type (
    'bt_patch',
    'Patch',
    'Patches',
    'acs_object',
    'bt_patches',
    'patch_id',
    null,
    'f',
    null,
    'bt_patch__name'
);


create or replace function bt_patch__new(
    integer,     -- patch_id
    integer,     -- project_id
    integer,     -- component_id
    text,        -- summary
    text,        -- description
    text,        -- description_format
    text,        -- content
    integer,     -- generated_from_version
    integer,     -- creation_user
    varchar      -- creation_ip
) returns int
as '
declare
    p_patch_id                    alias for $1;
    p_project_id                  alias for $2;
    p_component_id                alias for $3;
    p_summary                     alias for $4;
    p_description                 alias for $5;
    p_description_format          alias for $6;
    p_content                     alias for $7;
    p_generated_from_version      alias for $8;
    p_creation_user               alias for $9;
    p_creation_ip                 alias for $10;

    v_patch_id                    integer;
    v_patch_number                integer;
    v_action_id                 integer;
begin

    v_patch_id := acs_object__new(
        p_patch_id,             -- object_id
        ''bt_patch'',           -- object_type
        current_timestamp,      -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip,          -- creation_ip
        p_project_id,           -- context_id
        ''t''                   -- security_inherit_p
    );

    select coalesce(max(patch_number),0) + 1
    into   v_patch_number
    from   bt_patches
    where  project_id = p_project_id;

    insert into bt_patches
        (patch_id, 
         project_id, 
         component_id, 
         summary, 
         content, 
         generated_from_version,
         patch_number)
    values
        (v_patch_id, 
         p_project_id, 
         p_component_id, 
         p_summary, 
         p_content, 
         p_generated_from_version,
         v_patch_number);

    select nextval(''t_acs_object_id_seq'') 
    into   v_action_id;

    insert into bt_patch_actions
        (action_id, patch_id, action, actor, comment_text, comment_format)
     values
        (v_action_id, v_patch_id, ''open'', p_creation_user, p_description, p_description_format);

    return v_patch_id;
end;
' language 'plpgsql';

create or replace function bt_patch__name(
   integer                      -- patch_id
) returns varchar
as '
declare
   p_patch_id                 alias for $1;
   v_name                     varchar;
begin
   select summary
   into   v_name
   from   bt_patches
   where  patch_id = p_patch_id;

   return v_name;
end;
' language 'plpgsql';

create or replace function bt_patch__delete(
   integer                      -- patch_id
) returns integer
as '
declare
    p_patch_id              alias for $1;
begin
    perform acs_object__delete(p_patch_id);

    return 0;
end;
' language 'plpgsql';

-- There is a many to many relationship between patches and bugs
create table bt_patch_bug_map (
  patch_id            integer not null
                      constraint bt_patch_bug_map_pid_fk
                      references bt_patches(patch_id)
                      on delete cascade,
  bug_id              integer not null
                      constraint bt_patch_bug_map_bid_fk
                      references cr_items(item_id)
                      on delete cascade,
  constraint bt_patch_bug_map_un
  unique (patch_id, bug_id)
);

create index bt_patch_bug_map_patch_id_idx on bt_patch_bug_map(patch_id);
create index bt_patch_bug_map_bug_id_idx on bt_patch_bug_map(bug_id);

