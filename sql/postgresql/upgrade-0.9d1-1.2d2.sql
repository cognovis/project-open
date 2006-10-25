-- Upgrade script that converts the Bug Tracker to using the workflow package and the Content Repository
-- for its bugs.
--
-- @author Lars Pind
-- @author Peter Marklund
-- @creation-date 2003-02-13

---- *******
---- ******* Workflow Upgrade START

-- Prior to this sql script being sourced it is assumed that the before-upgrade Tcl callback
-- has setup worklfow instances for the Bug Tracker package type and for all package instances

-- First move all workflow data for each bug into the workflow data model
-- temporary table to map bug tracker comment format to CR mime types
create table temp_format_mime_map (
        format text,    
        mime_type text);
insert into temp_format_mime_map (format, mime_type) values ('html', 'text/html');
insert into temp_format_mime_map (format, mime_type) values ('plain', 'text/plain');
insert into temp_format_mime_map (format, mime_type) values ('pre', 'text/fixed-width');

create or replace function inline_0 ()
returns integer as '
declare
  -- Package_id loop
  project_rec           record;
  v_workflow_id         integer;
  v_open_action_id      integer;

  -- Bug loop vars
  bug_rec               record;
  v_case_id             integer;
  v_assignee_role_id    integer;
  v_submitter_role_id   integer;
  v_current_state_id    integer;  

  -- Action loop vars
  action_rec            record;
  v_entry_id            integer;
  v_action_id           integer;
  v_mime_type           text;
begin
  for project_rec in select project_id from bt_projects
  loop
  
    -- Get the bug workflow id
    select workflow_id into v_workflow_id 
        from workflows 
        where short_name = ''bug''
        and object_id = project_rec.project_id;

    if v_workflow_id is null then
        raise EXCEPTION ''You must define the workflow before running this upgade script. The workflow is created by the APM Tcl callbacks.'';
    end if;

    select action_id into v_open_action_id 
          from workflow_actions
          where workflow_id = v_workflow_id
            and short_name = ''open'';

    for bug_rec in select b.bug_id, 
                          b.status, 
                          b.resolution, 
                          b.assignee, 
                          o.creation_user, 
                          o.creation_date
                   from bt_bugs b, acs_objects o
                   where b.bug_id = o.object_id
                     and b.project_id = project_rec.project_id
    loop
          -- Create the case
          select nextval(''workflow_cases_seq'') into v_case_id;
          insert into workflow_cases (case_id, workflow_id, object_id)
              values (v_case_id, v_workflow_id, bug_rec.bug_id);

          -- Insert the submitter
          select role_id into v_submitter_role_id 
            from workflow_roles 
            where short_name = ''submitter''
              and workflow_id = v_workflow_id;
          insert into workflow_case_role_party_map (case_id, role_id, party_id)
              values (v_case_id, v_submitter_role_id, bug_rec.creation_user);

          -- Insert the assignee
          if bug_rec.assignee is not null then
            select role_id into v_assignee_role_id 
              from workflow_roles 
              where short_name = ''assignee''
                and workflow_id = v_workflow_id;
            insert into workflow_case_role_party_map (case_id, role_id, party_id)
              values (v_case_id, v_assignee_role_id, bug_rec.assignee);
          end if;

          -- Set the current state
          select state_id into v_current_state_id 
            from workflow_fsm_states
            where short_name = bug_rec.status
              and workflow_id = v_workflow_id;
          insert into workflow_case_fsm (case_id, current_state)
                  values (v_case_id, v_current_state_id);

          for action_rec in select action, 
                                   resolution,
                                   actor, 
                                   action_date, 
                                   comment, 
                                   comment_format
                            from bt_bug_actions
                            where bug_id = bug_rec.bug_id
          loop
              select action_id into v_action_id
                from workflow_actions
                where workflow_id = v_workflow_id
                  and short_name = action_rec.action;

              select mime_type into v_mime_type
                 from temp_format_mime_map
                 where format = action_rec.comment_format;

              -- Create the case log entry
              v_entry_id := workflow_case_log_entry__new (
                                      null,            
                                      ''workflow_case_log_entry'',
                                      v_case_id,
                                      v_action_id,
                                      action_rec.comment,
                                      v_mime_type,
                                      action_rec.actor,
                                      null);

              -- Update the creation date of the case log entry
              update acs_objects set creation_date = action_rec.action_date
                 where object_id = v_entry_id;
 
              -- If this is a resolve action - add the resolution code
              if action_rec.action = ''resolve'' then
                  insert into workflow_case_log_data (entry_id, key, value)
                          values (v_entry_id, ''resolution'', bug_rec.resolution);
              end if;
          end loop;
           
    end loop;
      
  end loop;

  return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();
drop table temp_format_mime_map;

-- remove the bug-tracker notifications stuff completely
create function inline_0 ()
 returns integer as '
 declare
     v_old_notification_type_id      integer;
     v_new_notification_type_id      integer;
     row                             record;
 begin
     -- change bug_tracker_project_notif to workflow
     select type_id
     into   v_old_notification_type_id
     from   notification_types 
     where  short_name = ''bug_tracker_project_notif'';
     
     select type_id
     into   v_new_notification_type_id
     from   notification_types 
     where  short_name = ''workflow'';

     update notification_requests set type_id = v_new_notification_type_id where type_id = v_old_notification_type_id;
     
     -- change bug_tracker_bug_notif to workflow_case
     select type_id
     into   v_old_notification_type_id
     from   notification_types 
     where  short_name = ''bug_tracker_bug_notif'';
     
     select type_id
     into   v_new_notification_type_id
     from   notification_types 
     where  short_name = ''workflow_case'';

     update notification_requests set type_id = v_new_notification_type_id where type_id = v_old_notification_type_id;
     
     for row in select nt.type_id
                from notification_types nt
                where nt.short_name in (''bug_tracker_project_notif'', ''bug_tracker_bug_notif'')
     loop
         perform notification_type__delete(row.type_id);
         delete from notifications where type_id = row.type_id;
         delete from notification_types where type_id = row.type_id;
         delete from notification_types_intervals where type_id = row.type_id;
         delete from notification_types_del_methods where type_id = row.type_id;
     end loop;

     return null;
 end;' language 'plpgsql';
select inline_0();
drop function inline_0 ();

-- Delete the service contract data
create function bt_service_contract_delete(varchar,varchar)
returns integer as '
declare
        p_impl_name             alias for $1;
        p_impl_short_name       alias for $2;
        impl_id integer;
        v_foo   integer;
begin        

        -- the notification type impl
        impl_id := acs_sc_impl__get_id (
                      ''NotificationType'',		-- impl_contract_name
                      p_impl_name	-- impl_name
        );

        PERFORM acs_sc_binding__delete (
                    ''NotificationType'',
                    p_impl_name
        );

        v_foo := acs_sc_impl_alias__delete (
                    ''NotificationType'',		-- impl_contract_name	
                    p_impl_name,	-- impl_name
                    ''GetURL''				-- impl_operation_name
        );

        v_foo := acs_sc_impl_alias__delete (
                    ''NotificationType'',		-- impl_contract_name	
                    p_impl_name,                        -- impl_name
                    ''ProcessReply''			-- impl_operation_name
        );

    return 0;
end;
' language 'plpgsql';

-- Drop bug tracker notifications. They are now taken care of by the workflow package
select bt_service_contract_delete('bug_tracker_project_notif_type','bug_tracker_project_notif');
select bt_service_contract_delete('bug_tracker_bug_notif_type','bug_tracker_bug_notif');
drop function bt_service_contract_delete(varchar,varchar);

-- Changed column names
-- comment is a reserved word in Oracle 
alter table bt_patch_actions rename column comment to comment_text;

-- Drop sequences not used
drop view bt_bug_number_seq;
drop sequence t_bt_bug_number_seq;
drop view bt_patch_number_seq;
drop sequence t_bt_patch_number_seq;

-- Drop tables no longer used
drop table bt_bug_actions; 

-- Drop functions not needed anymore
drop function bt_component__default_assignee(
   integer                      -- component_id
);
drop function bt_bug__status_sort_order(
    varchar                     -- status
);


-- *******
-- ******* CR Upgrade START

-- ******* First move away data from changed tables into temporary tables
create table project_temp as select * from bt_projects;
drop table bt_projects;

create table bt_bugs_temp as select * from bt_bugs;
drop table bt_bugs;


-- ******* START create new tables, indices, and functions

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
        content_item_globals.c_root_folder_id  -- parent_bi
    );

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

-- versions and components haven't changed...

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
  creation_date                 timestamp,
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

-- Update the bug content item object type
update acs_object_types set name_method = null where object_type = 'bt_bug';


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

select define_function_args ('bt_bug__new','bug_id,bug_number,package_id,component_id,found_in_version,summary,user_agent,comment_content,comment_formt,creation_date,creation_user,creation_ip,item_subtype;bt_bug,content_type;bt_bug_revision');

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
    timestamp,   -- creation_date
    integer,     -- creation_user
    varchar,     -- creation_ip
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
    p_item_subtype              alias for $13;
    p_content_type              alias for $14;

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
    v_bug_id := content_item__new_temp(
        v_bug_number,              -- name
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
        (bug_id, bug_number, comment_content, comment_format, parent_id, project_id, creation_date, creation_user)
    values
        (v_bug_id, v_bug_number, p_comment_content, p_comment_format, v_folder_id, p_package_id, p_creation_date, p_creation_user);

    -- create the initial revision
    v_revision_id := bt_bug_revision__new(
        null,                      -- bug_revision_id
        v_bug_id,                  -- bug_id
        p_component_id,            -- component_id
        p_found_in_version,        -- found_in_version
        null,                      -- fix_for_version
        null,                      -- fixed_in_version
        null,                      -- resolution
        p_user_agent,              -- user_agent
        p_summary,                 -- summary
        p_creation_date,           -- creation_date
        p_creation_user,           -- creation_user
        p_creation_ip              -- creation_ip
    );

    return v_bug_id;
end;
' language 'plpgsql';

-- A temporary modified version that doesn't create an acs_object
create or replace function content_item__new_temp (varchar,integer,integer,varchar,timestamp with time zone,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
  new__text                   alias for $15; -- default null
  new__storage_type           alias for $16; -- check in (''text'',''file'')
--  relation_tag                alias for $17; 
--  is_live                     alias for $18; 
  new__relation_tag           varchar default null;
  new__is_live                boolean default ''f'';

  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

  -- place the item in the context of the pages folder if no
  -- context specified 

  if new__parent_id is null then
    v_parent_id := content_item_globals.c_root_folder_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- Determine context_id
  if new__context_id is null then
    v_context_id := v_parent_id;
  else
    v_context_id := new__context_id;
  end if;

  if v_parent_id = 0 or 
    content_folder__is_folder(v_parent_id) = ''t'' then

    if v_parent_id != 0 and 
      content_folder__is_registered(
        v_parent_id, new__content_type, ''f'') = ''f'' then

      raise EXCEPTION ''-20000: This items content type % is not registered to this folder %'', new__content_type, v_parent_id;
    end if;

  else if v_parent_id != 0 then

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
	content_item__is_valid_child(v_parent_id, new__content_type) = ''f'' then

       raise EXCEPTION ''-20000: This items content type % is not allowed in this container %'', new__content_type, v_parent_id;
     end if;

  end if; end if;

  -- Create the object
  -- No, during upgrade the acs object is already created so skip this step
  v_item_id := new__item_id;   
--   v_item_id := acs_object__new(
--       new__item_id,
--       new__item_subtype, 
--       new__creation_date, 
--       new__creation_user, 
--       new__creation_ip, 
--       v_context_id
--   );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != 0 and
    content_folder__is_folder(v_parent_id) = ''f'' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = ''t'' then

    v_rel_id := acs_object__new(
      null,
      ''cr_item_child_rel'',
      now(),
      null,
      null,
      v_parent_id
    );

    if new__relation_tag is null then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || ''-'' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  -- use the name of the item if no title is supplied
  if new__title is null then
    v_title := new__name;
  else
    v_title := new__title;
  end if;

  if new__title is not null or 
     new__text is not null then

    v_revision_id := content_revision__new(
	v_title,
	new__description,
        now(),
	new__mime_type,
        null,
	new__text,
	v_item_id,
        null,
        new__creation_date, 
        new__creation_user, 
        new__creation_ip
    );

  end if;

  -- make the revision live if is_live is true
  if new__is_live = ''t'' then
    PERFORM content_item__set_live_revision(v_revision_id);
  end if;

  return v_item_id;
 
end;' language 'plpgsql';

-- A temporary modified version that doesn't create an acs_object
create function content_item__new_temp (varchar,integer,integer,varchar,timestamp with time zone,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
-- changed to integer for blob_id
  new__data                   alias for $15; -- default null
--  relation_tag                alias for $17; 
--  is_live                     alias for $18; 
  new__relation_tag           varchar default null;
  new__is_live                boolean default ''f'';

  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

  -- place the item in the context of the pages folder if no
  -- context specified 

  if new__parent_id is null then
    v_parent_id := content_item_globals.c_root_folder_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- Determine context_id
  if new__context_id is null then
    v_context_id := v_parent_id;
  else
    v_context_id := new__context_id;
  end if;

  if v_parent_id = 0 or 
    content_folder__is_folder(v_parent_id) = ''t'' then

    if v_parent_id != 0 and 
      content_folder__is_registered(
        v_parent_id, new__content_type, ''f'') = ''f'' then

      raise EXCEPTION ''-20000: This items content type % is not registered to this folder %'', new__content_type, v_parent_id;
    end if;

  else if v_parent_id != 0 then

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
	content_item__is_valid_child(v_parent_id, new__content_type) = ''f'' then

       raise EXCEPTION ''-20000: This items content type % is not allowed in this container %'', new__content_type, v_parent_id;
     end if;

  end if; end if;

  -- Create the object
  v_item_id := new__item_id;
--   v_item_id := acs_object__new(
--       new__item_id,
--       new__item_subtype, 
--       new__creation_date, 
--       new__creation_user, 
--       new__creation_ip, 
--       v_context_id
--   );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, ''lob''
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != 0 and
    content_folder__is_folder(v_parent_id) = ''f'' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = ''t'' then

    v_rel_id := acs_object__new(
      null,
      ''cr_item_child_rel'',
      now(),
      null,
      null,
      v_parent_id
    );

    if new__relation_tag is null or new__relation_tag = '''' then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || ''-'' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  -- use the name of the item if no title is supplied
  if new__title is null or new__title = '''' then
    v_title := new__name;
  else
    v_title := new__title;
  end if;

  -- create the revision if data or title or text is not null
  -- note that the caller could theoretically specify both text
  -- and data, in which case the text is ignored.

  if new__data is not null then

    v_revision_id := content_revision__new(
	v_title,
	new__description,
        now(),
	new__mime_type,
	new__nls_language,
	new__data,
        v_item_id,
        null,
        new__creation_date, 
        new__creation_user, 
        new__creation_ip
        );

  end if;

  -- make the revision live if is_live is true
  if new__is_live = ''t'' then
    PERFORM content_item__set_live_revision(v_revision_id);
  end if;

  return v_item_id;
 
end;' language 'plpgsql';

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

    perform workflow_case__delete(v_case_id);

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
    timestamp,      -- creation_date
    integer,        -- creation_user
    varchar         -- creation_ip
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
        now(),                  -- publish_date
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

-- ******* END create new tables, indices, and functions

-- ******* Recreate the project data
create or replace function inline_0 ()
returns integer as '
declare
  project_rec           record;
begin
  for project_rec in select project_id,
                            description,
                            email_subject_name,
                            maintainer 
        from project_temp
  loop

    perform bt_project__new (
        project_rec.project_id        
    );                

    update bt_projects set description = project_rec.description, 
                           email_subject_name = project_rec.email_subject_name, 
                           maintainer = project_rec.maintainer
        where project_id = project_rec.project_id;

  end loop;

  return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

-- ******* Migrate the severiy and priority codes to CR keywords
create table code_keyword_map_temp (
   code_id      integer,
   -- for bt_priority_codes or bt_severity_codes
   keyword_id   integer
                references cr_keywords
);

-- ******* Migrate bug type to CR keywords
create table bug_type_keyword_map_temp (
   project_id   integer,
   bug_type     varchar,
   keyword_id   integer
                references cr_keywords
);

create or replace function inline_0 ()
returns integer as '
declare
    project_rec            record;

    v_keyword_id           integer;
    v_severity_root        integer;
    severity_rec           record;
    v_priority_root        integer;
    priority_rec           record;
    v_bug_type_root        integer;
begin
    for project_rec in 
        select project_id, root_keyword_id 
        from   bt_projects
    loop

        -- Create the severity root keyword
        v_severity_root := content_keyword__new (
            ''Severity'',
            null,  
            project_rec.root_keyword_id,
            null,
            null,
            null,
            null,
            ''content_keyword''             -- object_type
        );      

        for severity_rec in 
            select severity_id,
                   severity_name,
                   sort_order
            from   bt_severity_codes
            where  project_id = project_rec.project_id
            order  by sort_order
        loop

            v_keyword_id := content_keyword__new (
                severity_rec.sort_order || '' - '' || severity_rec.severity_name,
                null,
                v_severity_root,
                null,
                null,
                null,
                null,
                ''content_keyword''             -- object_type
            );      

            insert into code_keyword_map_temp (code_id, keyword_id)
                 values (severity_rec.severity_id, v_keyword_id);
      
        end loop;

        -- Create the priority code root
        v_priority_root := content_keyword__new (
            ''Priority'',
            null,  
            project_rec.root_keyword_id,
            null,
            null,
            null,
            null,
            ''content_keyword''             -- object_type
        );

        for priority_rec in 
            select priority_id,
                   priority_name,
                   sort_order
            from   bt_priority_codes
            where  project_id = project_rec.project_id
            order  by sort_order
        loop

            v_keyword_id := content_keyword__new (
                priority_rec.sort_order || '' - '' || priority_rec.priority_name,
                null,
                v_priority_root,
                null,
                null,
                null,
                null,
              ''content_keyword''             -- object_type
            );      

            insert into code_keyword_map_temp (code_id, keyword_id)
                 values (priority_rec.priority_id, v_keyword_id);
        end loop;

        -- Create the bug type root
        v_bug_type_root := content_keyword__new (
            ''Bug Type'',
            null,  
            project_rec.root_keyword_id,
            null,
            null,
            null,
            null,
            ''content_keyword''             -- object_type
        );


        -- Bug Type: Bug
        v_keyword_id := content_keyword__new (
            ''Bug'',
            null,
            v_bug_type_root,
            null,
            null,
            null,
            null,
          ''content_keyword''             -- object_type
        );      

        insert into bug_type_keyword_map_temp (project_id, bug_type, keyword_id)
             values (project_rec.project_id, ''bug'', v_keyword_id);
    
        -- Bug Type: Suggestion
        v_keyword_id := content_keyword__new (
            ''Suggestion'',
            null,
            v_bug_type_root,
            null,
            null,
            null,
            null,
          ''content_keyword''             -- object_type
        );      

        insert into bug_type_keyword_map_temp (project_id, bug_type, keyword_id)
             values (project_rec.project_id, ''suggestion'', v_keyword_id);
    
        -- Bug Type: Todo
        v_keyword_id := content_keyword__new (
            ''Todo'',
            null,
            v_bug_type_root,
            null,
            null,
            null,
            null,
          ''content_keyword''             -- object_type
        );      

        insert into bug_type_keyword_map_temp (project_id, bug_type, keyword_id)
             values (project_rec.project_id, ''todo'', v_keyword_id);
    
    
    end loop;  

    return 0;    
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


-- ******* START Bug upgrade
-- Create each of the bugs with the new API that creates a content
-- item, an initial revision, and populates the bt_bugs denormalization table
create or replace function inline_0 ()
returns integer as '
declare
  -- Project loop
  project_rec           record;
  v_workflow_id         integer;
  v_open_action_id      integer;

  -- Bug loop
  bug_rec               record;
  notifications_rec     record;
  v_state_id            integer;
  v_item_id             integer;
  v_new_bug_id          integer;
  v_severity_id         integer;
  v_priority_id         integer;
  v_bug_type_id         integer;
  v_bug_revision_id     integer;
begin

  for project_rec in select project_id from bt_projects
  loop

    -- Get the bug workflow id
    select workflow_id into v_workflow_id 
        from workflows 
        where short_name = ''bug''
        and object_id = project_rec.project_id;

    select action_id into v_open_action_id 
          from workflow_actions
          where workflow_id = v_workflow_id
            and short_name = ''open'';


    for bug_rec in select b.bug_id,
                          b.bug_number,
                          b.project_id,
                          b.component_id,
                          b.found_in_version,
                          b.fix_for_version,
                          b.fixed_in_version,
                          b.resolution,
                          b.summary,
                          b.user_agent,
                          b.severity,
                          b.priority,
                          b.bug_type,
                          cr.content,
                          cr.mime_type,
                          o.creation_user, 
                          o.creation_date,
                          o.creation_ip
                   from bt_bugs_temp b, 
                        acs_objects o,
                        workflow_cases c,
                        workflow_case_log wcl,
                        cr_items ci,
                        cr_revisions cr
                   where b.bug_id = o.object_id
                     and b.project_id = project_rec.project_id
                     and b.bug_id = c.object_id
                     and c.workflow_id = v_workflow_id
                     and wcl.case_id = c.case_id
                     and wcl.action_id = v_open_action_id
                     and ci.item_id = wcl.entry_id
                     and cr.revision_id = ci.live_revision
    loop

        -- Use a modified version of bt_bug__new that doesn''t
        -- create a new acs_object
        perform bt_bug__new (
            bug_rec.bug_id,     -- bug_id
            bug_rec.bug_number,     -- bug_number
            bug_rec.project_id,     -- package_id
            bug_rec.component_id,     -- component_id
            bug_rec.found_in_version,     -- found_in_version
            bug_rec.summary,     -- summary
            bug_rec.user_agent,     -- user_agent
            bug_rec.content,        -- comment_content
            bug_rec.mime_type,     -- comment_format
            bug_rec.creation_date,   -- creation_date
            bug_rec.creation_user,     -- creation_user
            bug_rec.creation_ip,     -- creation_ip
            ''bt_bug'',     -- item_subtype
            ''bt_bug_revision''      -- content_type               
        );

        -- Get the revision id
        select live_revision
        into   v_bug_revision_id
        from   cr_items
        where  item_id = bug_rec.bug_id;
        
        -- Update with fix_for_version, fixed_in_version, resolution
        update bt_bug_revisions
        set    fix_for_version = bug_rec.fix_for_version,
               fixed_in_version = bug_rec.fixed_in_version,
               resolution = bug_rec.resolution
        where  bug_revision_id = v_bug_revision_id;

        -- update the cache in the item
        update bt_bugs
        set    fix_for_version = bug_rec.fix_for_version,
               fixed_in_version = bug_rec.fixed_in_version,
               resolution = bug_rec.resolution
        where  bug_id = bug_rec.bug_id;

        -- Map severity
        select keyword_id 
        into   v_severity_id
        from   code_keyword_map_temp
        where  code_id = bug_rec.severity;

        perform content_keyword__item_assign (
            bug_rec.bug_id,
            v_severity_id,
            null,
            bug_rec.creation_user,
            bug_rec.creation_ip
        );

        -- Map priority
        select keyword_id 
        into   v_priority_id
        from   code_keyword_map_temp
        where  code_id = bug_rec.priority;

        perform content_keyword__item_assign (
            bug_rec.bug_id,
            v_priority_id,
            null,
            bug_rec.creation_user,
            bug_rec.creation_ip
        );
        
        -- Map bug type
        select keyword_id
        into   v_bug_type_id
        from   bug_type_keyword_map_temp
        where  project_id = bug_rec.project_id
        and    bug_type = bug_rec.bug_type;

        perform content_keyword__item_assign (
            bug_rec.bug_id,
            v_bug_type_id,
            null,
            bug_rec.creation_user,
            bug_rec.creation_ip
        );
        
    end loop;

  end loop;

  return 0;    
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

-- ******* Drop tables no longer used
drop table bt_severity_codes;
drop table bt_priority_codes;

-- ******* Drop temporary upgrade tables
drop table code_keyword_map_temp;
drop table bug_type_keyword_map_temp;
drop table bt_bugs_temp;
drop table project_temp;

-- ******* Drop temporary upgrade functions
--drop function bt_bug__new_temp(
--    integer,     -- bug_id
--    integer,     -- bug_number
--    integer,     -- package_id
--    integer,     -- component_id
--    integer,     -- found_in_version
--    varchar,     -- summary
--    varchar,     -- user_agent
--    text,        -- comment_content
--    varchar,     -- comment_format
--    timestamp,   -- creation_date
--    integer,     -- creation_user
--    varchar,     -- creation_ip
--    varchar,     -- item_subtype
--    varchar      -- content_type
--);

drop function content_item__new_temp (varchar,integer,integer,varchar,timestamp with time zone,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer);

drop function content_item__new_temp (varchar,integer,integer,varchar,timestamp with time zone,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar);
