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

create function inline_0 () returns integer as '
begin
    perform workflow__delete_cases(''article_wf'');
    return 0;
end;' language 'plpgsql';

drop table wf_article_cases;


select inline_0 ();

drop function inline_0 ();



create function inline_0 () returns integer as '
begin
    perform workflow__drop_workflow(''article_wf'');
    return 0;
end;' language 'plpgsql';


select inline_0 ();

drop function inline_0 ();

drop function wf_article_callback__notification(integer,varchar,integer,integer,varchar,varchar);

