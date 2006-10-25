--
-- bt_versions
--

drop index bt_versions_pk;
drop index bt_versions_version_name_un;
alter table bt_versions rename to bt_versions_old;

create table bt_versions (
  version_id                     integer not null
                                 constraint bt_versions_pk
                                 primary key,
  project_id                     integer not null
                                 constraint bt_versions_projects_fk
                                 references bt_projects(project_id),
  -- Like apm_package_versions.version_name
  -- But can also be a human-readable name like "Future", "Milestone 3", etc.
  version_name                   varchar(500) not null,
  description                    text,
  anticipated_freeze_date        date,
  actual_freeze_date             date,
  anticipated_release_date       date,
  actual_release_date            date,
  maintainer                     integer 
                                 constraint bt_versions_maintainer_fk
                                 references users(user_id),
  supported_platforms            varchar(1000),
  active_version_p               char(1) not null
                                 constraint bt_versions_active_version_p_ck
                                 check (active_version_p in ('t','f'))
                                 default 'f',
  -- Can we assign bugs to be fixed for this version?
  assignable_p                   char(1)
                                 constraint bt_versions_assignable_p_ck
                                 check (assignable_p in ('t','f'))
);

insert into bt_versions select * from bt_versions_old;


--
-- bt_components
--

drop index bt_components_pk;
drop index bt_components_name_un;
alter table bt_components rename to bt_components_old;

create table bt_components (
  component_id                  integer not null
                                constraint bt_components_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_components_projects_fk 
                                references bt_projects(project_id),
  component_name                varchar(500) not null,
  description                   text,
  -- a component can be without maintainer, in which case we just default to the project maintainer
  maintainer                    integer 
                                constraint bt_components_maintainer_fk
                                references users(user_id)
);

insert into bt_components select * from bt_components_old;



--
-- bt_bugs
--

drop index bt_bugs_pk;
drop index bt_bugs_bug_number_un;
alter table bt_bugs rename to bt_bugs_old;

create table bt_bugs (
  bug_id                        integer 
                                constraint bt_bugs_pk
                                primary key
                                constraint bt_bugs_bug_id_fk
                                references acs_objects(object_id),
  project_id                    integer 
                                constraint bt_bugs_projects_fk
                                references bt_projects(project_id),

  component_id                  integer 
                                constraint bt_bugs_components_fk
                                references bt_components(component_id),
  bug_number                    integer not null,
  status                        varchar(50) not null
                                constraint bt_bugs_status_ck
                                check (status in ('open', 'resolved', 'closed'))
                                default 'open',
  resolution                    varchar(50)
                                constraint bt_bugs_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro')),
  bug_type                      varchar(50) not null
                                constraint bt_bugs_bug_type_ck
                                check (bug_type in ('bug', 'suggestion','todo')),
  severity                      integer not null
                                constraint bt_bugs_severity_fk
                                references bt_severity_codes(severity_id),
  priority                      integer not null
                                constraint bt_bugs_priority_fk
                                references bt_priority_codes(priority_id),
  user_agent                    varchar(500),
  original_estimate_minutes     integer,
  latest_estimate_minutes       integer,
  elapsed_time_minutes          integer,
  found_in_version              integer
                                constraint bt_bugs_found_in_version_fk   
                                references bt_versions(version_id), 
  fix_for_version               integer
                                constraint bt_bugs_fix_for_version_fk   
                                references bt_versions(version_id), 
  fixed_in_version              integer
                                constraint bt_bugs_fixed_in_version_fk   
                                references bt_versions(version_id), 
  summary                       varchar(500) not null,                                
  assignee                      integer
                                constraint bt_bug_assignee_fk
                                references users(user_id),
  constraint bt_bugs_bug_number_un
  unique (project_id, bug_number)
);

insert into bt_bugs select * from bt_bugs_old;

--
-- bt_bugs__new
--


create function bt_component__default_assignee(
   integer                      -- component_id
) returns integer
as '
declare
    p_component_id              alias for $1;
    v_assignee                  integer;
begin
    select maintainer
    into   v_assignee
    from   bt_components
    where  component_id = p_component_id;

    if v_assignee is null then
        select p.maintainer
        into   v_assignee
        from   bt_projects p, bt_components c
        where  p.project_id = c.project_id
        and    c.component_id = p_component_id;
    end if;

    return v_assignee;
end;
' language 'plpgsql';



drop function bt_bug__new
     (integer, integer, integer, varchar, integer, integer, integer, varchar, text, varchar, varchar, integer, varchar);

create function bt_bug__new(
    integer,     -- bug_id
    integer,     -- project_id
    integer,     -- component_id
    varchar,     -- bug_type 
    integer,     -- severity
    integer,     -- priority
    integer,     -- found_in_version
    varchar,     -- summary
    text,        -- description
    varchar,     -- desc_format
    varchar,     -- user_agent
    integer,     -- creation_user
    varchar      -- creation_ip
) returns int
as '
declare
    p_bug_id                    alias for $1;
    p_project_id                alias for $2;
    p_component_id              alias for $3;
    p_bug_type                  alias for $4;
    p_severity                  alias for $5;
    p_priority                  alias for $6;
    p_found_in_version          alias for $7;
    p_summary                   alias for $8;
    p_description               alias for $9;
    p_desc_format               alias for $10;
    p_user_agent                alias for $11;
    p_creation_user             alias for $12;
    p_creation_ip               alias for $13;
    v_bug_id                    integer;
    v_bug_number                integer;
    v_assignee                  integer;
    v_action_id                 integer;
begin
    v_assignee := bt_component__default_assignee(p_component_id);

    v_bug_id := acs_object__new(
        p_bug_id,               -- object_id
        ''bt_bug'',             -- object_type
        now(),                  -- creation_date
        p_creation_user,        -- creation_user
        p_creation_ip,          -- creation_ip
        p_project_id,           -- context_id
        ''t''                   -- security_inherit_p
    );

    select coalesce(max(bug_number),0) + 1
    into   v_bug_number
    from   bt_bugs
    where  project_id = p_project_id;

    insert into bt_bugs
        (bug_id, project_id, component_id,  bug_number, bug_type, severity, assignee,
         priority, found_in_version, summary, user_agent)
    values
        (v_bug_id, p_project_id, p_component_id, v_bug_number, p_bug_type, p_severity, v_assignee,
        p_priority, p_found_in_version, p_summary, p_user_agent);

    select nextval(''t_acs_object_id_seq'') 
    into   v_action_id;

    insert into bt_bug_actions
        (action_id, bug_id, action, actor, comment, comment_format)
    values
        (v_action_id, v_bug_id, ''open'', p_creation_user, p_description, p_desc_format);
        
    return 0;
end;
' language 'plpgsql';



drop table bt_versions_old;
drop table bt_components_old;
drop table bt_bugs_old;

