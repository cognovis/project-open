-- packages/acs-events/sql/postgresql/activity-drop.sql
--
-- $Id$

-- drop package acs_activity;
select drop_package('acs_activity');

drop table   acs_activity_object_map;
drop table   acs_activities;

select  acs_object_type__drop_type ('acs_activity','f');




