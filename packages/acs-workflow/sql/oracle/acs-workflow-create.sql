--
-- acs-workflow/sql/acs-workflow-create.sql
--
-- Calls the other SQL files to create the data models and PL/SQL packages.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id: acs-workflow-create.sql,v 1.1 2005/04/27 22:50:59 cvs Exp $
--

@@ wf-core-create
@@ workflow-case-package
@@ workflow-package
@@ wf-callback-package

/* We create two sample processes */
@@ sample-expenses-create
@@ sample-article-create
