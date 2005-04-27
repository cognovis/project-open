--
-- acs-workflow/sql/acs-workflow-drop.sql
--
-- Drops the data model and the PL/SQL packages.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--


--\i jobs-kill.sql
\i sample-article-drop.sql
\i wf-core-drop.sql


drop function __workflow__simple_p (varchar,integer);
drop table guard_list;
drop table target_place_list;
drop table previous_place_list;
drop sequence workflow_session_id;
drop function sweep_hold_timeout ();
drop function sweep_timed_transitions ();

select drop_package('wf_callback');
select drop_package('workflow');
select drop_package('workflow_case');







