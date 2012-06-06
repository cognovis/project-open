--
-- Upgrade script
--
-- Renamed workflow_case__delete to workflow_case_pkg__delete to prevent clash with old acs-workflow package
--
-- Lars Pind (lars@collaboraid.biz)
--
-- $Id$

-- This needs to be recreated to use the renamed workflow_case_pkg__delete function

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

-- Renamed from workflow_case__delete, because 'acs-workflow' already defined workflow_case__delete.
-- LARS:
-- What do we do with the old acs-workflow one, which we may have overwritten?
-- I suppose that if people have tried installing workflow after acs-workflow, that installation
-- will have failed, and their systems will be somewhat screwed, anyway

create or replace function workflow_case_pkg__delete (integer)
returns integer as '
declare
  delete_case_id                alias for $1;
  rec                           record;
begin

    for rec in select cr.item_id
                   from cr_items cr, workflow_case_log wcl
                   where cr.item_id = wcl.entry_id
                   and wcl.case_id = delete_case_id loop

                delete from workflow_case_log where entry_id = rec.item_id;
                perform content_item__delete(rec.item_id);                
    end loop;

    -- All workflow data cascades from the case id
    delete from workflow_cases
      where case_id = delete_case_id;    

  return 0; 
end;' language 'plpgsql';

drop function workflow_case__delete (integer);

-- Renamed from workflow_case__get_pretty_state to maintain consitency with workflow_case__delete

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

drop function workflow_case__get_pretty_state (
    varchar, -- workflow_short_name
    integer  -- object_id
);


