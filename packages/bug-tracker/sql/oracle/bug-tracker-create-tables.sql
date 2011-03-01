--
-- Bug tracker Oracle data model
--
-- Ported from the postgresql version
--   by:  Mark Aufflick (mark@pumptheory.com) <http://pumptheory.com/>
--   for: Collaboraid <http://collaboraid.biz/>
--

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
  description                   clob,
                                -- short string will be included in the subject line of emails                                                                
  email_subject_name            varchar2(1000),
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

create table bt_versions (
  version_id                    integer not null
                                constraint bt_versions_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_versions_projects_fk
                                references bt_projects(project_id),
                                -- Like apm_package_versions.version_name
                                -- But can also be a human-readable name like "Future", "Milestone 3", etc.
  version_name                  varchar2(500) not null,
  description                   clob,
  anticipated_freeze_date       date,
  actual_freeze_date            date,
  anticipated_release_date      date,
  actual_release_date           date,
  maintainer                    integer 
                                constraint bt_versions_maintainer_fk
                                references users(user_id),
  supported_platforms           varchar2(1000),
  active_version_p              char(1) default 'f' not null
                                constraint bt_vers_activ_ver_p_ck
                                check (active_version_p in ('t','f')),
                                -- Can we assign bugs to be fixed for this version?
  assignable_p                  char(1)
                                constraint bt_versions_assignable_p_ck
                                check (assignable_p in ('t','f'))
);


create table bt_components (
  component_id                  integer not null
                                constraint bt_components_pk
                                primary key,
  project_id                    integer not null
                                constraint bt_components_projects_fk 
                                references bt_projects(project_id),
  component_name                varchar2(500) not null,
  description                   clob,
                                -- This is what the component can be referred to in the URL
  url_name                      varchar2(4000),
                                -- a component can be without maintainer, in which case we just default
                                -- to the project maintainer
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
                                on delete cascade
);
alter table bt_default_keywords add constraint bt_default_keywords_prj_par_un unique (project_id, parent_id);

create index bt_default_keyw_parent_id_idx on bt_default_keywords(parent_id);
create index bt_default_keyw_keyword_id_idx on bt_default_keywords(keyword_id);

create table bt_bugs (
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
  comment_content               varchar2(4000),
  comment_format                varchar2(200),
  -- denormalized from cr_items
  parent_id                     integer,
  live_revision_id              integer,
  -- denormalized from cr_revisions.title
  summary                       varchar2(1000),
  -- denormalized from bt_projects
  project_id                    integer,
  -- denormalized from bt_bug_revisions
  component_id                  integer,
  resolution                    varchar2(50),
  user_agent                    varchar2(500),
  found_in_version              integer,
  fix_for_version               integer,
  fixed_in_version              integer,
  -- denormalized from acs_objects
  creation_date                 date,
  creation_user                 integer
);
alter table bt_bugs add constraint bt_bug_parent_id_bug_number_un unique (parent_id, bug_number);

-- LARS:
-- we need to figure out which ones of these will be used by the query optimizer

create index bt_bugs_proj_id_bug_number_idx on bt_bugs(project_id, bug_number);
create index bt_bugs_bug_number_idx on bt_bugs(bug_number);

create index bt_bugs_proj_id_fix_for_idx on bt_bugs(project_id, fix_for_version);
create index bt_bugs_fix_for_version_idx on bt_bugs(fix_for_version);

create index bt_bugs_proj_id_crea_date_idx on bt_bugs(project_id, creation_date);
create index bt_bugs_creation_date_idx on bt_bugs(creation_date);


-- Create the bt_bug object type

begin
    acs_object_type.create_type (
	'bt_bug',
	'Bug',
	'Bugs',
	'acs_object',
	'bt_bugs',
	'bug_id',
	null,
	'f',
	null,
	'bt_bug.name'
	);
end;
/
show errors

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

begin
    content_type.create_type (
        'bt_bug_revision',
        'content_revision',
        'Bug Revision',
        'Bug Revisions',
        'bt_bug_revisions',
        'bug_revision_id',
        'content_revision.revision_name'
    );
end;
/
show errors
 
create table bt_user_prefs (
  user_id                       integer not null
                                constraint bt_user_prefs_user_id_fk
                                references users(user_id),
  project_id                    integer not null
                                constraint bt_user_prefs_project_fk
                                references bt_projects(project_id),
  user_version                  integer
                                constraint bt_usr_prfs_curr_ver_fk
                                references bt_versions(version_id)
);

alter table bt_user_prefs add constraint bt_user_prefs_pk primary key (user_id, project_id);

-- For stability, URLs contain patch numbers rather than ACS Object ids.
-- This avoids dependence on the ACS kernel and makes upgrades easier.

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
       summary                  varchar2(500),
       content                  clob,
       generated_from_version   integer
                                constraint bt_patches_vid_fk
                                references bt_versions(version_id),
       apply_to_version         integer
                                constraint bt_patchs_apply_to_version_fk   
                                references bt_versions(version_id), 
       applied_to_version       integer
                                constraint bt_patchs_applied_to_ver_fk   
                                references bt_versions(version_id), 
       status                   varchar2(50) default 'open' not null
                                constraint bt_patchs_status_ck
                                check (status in ('open', 'accepted', 'refused', 'deleted'))
);
alter table bt_patches add constraint bt_patches_un unique(patch_number, project_id);

create table bt_patch_actions (
       action_id                integer not null
                                constraint bt_patch_actions_pk
                                primary key,
       patch_id                 integer not null
                                constraint bt_patch_actions_patch_fk
                                references bt_patches(patch_id)
                                on delete cascade,
       action                   varchar2(50) default 'open'
                                constraint bt_patch_actions_action_ck
                                check (action in ('open', 'edit', 'comment', 'accept', 
                                                  'reopen', 'refuse', 'delete')),
       actor                    integer not null
                                constraint bt_patch_actions_actor_fk
                                references users(user_id),
       action_date              date default sysdate not null,
       comment_text             clob,
       comment_format           varchar2(30) default 'plain' not null
                                constraint  bt_patch_actns_comment_fmt_pk
                                check (comment_format in ('html', 'plain', 'pre'))
);

-- Create the bt_patch object type
begin
    acs_object_type.create_type (
	'bt_patch',
	'Patch',
	'Patches',
	'acs_object',
	'bt_patches',
	'patch_id',
	null,
	'f',
	null,
	'bt_patch.name'
	);
end;
/
show errors


-- There is a many to many relationship between patches and bugs
create table bt_patch_bug_map (
       patch_id            integer not null
                           constraint bt_patch_bug_map_pid_fk
                           references bt_patches(patch_id)
                           on delete cascade,
       bug_id              integer not null
                           constraint bt_patch_bug_map_bid_fk
                           references bt_bugs(bug_id)
                           on delete cascade
);
alter table bt_patch_bug_map add constraint bt_patch_bug_map_un unique (patch_id, bug_id);

create index bt_patch_bug_map_patch_id_idx on bt_patch_bug_map(patch_id);
create index bt_patch_bug_map_bug_id_idx on bt_patch_bug_map(bug_id);
