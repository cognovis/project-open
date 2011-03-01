--
-- bt_bugs: add 'needinfo' to resolution check constraint
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
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro','needinfo')),
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

-- We do this in an inline function, so that we won't delete the _old table if the insert fails.

create function inline_0 ()
returns integer as '
begin
    insert into bt_bugs select * from bt_bugs_old;

    drop table bt_bugs_old;

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


--
-- bt_bug_actions: add 'needinfo' to resolution check constraint
--

drop index bt_bug_actions_pk;

alter table bt_bug_actions rename to bt_bug_actions_old;

create table bt_bug_actions (
  action_id                     integer not null
                                constraint bt_bug_actions_pk
                                primary key,
  bug_id                        integer not null
                                constraint bt_bug_actions_bug_fk
                                references bt_bugs(bug_id)
                                on delete cascade,
  action                        varchar(50)
                                constraint bt_bug_actions_action_ck
                                check (action in ('open','edit','comment','reassign','resolve','reopen','close')),
  resolution                    varchar(50)
                                constraint bt_bugs_actions_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro','needinfo')),
  actor                         integer not null
                                constraint bt_bug_actions_actor_fk
                                references users(user_id),
  action_date                   timestamptz not null
                                default current_timestamp,
  comment                       text,
  comment_format                varchar(30) default 'plain' not null
                                constraint  bt_bug_actions_comment_format_ck
                                check (comment_format in ('html', 'plain', 'pre'))
);

create function inline_0 ()
returns integer as '
begin
    insert into bt_bug_actions (action_id, bug_id, action, resolution, actor, action_date, comment, comment_format) 
    select action_id, bug_id, action, resolution, actor, action_date, comment, comment_format from bt_bug_actions_old;

    drop table bt_bug_actions_old;

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();



