--
-- acs-workflow/sql/sample-article-drop.sql
--
-- Drops the article-authoring workflow.
--
-- @author Kevin Scaldeferri (kevin@theory.caltech.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id: sample-article-drop.sql,v 1.1 2005/04/27 22:50:59 cvs Exp $
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


