-- packages/acs-events/sql/acs-events-drop.sql
--
-- $Id: acs-events-drop.sql,v 1.2 2010/11/08 13:10:35 victorg Exp $

-- drop package acs_event;
select drop_package('acs_event');

drop view    partially_populated_events;
drop view    partially_populated_event_ids;
drop view    acs_events_activities;
drop view    acs_events_dates;

drop table   acs_event_party_map;
drop index   acs_events_recurrence_id_idx;
drop table   acs_events;


\i recurrence-drop.sql
\i timespan-drop.sql
\i activity-drop.sql
\i oracle-compat-drop.sql

-- acs_activity subclasses acs_event object, so we should only delete here.
select acs_object_type__drop_type ('acs_event','f');


