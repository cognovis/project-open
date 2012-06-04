--
-- Fixes case deletion, which can now be done completely through cascading delete
-- Also adds missing upgrade scripts from that bug fix
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

create or replace function workflow_case_pkg__delete (integer)
returns integer as '
declare
  delete_case_id                alias for $1;
  rec                           record;
begin
    -- All workflow data cascades from the case id
    delete from workflow_cases
      where case_id = delete_case_id;    

  return 0; 
end;' language 'plpgsql';



create or replace function workflow_case_log_entry__new (
    integer,                  -- entry_id
    varchar,                  -- content_type
    integer,                  -- case_id
    integer,                  -- action_id
    varchar,                  -- comment
    varchar,                  -- comment_mime_type
    integer,                  -- creation_user
    varchar                   -- creation_ip
) returns integer as '
declare
    p_item_id           alias for $1;
    p_content_type      alias for $2;
    p_case_id           alias for $3;
    p_action_id         alias for $4;
    p_comment           alias for $5;
    p_comment_mime_type alias for $6;
    p_creation_user     alias for $7;
    p_creation_ip       alias for $8;
        
    v_name                        varchar;
    v_action_short_name           varchar;
    v_action_pretty_past_tense    varchar;
    v_case_object_id              integer;
    v_item_id                     integer;
    v_revision_id                 integer;
begin
    select short_name, pretty_past_tense
    into   v_action_short_name, v_action_pretty_past_tense
    from   workflow_actions
    where  action_id = p_action_id;

    -- use case object as context_id
    select object_id
    into   v_case_object_id
    from   workflow_cases
    where  case_id = p_case_id;

    -- build the unique name
    if p_item_id is not null then
        v_item_id := p_item_id;
    else
        select nextval
        into   v_item_id
        from   acs_object_id_seq;
    end if;
    v_name := v_action_short_name || '' '' || v_item_id;

    v_item_id := content_item__new (
        v_item_id,                   -- item_id
        v_name,                      -- name
        v_case_object_id,            -- parent_id
        v_action_pretty_past_tense,  -- title
        now(),                       -- creation_date
        p_creation_user,             -- creation_user
        v_case_object_id,            -- context_id
        p_creation_ip,               -- creation_ip
        ''t'',                       -- is_live
        p_comment_mime_type,         -- mime_type
        p_comment,                   -- text
        ''text'',                    -- storage_type
        ''t'',                       -- security_inherit_p
        ''CR_FILES'',                -- storage_area_key
        ''content_item'',            -- item_subtype
        p_content_type               -- content_type
    );

    -- insert the row into the single-column entry revision table
    select content_item__get_live_revision (v_item_id)
    into v_revision_id;

    insert into workflow_case_log_rev (entry_rev_id)
    values (v_revision_id);

    -- insert into workflow-case-log
    insert into workflow_case_log (entry_id, case_id, action_id)
    values (v_item_id, p_case_id, p_action_id);

    -- return id of newly created item
    return v_item_id;
end;' language 'plpgsql';


-- Now change parent_id of existing cases

create or replace function inline_0() returns integer as '
declare
  rec                           record;
begin
    for rec in select c.object_id, 
                       l.entry_id 
                from   workflow_cases c, 
                       workflow_case_log l 
                where  c.case_id = l.case_id
    loop
        update cr_items
        set    parent_id = rec.object_id
        where  item_id = rec.entry_id;
    end loop;

    return 0;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();

