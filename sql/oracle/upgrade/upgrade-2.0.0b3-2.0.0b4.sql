-- 
-- 
-- 
-- @author Jade Rubick (jader@bread.com)
-- From bug #2210
-- @creation-date 2004-12-16
-- @arch-tag: 16d12f6e-d889-45a4-b7d5-df75388b11fe
-- @cvs-id $Id$
--

create or replace package body workflow_case_pkg
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

  function del(
    delete_case_id in integer
  ) return integer
  is
  begin
    -- All workflow data cascades from the case id
    delete 
    from   workflow_cases
    where  case_id = workflow_case_pkg.del.delete_case_id;

    return 0;
  end del;

end workflow_case_pkg;
/
show errors
