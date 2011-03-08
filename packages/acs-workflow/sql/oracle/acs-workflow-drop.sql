--
-- acs-workflow/sql/acs-workflow-drop.sql
--
-- Drops the data model and the PL/SQL packages.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id: acs-workflow-drop.sql,v 1.1 2005/04/27 22:50:59 cvs Exp $
--


@@ jobs-kill
@@ wf-core-drop
drop package wf_callback;
drop package workflow;
drop package workflow_case;
