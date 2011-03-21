-- packages/acs-events/sql/recurrence-drop.sql
--
-- $Id: recurrence-drop.sql,v 1.1 2001/07/13 02:00:30 jowells Exp $

drop package recurrence;

drop table recurrences;
drop table recurrence_interval_types;

drop sequence recurrence_seq;
