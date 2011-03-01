--
-- acs-events/sql/test/acs-events-test.sql
--
-- PL/SQL regression tests for ACS Events
--
-- Note: These tests use the utPLSQL regression package available at:
-- ftp://ftp.oreilly.com/published/oreilly/oracle/utplsql/utInstall.zip
--
-- @author W. Scott Meeks (smeeks@arsdigita.com)
--
-- @creation-date 2000-11-29
--
-- @cvs-id $Id: acs-events-test.sql,v 1.2 2003/09/30 12:10:02 mohanp Exp $

-- In order for utPLSQL to work, you need to grant 
-- specific permissions to your user:
---
-- grant create public synonym to servicename;
-- grant drop public synonym to servicename;
-- grant execute on dbms_pipe to servicename;
-- grant drop any table to servicename;
-- grant create any table to servicename;
--
-- In order to execute the test, you need to set things up
-- in your SQL*PLUS session. First type:
-- 
--     set serveroutput on size 1000000 format wrapped
--
-- Now, if you have the UTL_FILE PL/SQL package installed, type:
--
--     exec utplsql.setdir('/web/servicename/packages/acs-events/sql/test');
--
-- Otherwise, you'll have to disable autocompilation and manually
-- compile:
--
--     exec utplsql.autocompile (false);
--     @acs-events-test
--
-- To actually execute the test, type:
--
--     exec utplsql.test('acs_event');

set serveroutput on size 1000000 format wrapped
exec utplsql.autocompile (false);
exec utplsql.setdir('/web/servicename/packages/acs-events/sql/test');

-- we need these here or else the PL/SQL won't compile.

drop table ut_acs_events;
create table ut_acs_events as select * from acs_events;

drop table ut_acs_event_party_map;
create table ut_acs_event_party_map as select * from acs_event_party_map;

-- Template created with exec utGen.testpkg('acs_event');

CREATE OR REPLACE PACKAGE ut_acs_event
IS
   PROCEDURE ut_setup;
   PROCEDURE ut_teardown;

   -- For each program to test...
--     PROCEDURE ut_ACTIVITY_SET;
--     PROCEDURE ut_DELETE;
--     PROCEDURE ut_DELETE_ALL;
--     PROCEDURE ut_DELETE_ALL_RECURRENCES;
--     PROCEDURE ut_GET_DESCRIPTION;
--     PROCEDURE ut_GET_NAME;
     PROCEDURE ut_INSERT_INSTANCES;
--     PROCEDURE ut_INSTANCES_EXIST_P;
--     PROCEDURE ut_NEW;
--     PROCEDURE ut_PARTY_MAP;
--     PROCEDURE ut_PARTY_UNMAP;
--     PROCEDURE ut_RECURS_P;
--     PROCEDURE ut_SHIFT;
--     PROCEDURE ut_SHIFT_ALL1;
--     PROCEDURE ut_SHIFT_ALL2;
--     PROCEDURE ut_TIMESPAN_SET;
END ut_acs_event;
/
CREATE OR REPLACE PACKAGE BODY ut_acs_event
IS
   date1 date;
   date2 date;

   PROCEDURE ut_setup
   IS
   BEGIN
		ut_teardown;
        dbms_output.put_line('Setting up...');
		-- create copies of the tables
		execute immediate 'create table ut_acs_events as
			select * from acs_events';
		execute immediate 'create table ut_acs_event_party_map as
			select * from acs_event_party_map';

   END ut_setup;

   PROCEDURE ut_teardown
   IS
   BEGIN
        dbms_output.put_line('Tearing down...');
		-- clean out the test tables
		begin
			execute immediate 'drop table ut_acs_events cascade constraints';
			execute immediate 'drop table ut_acs_event_party_map cascade constraints';
			exception
              when others
              then
                  null;
        end;
   END;

   -- For each program to test...
--     PROCEDURE ut_ACTIVITY_SET IS
--     BEGIN
--  	    ACS_EVENT.ACTIVITY_SET (
--  	    EVENT_ID => ''
--  	    ,
--  	    ACTIVITY_ID => ''
--         );

--        utAssert.this (
--  	 'Test of ACTIVITY_SET',
--  	 '<boolean expression>'
--  	 );
--     END ut_ACTIVITY_SET;

--     PROCEDURE ut_DELETE IS
--     BEGIN
--  	    ACS_EVENT.DELETE (
--  	    EVENT_ID => ''
--         );

--        utAssert.this (
--  	 'Test of DELETE',
--  	 '<boolean expression>'
--  	 );
--     END ut_DELETE;

--     PROCEDURE ut_DELETE_ALL IS
--     BEGIN
--  	    ACS_EVENT.DELETE_ALL (
--  	    EVENT_ID => ''
--         );

--        utAssert.this (
--  	 'Test of DELETE_ALL',
--  	 '<boolean expression>'
--  	 );
--     END ut_DELETE_ALL;

--     PROCEDURE ut_DELETE_ALL_RECURRENCES IS
--     BEGIN
--  	    ACS_EVENT.DELETE_ALL_RECURRENCES (
--  	    RECURRENCE_ID => ''
--         );

--        utAssert.this (
--  	 'Test of DELETE_ALL_RECURRENCES',
--  	 '<boolean expression>'
--  	 );
--     END ut_DELETE_ALL_RECURRENCES;

--     PROCEDURE ut_GET_DESCRIPTION IS
--     BEGIN
--        utAssert.this (
--  	 'Test of GET_DESCRIPTION',
--  	       ACS_EVENT.GET_DESCRIPTION(
--  	    EVENT_ID => ''
--  	    )
--  	 );
--     END ut_GET_DESCRIPTION;

--     PROCEDURE ut_GET_NAME IS
--     BEGIN
--        utAssert.this (
--  	 'Test of GET_NAME',
--  	       ACS_EVENT.GET_NAME(
--  	    EVENT_ID => ''
--  	    )
--  	 );
--     END ut_GET_NAME;

   -- The test of insert_instances has been augmented to test 
   -- other routines.  Specifically new, delete, delete_all, 
   -- timespan_set, activity_set, get_name, get_description, 
   -- party_map, party_unmap, recurs_p, instances_exist_p
   PROCEDURE ut_INSERT_INSTANCES IS
    
	timespan_id			acs_events.timespan_id%TYPE;
	activity_id			acs_events.activity_id%TYPE;
	recurrence_id		acs_events.recurrence_id%TYPE;
	event_id			acs_events.event_id%TYPE;
	instance_count		integer;
	cursor event_cursor is
	    select * from acs_events_dates
		where recurrence_id = ut_INSERT_INSTANCES.recurrence_id;
	events event_cursor%ROWTYPE;
   BEGIN
   dbms_output.put_line('Testing INSERT_INSTANCES...');
	-- Create event components
	timespan_id := timespan.new(date1, date2);

	activity_id := acs_activity.new(
						name => 'Testing',
						description => 'Making sure the code works'
				   );

	-- Recurrence
	recurrence_id := recurrence.new(
						interval_type => 'week',
						every_nth_interval => 1,
						days_of_week => '1 3',
						recur_until => to_date('2000-02-01')
					 );

	-- Create event
	event_id := acs_event.new();

	-- Do some testing while we're here
	utAssert.eq (
		'Test of INSTANCES_EXIST_P f within INSERT_INSTANCES',
		acs_event.instances_exist_p(recurrence_id),
		'f'
	);

	insert into ut_acs_events (event_id)
	values (event_id);

	utAssert.eqtable ( 
		'Test of NEW within INSERT_INSTANCES',
		'ut_acs_events',
		'acs_events'
	);

	utAssert.isnull (
		'Test of GET_NAME null within INSERT_INSTANCES',
		acs_event.get_name(event_id)
	);
					
	utAssert.isnull (
		'Test of GET_DESCRIPTION null within INSERT_INSTANCES',
		acs_event.get_description(event_id)
	);
					
	utAssert.eq (
		'Test of RECURS_P f within INSERT_INSTANCES',
		acs_event.recurs_p(event_id),
		'f'
	);
					
	acs_event.timespan_set(event_id, timespan_id);
	acs_event.activity_set(event_id, activity_id);

	update acs_events
	set recurrence_id = ut_insert_instances.recurrence_id
	where event_id = ut_insert_instances.event_id;
	
	update ut_acs_events
	set timespan_id = ut_insert_instances.timespan_id,
		activity_id = ut_insert_instances.activity_id,
		recurrence_id = ut_insert_instances.recurrence_id
	where event_id = ut_insert_instances.event_id;

	utAssert.eqtable ( 
		'Test of SET procedures within INSERT_INSTANCES',
		'ut_acs_events',
		'acs_events'
	);

	utAssert.eq (
		'Test of GET_NAME from activity within INSERT_INSTANCES',
		acs_event.get_name(event_id),
		'Testing'
	);
					
	utAssert.eq (
		'Test of GET_DESCRIPTION from activity within INSERT_INSTANCES',
		acs_event.get_description(event_id),
		'Making sure the code works'
	);
					
	update acs_events
	set name = 'Further Testing',
		description = 'Making sure the code works correctly.'
	where event_id = ut_insert_instances.event_id;

	utAssert.eq (
		'Test of GET_NAME from event within INSERT_INSTANCES',
		acs_event.get_name(event_id),
		'Further Testing'
	);
					
	utAssert.eq (
		'Test of GET_DESCRIPTION from event within INSERT_INSTANCES',
		acs_event.get_description(event_id),
		'Making sure the code works correctly.'
	);

	-- Insert instances
	acs_event.insert_instances (
	    event_id => event_id
	    ,
	    cutoff_date => to_date('2000-02-02')
       );

	-- Test for instances
	utAssert.eq (
		'Test of RECURS_P t within INSERT_INSTANCES',
		acs_event.recurs_p(event_id),
		't'
	);

	utAssert.eq (
		'Test of INSTANCES_EXIST_P t within INSERT_INSTANCES',
		acs_event.instances_exist_p(recurrence_id),
		't'
	);

	-- Count instances
	select count(*) 
	into instance_count
	from acs_events
	where recurrence_id =  ut_insert_instances.recurrence_id;

	dbms_output.put_line('Instances: ' || instance_count);

	utAssert.eqquery (
		'Test count of instances in INSERT_INSTANCES',
		'select count(*) from acs_events
		where recurrence_id = ' || recurrence_id,
		'select 9 from dual'
	);
	
	-- Check that instances match except for dates
	utAssert.eqquery (
		'Test instances in INSERT_INSTANCES',
		'select count(*) from (select name, description, activity_id 
							   from acs_events
							   where recurrence_id = ' || recurrence_id ||
							   'group by name, description, activity_id)',
		'select 1 from dual'
	);
	
	-- Check dates
	-- Just print 'em out and eyeball 'em for now.
	for events in event_cursor
		loop
			dbms_output.put_line(events.name || ' - ' || 
								 to_char(events.start_date, 'YYYY-MM-DD HH24:MI'));
		end loop;

	-- Clean up
	acs_event.delete_all(event_id);
	recurrence.del(recurrence_id);
	acs_activity.del(activity_id);
	timespan.del(timespan_id);
   END ut_INSERT_INSTANCES;

--     PROCEDURE ut_INSTANCES_EXIST_P IS
--     BEGIN
--        utAssert.this (
--  	 'Test of INSTANCES_EXIST_P',
--  	       ACS_EVENT.INSTANCES_EXIST_P(
--  	    RECURRENCE_ID => ''
--  	    )
--  	 );
--     END ut_INSTANCES_EXIST_P;

--     PROCEDURE ut_NEW IS
--     BEGIN
--        utAssert.this (
--  	 'Test of NEW',
--  	       ACS_EVENT.NEW(
--  	    EVENT_ID => ''
--  	    ,
--  	    NAME => ''
--  	    ,
--  	    DESCRIPTION => ''
--  	    ,
--  	    TIMESPAN_ID => ''
--  	    ,
--  	    ACTIVITY_ID => ''
--  	    ,
--  	    RECURRENCE_ID => ''
--  	    ,
--  	    OBJECT_TYPE => ''
--  	    ,
--  	    CREATION_DATE => ''
--  	    ,
--  	    CREATION_USER => ''
--  	    ,
--  	    CREATION_IP => ''
--  	    ,
--  	    CONTEXT_ID => ''
--  	    )
--  	 );
--     END ut_NEW;

--     PROCEDURE ut_PARTY_MAP IS
--     BEGIN
--  	    ACS_EVENT.PARTY_MAP (
--  	    EVENT_ID => ''
--  	    ,
--  	    PARTY_ID => ''
--         );

--        utAssert.this (
--  	 'Test of PARTY_MAP',
--  	 '<boolean expression>'
--  	 );
--     END ut_PARTY_MAP;

--     PROCEDURE ut_PARTY_UNMAP IS
--     BEGIN
--  	    ACS_EVENT.PARTY_UNMAP (
--  	    EVENT_ID => ''
--  	    ,
--  	    PARTY_ID => ''
--         );

--        utAssert.this (
--  	 'Test of PARTY_UNMAP',
--  	 '<boolean expression>'
--  	 );
--     END ut_PARTY_UNMAP;

--     PROCEDURE ut_RECURS_P IS
--     BEGIN
--        utAssert.this (
--  	 'Test of RECURS_P',
--  	       ACS_EVENT.RECURS_P(
--  	    EVENT_ID => ''
--  	    )
--  	 );
--     END ut_RECURS_P;

--     PROCEDURE ut_SHIFT IS
--     BEGIN
--  	    ACS_EVENT.SHIFT (
--  	    EVENT_ID => ''
--  	    ,
--  	    START_OFFSET => ''
--  	    ,
--  	    END_OFFSET => ''
--         );

--        utAssert.this (
--  	 'Test of SHIFT',
--  	 '<boolean expression>'
--  	 );
--     END ut_SHIFT;

--     PROCEDURE ut_SHIFT_ALL1 IS
--     BEGIN
--  	    ACS_EVENT.SHIFT_ALL (
--  	    EVENT_ID => ''
--  	    ,
--  	    START_OFFSET => ''
--  	    ,
--  	    END_OFFSET => ''
--         );

--        utAssert.this (
--  	 'Test of SHIFT_ALL',
--  	 '<boolean expression>'
--  	 );
--     END ut_SHIFT_ALL1;

--     PROCEDURE ut_SHIFT_ALL2 IS
--     BEGIN
--  	    ACS_EVENT.SHIFT_ALL (
--  	    RECURRENCE_ID => ''
--  	    ,
--  	    START_OFFSET => ''
--  	    ,
--  	    END_OFFSET => ''
--         );

--        utAssert.this (
--  	 'Test of SHIFT_ALL',
--  	 '<boolean expression>'
--  	 );
--     END ut_SHIFT_ALL2;

--     PROCEDURE ut_TIMESPAN_SET IS
--     BEGIN
--  	    ACS_EVENT.TIMESPAN_SET (
--  	    EVENT_ID => ''
--  	    ,
--  	    TIMESPAN_ID => ''
--         );

--        utAssert.this (
--  	 'Test of TIMESPAN_SET',
--  	 '<boolean expression>'
--  	 );
--   END ut_TIMESPAN_SET;
	 
	 begin
		date1 := to_date('2000-01-03 13:00', 'YYYY-MM-DD HH24:MI');
		date2 := to_date('2000-01-03 14:00', 'YYYY-MM-DD HH24:MI');

END ut_acs_event;
/
show errors


