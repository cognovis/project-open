-- Script to implement the workflow_case -> workflow_case_pkg change
-- for existing installations
-- 
-- Note - this script assumes that only workflow is installed, not acs-workflow.
-- if both have been installed this will delete a package which is in use by
-- acs-workflow, but then again if both are installed then the site has
-- problems already, so maybe that's not the end of the world.
--
-- @author Janine Sisk (janine@furfly.net)
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- delete existing package.  This package was named the same as a package
-- from acs-workflow, meaning they could not both be installed at the same
-- time.
drop package workflow_case;

-- now create the new one.  This is just a copy of the code from
-- workflow-procedural-create.sql
create or replace package workflow_case_pkg
as
  function get_pretty_state(
    workflow_short_name in varchar,
    object_id in integer
    ) return varchar;
  
  function delete(
    delete_case_id in integer
  ) return integer;

end workflow_case_pkg;
/
show errors

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
        where object_id = delete_case_id;

    return 0;
  end delete;

end workflow_case_pkg;
/
show errors

