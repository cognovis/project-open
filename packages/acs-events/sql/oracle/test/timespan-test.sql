--
-- acs-events/sql/test/-test.sql
--
-- PL/SQL regression tests for 
--
-- Note: These tests use the utPLSQL regression package available at:
-- ftp://ftp.oreilly.com/published/oreilly/oracle/utplsql/utInstall.zip
--
-- @author W. Scott Meeks (smeeks@arsdigita.com)
--
-- @creation-date 2000-11-29
--
-- @cvs-id $Id: timespan-test.sql,v 1.2 2003/09/30 12:10:02 mohanp Exp $

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
--     @timespan-test
--
-- To actually execute the tests, type:
--
--     exec utplsql.test('time_interval');
--     exec utplsql.test('timespan');

set serveroutput on size 1000000 format wrapped
exec utplsql.autocompile (false);
exec utplsql.setdir('/web/servicename/packages/acs-events/sql/test');

-- we need these here or else the PL/SQL won't compile.

drop table ut_time_intervals;
create table ut_time_intervals as select * from time_intervals;

drop table ut_interval_ids;
create table ut_interval_ids as select interval_id from time_intervals;

-- Note: this package was created by hand
create or replace package ut_time_interval
as
    procedure ut_setup;

    procedure ut_teardown;

	procedure ut_copy;

	procedure ut_overlaps_p;

	procedure ut_shift;

	procedure ut_edit;

	procedure ut_delete;

	procedure ut_new;

	procedure ut_eq;
end ut_time_interval;
/
show errors

create or replace package body ut_time_interval
as
	-- Common dates for testing
	date1 date;
	date2 date;
	date3 date;
	date4 date;

    procedure ut_setup
    is
    begin
		ut_teardown;
        dbms_output.put_line('Setting up...');
		-- create copy of the table
		execute immediate 'create table ut_time_intervals as
			select * from time_intervals';
		-- Intervals to be saved during cleanup
		execute immediate 'create table ut_interval_ids as
			select interval_id from time_intervals';
	utassert.eqtable (
	    msg_in => 'Comparing copied data for time interval',
	    check_this_in => 'time_intervals',
	    against_this_in => 'ut_time_intervals'
        );
	end ut_setup;

    procedure ut_teardown
    is
    begin
        dbms_output.put_line('Tearing down...');
		-- clean out the test tables
		begin
			-- Delete intervals added by tests
			delete time_intervals
			where interval_id not in (select interval_id
									  from ut_interval_ids);
			-- Drop test tables
			execute immediate 'drop table ut_time_intervals cascade constraints';
			execute immediate 'drop table ut_interval_ids cascade constraints';
			exception
              when others
              then
                  null;
        end;
    end ut_teardown;

    procedure ut_new
    is
		new_interval_id time_intervals.interval_id%TYPE;
    begin
        dbms_output.put_line('Testing new...');
        -- Tests just the common functionality of the API.

	-- create a time interval
	utassert.isnotnull (
	    msg_in => 'Creating a new test time interval',
	    check_this_in => time_interval.new(date1, date2)
        );

	-- Verify that the API does the correct insert.
	select timespan_seq.currval into new_interval_id from dual;
	insert into ut_time_intervals(interval_id, start_date, end_date)
        values(new_interval_id, date1, date2);
	
	utassert.eqtable (
	    msg_in => 'Comparing created data for time interval',
	    check_this_in => 'time_intervals',
	    against_this_in => 'ut_time_intervals'
        );

    end ut_new;

    procedure ut_delete
    is
		new_interval_id time_intervals.interval_id%TYPE;
    begin
        dbms_output.put_line('Testing delete...');

	    new_interval_id := time_interval.new(date1, date2);

	-- delete the row.
	time_interval.del(interval_id => new_interval_id);

 	-- verify time interval not there.
 	utassert.eqtable (
 	    msg_in => 'Delete verification',
 	    check_this_in => 'ut_time_intervals',
 	    against_this_in => 'time_intervals'
        );

    end ut_delete;    

	procedure ut_eq
    is
		interval_1_id time_intervals.interval_id%TYPE;
		interval_2_id time_intervals.interval_id%TYPE;
		interval_3_id time_intervals.interval_id%TYPE;
    begin
        dbms_output.put_line('Testing eq...');

	    interval_1_id := time_interval.new(date1, date2);
	    interval_2_id := time_interval.new(date1, date2);
	    interval_3_id := time_interval.new(date2, date3);
	 
		utAssert.this (
			'Comparing equivalent dates',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		utAssert.eq (
			'Comparing different dates',
			time_interval.eq(interval_1_id, interval_3_id),
			false
		);

		-- Clean up
		time_interval.del(interval_1_id);
		time_interval.del(interval_2_id);
		time_interval.del(interval_3_id);
	end ut_eq;

	procedure ut_edit
	is
		interval_id time_intervals.interval_id%TYPE;
	begin
        dbms_output.put_line('Testing edit...');
		
		-- create a new time interval to edit;
	    interval_id := time_interval.new(date1, date2);

		-- Edit the time interval
		time_interval.edit(interval_id => interval_id,
						   start_date => date2,
						   end_date => date3);

		-- Verify
		insert into ut_time_intervals(interval_id, start_date, end_date)
			values(interval_id, date2, date3);

		utassert.eqtable (
			msg_in => 'Comparing edited data for time interval',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

		-- Edit the time interval
		time_interval.edit(interval_id => interval_id,
						   start_date => date1);

		-- Verify
		update ut_time_intervals
		set start_date = date1
		where interval_id = ut_edit.interval_id;

		utassert.eqtable (
			msg_in => 'Comparing edited data for time interval',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

		-- Edit the time interval
		time_interval.edit(interval_id => interval_id,
						   end_date => date2);

		-- Verify
		update ut_time_intervals
		set end_date = date2
		where interval_id = ut_edit.interval_id;

		utassert.eqtable (
			msg_in => 'Comparing edited data for time interval',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

		-- Edit the time interval
		time_interval.edit(interval_id => interval_id);

		-- Verify
		utassert.eqtable (
			msg_in => 'Comparing edited data for time interval',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

	end ut_edit;

	procedure ut_shift
	is
		interval_id time_intervals.interval_id%TYPE;
	begin
        dbms_output.put_line('Testing shift...');
		
		-- create a new time interval to shift;
	    interval_id := time_interval.new(date1, date2);

		-- Shift the time interval
		time_interval.shift(interval_id, 1, 2);

		-- Verify
		insert into ut_time_intervals (interval_id, start_date, end_date)
		values (interval_id, date2, date4);

		-- create a new time interval to shift;
	    interval_id := time_interval.new(date1);

		-- Shift the time interval
		time_interval.shift(
			interval_id => interval_id, 
			end_offset => 2
		);

		-- Verify
		insert into ut_time_intervals (interval_id, start_date, end_date)
		values (interval_id, date1, null);

		utassert.eqtable (
			msg_in => 'Comparing shifted data for time intervals',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );
		
	end ut_shift;

	procedure ut_overlaps_p
	is
		interval_1_id time_intervals.interval_id%TYPE;
		interval_2_id time_intervals.interval_id%TYPE;
	begin
		-- Note: not yet 100% branch coverage....

        dbms_output.put_line('Testing overlaps_p...');
		
		-- create new time intervals to test;
	    interval_1_id := time_interval.new();
	    interval_2_id := time_interval.new(date1, date2);

		-- Test the time interval
		utassert.eq (
			msg_in => 'Null interval overlaps',
			check_this_in => 
				time_interval.overlaps_p(interval_1_id, interval_2_id),
			against_this_in => 't'
		);

		-- Update 1st interval
		time_interval.edit(
			interval_id => interval_1_id,
			start_date => date2
		);

		-- Test the time intervals
		utassert.eq (
			msg_in => 'Null start_2 overlaps',
			check_this_in => 
				time_interval.overlaps_p (
					interval_id => interval_1_id, 
					start_date => null,
					end_date => date3
				),
			against_this_in => 't'
		);
		utassert.eq (
			msg_in => 'Null start_2 no overlap',
			check_this_in => 
				time_interval.overlaps_p (
					interval_id => interval_1_id, 
					start_date => null,
					end_date => date1
				),
			against_this_in => 'f'
		);

		utassert.eq (
			msg_in => 'No nulls, no overlap',
			check_this_in => 
				time_interval.overlaps_p (
					interval_id => interval_2_id, 
					start_date => date3,
					end_date => date4
				),
			against_this_in => 'f'
		);
		utassert.eq (
			msg_in => 'No nulls, overlap 1 before 2',
			check_this_in => 
				time_interval.overlaps_p (
					start_1 => date1,
					end_1 => date3,
					start_2 => date2,
					end_2 => date4
				),
			against_this_in => 't'
		);
		utassert.eq (
			msg_in => 'No nulls, overlap 2 before 1',
			check_this_in => 
				time_interval.overlaps_p (
					start_1 => date2,
					end_1 => date4,
					start_2 => date1,
					end_2 => date3
				),
			against_this_in => 't'
		);

		-- Delete the test intervals
		time_interval.del(interval_1_id);
		time_interval.del(interval_2_id);

	end ut_overlaps_p;

	procedure ut_copy
	is
		interval_id time_intervals.interval_id%TYPE;
		new_interval_id time_intervals.interval_id%TYPE;
	begin
        dbms_output.put_line('Testing copy...');
		
		-- create a new time interval to copy;
	    interval_id := time_interval.new(date1, date2);

		-- Copy the time interval
		new_interval_id := time_interval.copy(interval_id);

		-- Insert for testing
		insert into ut_time_intervals (interval_id, start_date, end_date)
		values (interval_id, date1, date2);
		insert into ut_time_intervals (interval_id, start_date, end_date)
		values (new_interval_id, date1, date2);

		-- Verify copies
		utassert.eqtable (
			msg_in => 'Comparing copied data for time intervals',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

		-- Copy the time interval with offset
		new_interval_id := time_interval.copy(interval_id, 1);

		-- Insert for testing
		insert into ut_time_intervals (interval_id, start_date, end_date)
		values (new_interval_id, date2, date3);

		-- Verify copies
		utassert.eqtable (
			msg_in => 'Comparing copied and shifted data for time intervals',
			check_this_in => 'time_intervals',
			against_this_in => 'ut_time_intervals'
        );

	end ut_copy;

	begin
		date1 := '2000-01-01';
		date2 := '2000-01-02';
		date3 := '2000-01-03';
		date4 := '2000-01-04';

end ut_time_interval;
/
show errors

-- we need these here or else the PL/SQL won't compile.

drop table ut_timespans;
create table ut_timespans as select * from timespans;

drop table ut_timespan_ids;
create table ut_timespan_ids as select timespan_id from timespans;

-- Note: this package was created starting from 
-- utGen.testpkg('timespan');

CREATE OR REPLACE PACKAGE ut_timespan
IS
   PROCEDURE ut_setup;
   PROCEDURE ut_teardown;

   -- For each program to test...
     PROCEDURE ut_COPY;
     PROCEDURE ut_DELETE;
     PROCEDURE ut_EXISTS_P;
     PROCEDURE ut_INTERVAL_DELETE;
     PROCEDURE ut_JOIN1;
     PROCEDURE ut_JOIN2;
     PROCEDURE ut_JOIN_INTERVAL;
     PROCEDURE ut_MULTI_INTERVAL_P;
   PROCEDURE ut_NEW1;
   PROCEDURE ut_NEW2;
   PROCEDURE ut_OVERLAPS_INTERVAL_P;
   PROCEDURE ut_OVERLAPS_P1;
   PROCEDURE ut_OVERLAPS_P2;
END ut_timespan;
/

CREATE OR REPLACE PACKAGE BODY ut_timespan
IS
	-- Common dates for testing
	date1 date;
	date2 date;
	date3 date;
	date4 date;
	date5 date;

   PROCEDURE ut_setup
   IS
   BEGIN
		ut_teardown;
        dbms_output.put_line('Setting up...');
		-- create copy of the table
		execute immediate 'create table ut_timespans as
			select * from timespans';
		-- Intervals to be saved during cleanup
		execute immediate 'create table ut_timespan_ids as
			select timespan_id from timespans';
	utassert.eqtable (
	    msg_in => 'Comparing copied data for timespan',
	    check_this_in => 'timespans',
	    against_this_in => 'ut_timespans'
        );
   END ut_setup;

   PROCEDURE ut_teardown
   IS
   BEGIN
        dbms_output.put_line('Tearing down...');
		-- clean out the test tables
		begin
			-- Delete intervals added by tests
			delete time_intervals
			where interval_id in 
				  (select interval_id
				   from timespans
				   where timespan_id not in (select timespan_id
											 from ut_timespan_ids));
			-- Drop test tables
			execute immediate 'drop table ut_timespans cascade constraints';
			execute immediate 'drop table ut_timespan_ids cascade constraints';
			exception
              when others
              then
                  null;
        end;
   END ut_teardown;

   -- For each program to test...
   PROCEDURE ut_COPY IS
	timespan_1_id timespans.timespan_id%TYPE;
	timespan_2_id timespans.timespan_id%TYPE;
	timespan_copy_id timespans.timespan_id%TYPE;
	interval_1_id time_intervals.interval_id%TYPE;
	interval_2_id time_intervals.interval_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing COPY...');

	  timespan_1_id := timespan.new(date1, date2);

	  select interval_id
	  into interval_1_id
	  from time_intervals
	  where interval_id = (select interval_id
						   from timespans
						   where timespan_id = timespan_1_id);

	  timespan_2_id := timespan.new(date2, date3);

	  timespan_copy_id := timespan.copy(timespan_1_id);

	  select interval_id
	  into interval_2_id
	  from time_intervals
	  where interval_id = (select interval_id
						   from timespans
						   where timespan_id = timespan_copy_id);
	  
      utAssert.eq (
		'Test of COPY no offset',
	    time_interval.eq(interval_1_id, interval_2_id),
		true
	 );

	 timespan.del(timespan_copy_id);

	 timespan_copy_id := timespan.copy(timespan_1_id, 1);

	  select interval_id
	  into interval_1_id
	  from time_intervals
	  where interval_id = (select interval_id
						   from timespans
						   where timespan_id = timespan_2_id);
	  select interval_id
	  into interval_2_id
	  from time_intervals
	  where interval_id = (select interval_id
						   from timespans
						   where timespan_id = timespan_copy_id);

      utAssert.eq (
		'Test of COPY w/ offset',
	    time_interval.eq(interval_1_id, interval_2_id),
		true
	 );

	 -- Cleanup
	 timespan.del(timespan_1_id);
	 timespan.del(timespan_2_id);
	 timespan.del(timespan_copy_id);
   END ut_COPY;

   PROCEDURE ut_DELETE IS
	timespan_id timespans.timespan_id%TYPE;
   BEGIN
        dbms_output.put_line('Testing DELETE...');
	timespan_id := timespan.new(date1, date2);

	    TIMESPAN.DELETE (
	    TIMESPAN_ID => timespan_id
       );

      utAssert.eqtable (
		'Test of DELETE',
		'ut_timespans',
		'timespans'
	  );
   END ut_DELETE;

   PROCEDURE ut_EXISTS_P IS
	  timespan_id timespans.timespan_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing EXISTS_P...');
	  timespan_id := timespan.new(date1, date2);

      utAssert.eq (
		'Test of EXISTS_P true',
	       TIMESPAN.EXISTS_P(
	    TIMESPAN_ID => timespan_id
	    ),
		't'
	 );

	 timespan.del(timespan_id);

      utAssert.eq (
		'Test of EXISTS_P false',
	       TIMESPAN.EXISTS_P(
	    TIMESPAN_ID => timespan_id
	    ),
		'f'
	 );
   END ut_EXISTS_P;

   PROCEDURE ut_INTERVAL_DELETE IS
	  timespan_id timespans.timespan_id%TYPE;
	  interval_id time_intervals.interval_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing INTERVAL_DELETE...');

	  timespan_id := timespan.new(date1, date2);

	  select interval_id into interval_id
	  from timespans
	  where timespan_id = ut_INTERVAL_DELETE.timespan_id;


	    TIMESPAN.INTERVAL_DELETE (
	    TIMESPAN_ID => timespan_id
	    ,
	    INTERVAL_ID => interval_id
       );

      utAssert.eq (
	 'Test of INTERVAL_DELETE',
	 timespan.exists_p(timespan_id),
	 'f'
	 );
   END ut_INTERVAL_DELETE;

   PROCEDURE ut_JOIN1 IS
	timespan_1_id timespans.timespan_id%TYPE;
	timespan_2_id timespans.timespan_id%TYPE;
	interval_1_id time_intervals.interval_id%TYPE;
	interval_2_id time_intervals.interval_id%TYPE;
   BEGIN
        dbms_output.put_line('Testing JOIN1...');
		timespan_1_id := timespan.new(date1, date2);
		timespan_2_id := timespan.new(date3, date4);

		select interval_id into interval_1_id
		from timespans
		where timespan_id = timespan_1_id;

	    timespan.join(timespan_1_id, timespan_2_id);

		utAssert.eqquery (
			'JOIN1: interval count = 2',
			'select count(*) 
			 from timespans
			 where timespan_id = ' || timespan_1_id,
			'select 2 from dual'
		);

		select min(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;
				
		utAssert.this (
			'JOIN1: match 1st interval',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		select interval_id into interval_1_id
		from timespans
		where timespan_id = timespan_2_id;

		select max(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;

		utAssert.this (
			'JOIN1: match 2nd interval',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		-- Cleanup
		timespan.del(timespan_1_id);
		timespan.del(timespan_2_id);
   END ut_JOIN1;

   PROCEDURE ut_JOIN2 IS
	timespan_1_id timespans.timespan_id%TYPE;
	interval_1_id time_intervals.interval_id%TYPE;
	interval_2_id time_intervals.interval_id%TYPE;
   BEGIN
        dbms_output.put_line('Testing JOIN2...');
		timespan_1_id := timespan.new(date1, date2);

		select interval_id into interval_1_id
		from timespans
		where timespan_id = timespan_1_id;

	    timespan.join(timespan_1_id, date3, date4);

		utAssert.eqquery (
			'JOIN2: interval count = 2',
			'select count(*) 
			 from timespans
			 where timespan_id = ' || timespan_1_id,
			'select 2 from dual'
		);

		select min(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;
				
		utAssert.this (
			'JOIN2: match 1st interval',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		interval_1_id := time_interval.new(date3, date4);

		select max(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;

		utAssert.this (
			'JOIN2: match 2nd interval',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		-- Cleanup
		timespan.del(timespan_1_id);
		time_interval.del(interval_1_id);
   END ut_JOIN2;

   PROCEDURE ut_JOIN_INTERVAL IS
	timespan_1_id timespans.timespan_id%TYPE;
	interval_1_id time_intervals.interval_id%TYPE;
	interval_2_id time_intervals.interval_id%TYPE;
	interval_3_id time_intervals.interval_id%TYPE;
   BEGIN
        dbms_output.put_line('Testing JOIN_INTERVAL...');
		timespan_1_id := timespan.new(date1, date2);
		interval_3_id := time_interval.new(date3, date4);

		select interval_id into interval_1_id
		from timespans
		where timespan_id = timespan_1_id;

	    timespan.join_interval(timespan_1_id, interval_3_id);

		utAssert.eqquery (
			'JOIN_INTERVAL: interval count = 2',
			'select count(*) 
			 from timespans
			 where timespan_id = ' || timespan_1_id,
			'select 2 from dual'
		);

		select min(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;
				
		utAssert.this (
			'JOIN_INTERVAL: match 1st interval',
			time_interval.eq(interval_1_id, interval_2_id)
		);

		select max(interval_id) into interval_2_id
		from timespans
		where timespan_id = timespan_1_id;

		utAssert.this (
			'JOIN1: match 2nd interval',
			time_interval.eq(interval_2_id, interval_3_id)
		);

		-- Cleanup
		timespan.del(timespan_1_id);
		time_interval.del(interval_3_id);
   END ut_JOIN_INTERVAL;

   PROCEDURE ut_MULTI_INTERVAL_P IS
	timespan_id timespans.timespan_id%TYPE;
	interval_id time_intervals.interval_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing MULTI_INTERVAL_P...');

	  timespan_id := timespan.new(date1, date2);
	  interval_id := time_interval.new(date1, date2);

      utAssert.eq (
		'Test of MULTI_INTERVAL_P 1',
	       TIMESPAN.MULTI_INTERVAL_P(
				TIMESPAN_ID => timespan_id
	    ),
		'f'
	 );
	 
	 timespan.join_interval(timespan_id, interval_id);

      utAssert.eq (
		'Test of MULTI_INTERVAL_P 2',
	       TIMESPAN.MULTI_INTERVAL_P(
				TIMESPAN_ID => timespan_id
	    ),
		't'
	 );

	 -- Cleanup
		timespan.del(timespan_id);
		time_interval.del(interval_id);
 END ut_MULTI_INTERVAL_P;

   PROCEDURE ut_NEW1 IS
	interval_id time_intervals.interval_id%TYPE;
	timespan_id timespans.timespan_id%TYPE;
	new_interval_id time_intervals.interval_id%TYPE;
   BEGIN
        dbms_output.put_line('Testing NEW1...');
	interval_id := time_interval.new(date1, date2);
	timespan_id := TIMESPAN.NEW(
						INTERVAL_ID => interval_id
					);
	select interval_id into new_interval_id
	from timespans
	where timespan_id = ut_NEW1.timespan_id;

	utAssert.this (
		'Test of NEW w/ interval',
		time_interval.eq(interval_id, new_interval_id)
	);

	-- Cleanup
	time_interval.del(interval_id);
	timespan.del(timespan_id);
   END ut_NEW1;

   PROCEDURE ut_NEW2 IS
	timespan_id timespans.timespan_id%TYPE;
	interval time_intervals%ROWTYPE;
   BEGIN
        dbms_output.put_line('Testing NEW2...');
	timespan_id := TIMESPAN.NEW(
	    START_DATE => date1
	    ,
	    END_DATE => date2
	 );

	 utAssert.eqquery (
		'Test of NEW w/ dates',
		'select start_date, end_date 
		 from time_intervals
		 where interval_id = (select interval_id
							  from timespans
							  where timespan_id = ' || timespan_id || ')',
		'select to_date(''' || date1 || '''), to_date(''' || date2 || ''') from dual'
	);
	-- Cleanup
	timespan.del(timespan_id);
   END ut_NEW2;

   PROCEDURE ut_OVERLAPS_INTERVAL_P IS
	timespan_id timespans.timespan_id%TYPE;
	interval_1_id time_intervals.interval_id%TYPE;
	interval_2_id time_intervals.interval_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing OVERLAPS_INTERVAL_P...');
	  
	  timespan_id := timespan.new(date1, date3);
	  interval_1_id := time_interval.new(date2, date4);
	  interval_2_id := time_interval.new(date4, date5);

      utAssert.eq (
		'Test of OVERLAPS_INTERVAL_P t',
	       TIMESPAN.OVERLAPS_INTERVAL_P(
				TIMESPAN_ID => timespan_id
				,
				INTERVAL_ID => interval_1_id
		   ),
		't'
	 );

      utAssert.eq (
		'Test of OVERLAPS_INTERVAL_P f',
	       TIMESPAN.OVERLAPS_INTERVAL_P(
	    TIMESPAN_ID => timespan_id
	    ,
	    INTERVAL_ID => interval_2_id
	    ),
		'f'
	 );

	-- Cleanup
	timespan.del(timespan_id);
	time_interval.del(interval_1_id);
	time_interval.del(interval_2_id);
   END ut_OVERLAPS_INTERVAL_P;

   PROCEDURE ut_OVERLAPS_P1 IS
	timespan_1_id timespans.timespan_id%TYPE;
	timespan_2_id timespans.timespan_id%TYPE;
	timespan_3_id timespans.timespan_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing OVERLAPS_P1...');

	  timespan_1_id := timespan.new(date1, date3);
	  timespan_2_id := timespan.new(date2, date4);
	  timespan_3_id := timespan.new(date4, date5);

      utAssert.eq (
		'Test of OVERLAPS_P t',
		TIMESPAN.OVERLAPS_P(
			TIMESPAN_1_ID => timespan_1_id
			,
			TIMESPAN_2_ID => timespan_2_id
	    ),
		't'
	 );

      utAssert.eq (
		'Test of OVERLAPS_P f',
		TIMESPAN.OVERLAPS_P(
			TIMESPAN_1_ID => timespan_1_id
			,
			TIMESPAN_2_ID => timespan_3_id
	    ),
		'f'
	 );

	-- Cleanup
	timespan.del(timespan_1_id);
	timespan.del(timespan_2_id);
	timespan.del(timespan_3_id);
   END ut_OVERLAPS_P1;

   PROCEDURE ut_OVERLAPS_P2 IS
	timespan_id timespans.timespan_id%TYPE;
   BEGIN
      dbms_output.put_line('Testing OVERLAPS_P2...');

	  timespan_id := timespan.new(date1, date3);

      utAssert.eq (
		'Test of OVERLAPS_P t',
		TIMESPAN.OVERLAPS_P(
			TIMESPAN_ID => timespan_id
			,
			START_DATE => date2
			,
			END_DATE => date4
	    ),
		't'
	 );

      utAssert.eq (
		'Test of OVERLAPS_P f',
		TIMESPAN.OVERLAPS_P(
			TIMESPAN_ID => timespan_id
			,
			START_DATE => date4
			,
			END_DATE => date5
	    ),
		'f'
	 );

	-- Cleanup
	timespan.del(timespan_id);
   END ut_OVERLAPS_P2;

	begin
		date1 := '2000-01-01';
		date2 := '2000-01-02';
		date3 := '2000-01-03';
		date4 := '2000-01-04';
		date5 := '2000-01-05';

END ut_timespan;
/
show errors
