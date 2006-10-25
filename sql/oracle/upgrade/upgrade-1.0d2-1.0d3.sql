-- Upgrade script
--
-- Reload the workflow_case PL/SQL package.
-- workflow_case.delete was implemented wrong, so it tried to delete the case by object_id instead of case_id.
--
-- Lars Pind (lars@collaboraid.biz)
-- $Id$



create or replace package workflow_case
as
  function get_pretty_state(
    workflow_short_name in varchar,
    object_id in integer
    ) return varchar;
  
  function delete(
    delete_case_id in integer
  ) return integer;

end workflow_case;
/
show errors

create or replace package body workflow_case
as 
  function get_pretty_state(
    workflow_short_name in varchar,
    object_id in integer
  ) return varchar
  is 
    v_state_pretty varchar(4000);
    v_object_id integer;
  begin
   v_object_id := object_id;   

   select s.pretty_name
   into   v_state_pretty
   from   workflows w,
          workflow_cases c,
          workflow_case_fsm cfsm,
          workflow_fsm_states s
   where  w.short_name = workflow_short_name
   and    c.object_id = v_object_id
   and    c.workflow_id = w.workflow_id
   and    cfsm.case_id = c.case_id
   and    s.state_id = cfsm.current_state;

   return v_state_pretty;

  end get_pretty_state;    

  function delete(
    delete_case_id in integer
  ) return integer
  is
  begin
   for rec in (select cr.item_id
                from cr_items cr, workflow_case_log wcl
                where cr.item_id = wcl.entry_id
                and wcl.case_id = delete_case_id)
    loop
        delete from workflow_case_log where entry_id = rec.item_id;
        content_item.delete(rec.item_id);
    end loop;

    -- All workflow data cascades from the case id
    delete from workflow_cases
        where case_id = delete_case_id;

    return 0;
  end delete;

end workflow_case;
/
show errors

