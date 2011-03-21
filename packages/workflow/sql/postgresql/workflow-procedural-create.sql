-- Procedural database code for the workflow package, a package in the OpenACS system.
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

---------------------------------
-- Workflow level, Generic Model
---------------------------------

create or replace function workflow__delete (integer)
returns integer as '
declare
  delete_workflow_id            alias for $1;
  rec                           record;
begin
  -- Delete all cases first
  for rec in select case_id     
             from workflow_cases
             where workflow_id = delete_workflow_id loop

        perform workflow_case_pkg__delete (rec.case_id);
  end loop;

  perform acs_object__delete(delete_workflow_id);

  return 0; 
end;' language 'plpgsql';

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

-- Function for creating a workflow
create or replace function workflow__new (
    varchar, -- short_name
    varchar, -- pretty_name
    varchar, -- package_key
    integer, -- object_id
    varchar, -- object_type
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
)
returns integer as '
declare
    p_short_name            alias for $1;
    p_pretty_name           alias for $2;
    p_package_key           alias for $3;
    p_object_id             alias for $4;
    p_object_type           alias for $5;
    p_creation_user         alias for $6;
    p_creation_ip           alias for $7;
    p_context_id            alias for $8;
  
    v_workflow_id           integer;
begin
    -- Instantiate the ACS Object super type with auditing info
    v_workflow_id  := acs_object__new(null,
                                      ''workflow_lite'',
                                      now(),
                                      p_creation_user,
                                      p_creation_ip,
                                      p_context_id,
                                      ''t'');

    -- Insert workflow specific info into the workflows table
    insert into workflows
           (workflow_id, short_name, pretty_name, package_key, object_id, object_type)
       values
           (v_workflow_id, p_short_name, p_pretty_name, p_package_key, p_object_id, p_object_type);
            

   return v_workflow_id;
end;
' language 'plpgsql';




-- Function for getting the pretty state of a case
create or replace function workflow_case_pkg__get_pretty_state (
    varchar, -- workflow_short_name
    integer  -- object_id
)
returns varchar as '
declare
    p_workflow_short_name   alias for $1;
    p_object_id             alias for $2;
  
    v_state_pretty          varchar;
begin
   select s.pretty_name
   into   v_state_pretty
   from   workflows w,
          workflow_cases c,
          workflow_case_fsm cfsm,
          workflow_fsm_states s
   where  w.short_name = p_workflow_short_name
   and    c.object_id = p_object_id
   and    c.workflow_id = w.workflow_id
   and    cfsm.case_id = c.case_id
   and    s.state_id = cfsm.current_state;

   return v_state_pretty;
end;
' language 'plpgsql';

select define_function_args ('workflow_case_log_entry__new','entry_id,content_type;workflow_case_log_entry,case_id,action_id,comment,comment_mime_type,creation_user,creation_ip');

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
