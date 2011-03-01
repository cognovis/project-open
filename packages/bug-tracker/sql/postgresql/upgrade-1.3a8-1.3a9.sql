select define_function_args ('bt_bug__new','bug_id,bug_number,package_id,component_id,found_in_version,summary,user_agent,comment_content,comment_formt,creation_date,creation_user,creation_ip,fix_for_version,item_subtype;bt_bug,content_type;bt_bug_revision,bug_container_project_id');

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
    integer,     -- fix_for_version	 
    varchar,     -- item_subtype
    varchar,     -- content_type
    integer      -- bug_container_project_id
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
    p_bug_container_project_id  alias for $16;
    
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
        (bug_id, bug_number, comment_content, comment_format, parent_id, project_id, creation_date, creation_user, fix_for_version, bug_container_project_id)
    values
        (v_bug_id, v_bug_number, p_comment_content, p_comment_format, v_folder_id, p_package_id, p_creation_date, p_creation_user, p_fix_for_version, p_bug_container_project_id);

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
        p_creation_ip,             -- creation_ip,
	p_bug_container_project_id -- bug_container_project_id
    );

    return v_bug_id;
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
    varchar,        -- creation_ip
    integer         -- bug_container_project_id
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
    p_bug_container_project_id alias for $13;

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
           fixed_in_version = p_fixed_in_version,
	   bug_container_project_id = p_bug_container_project_id
    where  bug_id = p_bug_id;

    return v_revision_id;
end;
' language 'plpgsql';




create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) 
	into v_count 
	from user_tab_columns 
	where lower(table_name)=''bt_bugs'' 
		and lower(column_name)=''bug_container_project_id'';

        if v_count > 0 then
            return 0;
        end if;

	alter table bt_bugs add bug_container_project_id integer;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
