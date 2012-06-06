-- packages/acs-events/sql/activity-drop.sql
--
-- $Id$

drop package acs_activity;
drop table   acs_activity_object_map;
drop table   acs_activities;

begin
    acs_object_type.drop_type ('acs_activity');
end;
/
show errors



