-- packages/acs-events/sql/timespan-drop.sql
--
-- $Id: timespan-drop.sql,v 1.1 2001/07/13 02:00:30 jowells Exp $

drop package timespan;
drop index 	 timespans_idx;
drop table   timespans;

drop package time_interval;
drop table   time_intervals;

drop sequence timespan_seq;
