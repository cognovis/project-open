-- packages/acs-events/sql/recurrence-drop.sql
--
-- Drop support for temporal recurrences
--
-- $Id: recurrence-drop.sql,v 1.2 2010/11/08 13:10:35 victorg Exp $

-- drop package recurrence;
select drop_package('recurrence');

drop table recurrences;
drop table recurrence_interval_types;

drop sequence recurrence_sequence;

