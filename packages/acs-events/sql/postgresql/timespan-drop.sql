-- packages/acs-events/sql/timespan-drop.sql
--
-- Drop the data models and API for both time_interval and timespan.
--
-- @author W. Scott Meeks
--
-- $Id: timespan-drop.sql,v 1.2 2010/11/08 13:10:35 victorg Exp $

select drop_package('timespan');
drop index   timespans_idx;
drop table   timespans;

select drop_package('time_interval');
drop table   time_intervals;

drop sequence timespan_sequence;
