-- packages/acs-events/sql/timespan-drop.sql
--
-- $Id$

drop package timespan;
drop index 	 timespans_idx;
drop table   timespans;

drop package time_interval;
drop table   time_intervals;

drop sequence timespan_seq;
