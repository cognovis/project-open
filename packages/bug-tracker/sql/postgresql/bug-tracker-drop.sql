
drop function bt_bug__new(
    integer,     -- bug_id
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
    varchar,     -- item_subtype
    varchar      -- content_type
);

drop function bt_bug__delete (integer);

drop function bt_bug_revision__new(
    integer,        -- revision_id
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
);

drop function bt_version__set_active (integer);
drop function bt_project__new(integer);
drop function bt_project__delete(integer);

drop table bt_user_prefs;
drop table bt_bugs;
select acs_object_type__drop_type('bt_bug', 't');

select content_type__drop_type('bt_bug_revision', 't', 'f');
drop table bt_bug_revisions;

drop table bt_default_keywords;

drop table bt_components;
drop table bt_versions;
drop table bt_projects;


drop table bt_patch_bug_map;
drop function bt_patch__delete(integer);
drop function bt_patch__name(integer);
drop function bt_patch__new(integer,integer,integer,text,text,text,text,integer,integer,varchar);
drop table bt_patch_actions;
drop table bt_patches;
drop sequence t_bt_patch_number_seq;
drop view bt_patch_number_seq;

delete from acs_objects where object_type = 'bt_patch';

select acs_object_type__drop_type('bt_patch', 't');
