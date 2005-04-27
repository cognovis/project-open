--
-- acs-workflow/sql/sample-article-drop.sql
--
-- Drops the article-authoring workflow.
--
-- @author Kevin Scaldeferri (kevin@theory.caltech.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

begin
    workflow.delete_cases(workflow_key => 'article_wf');
end;
/
show errors;

drop table wf_article_cases;

begin
    workflow.drop_workflow(workflow_key => 'article_wf');
end;
/
show errors;


