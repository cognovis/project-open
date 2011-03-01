--
-- acs-workflow/sql/sample-expenses-drop.sql
--
-- Drops the expenses workflow.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id: sample-expenses-drop.sql,v 1.1 2005/04/27 22:50:59 cvs Exp $
--

begin
    workflow.delete_cases(workflow_key => 'expenses_wf');
end;
/
show errors;

drop table wf_expenses_cases;

begin
    workflow.drop_workflow(workflow_key => 'expenses_wf');
end;
/
show errors;


