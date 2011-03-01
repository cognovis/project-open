-- For stability, URLs contain patch numbers rather than ACS Object ids.
-- This avoids dependence on the ACS kernel and makes upgrades easier.
create sequence t_bt_patch_number_seq;
create view bt_patch_number_seq as
select nextval('t_bt_patch_number_seq') as nextval;

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
       comment                  text,
       comment_format           varchar(30) default 'plain' not null
                                constraint  bt_patch_actions_comment_format_ck
                                check (comment_format in ('html', 'plain', 'pre'))
);

-- Create the bt_patch object type
create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''bt_patch'',
	''Patch'',
	''Patches'',
	''acs_object'',
	''bt_patches'',
	''patch_id'',
	null,
	''f'',
	null,
	''bt_patch__name''
	);

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

create function bt_patch__new(
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
        p_patch_id,               -- object_id
        ''bt_patch'',             -- object_type
        now(),                  -- creation_date
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
        (action_id, patch_id, action, actor, comment, comment_format)
     values
        (v_action_id, v_patch_id, ''open'', p_creation_user, p_description, p_description_format);

    return 0;
end;
' language 'plpgsql';

create function bt_patch__name(
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

create function bt_patch__delete(
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
                           references bt_bugs(bug_id)
                           on delete cascade,
       constraint bt_patch_bug_map_un
       unique (patch_id, bug_id)
);
