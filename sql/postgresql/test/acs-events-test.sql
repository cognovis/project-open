-- packages/acs-events/sql/postgres/test/acs-events-test.sql
--
-- Regression tests for ACS Events
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id$

-- Note: These tests use the semi-ported utPLSQL regression package
\i utest-create.sql

create function ut__setup()
returns integer as '
begin

	raise notice ''Setting up acs-events-test...'';

	-- create copies of the tables
	-- No need for excute here?
	create table ut_acs_events as
		  select * from acs_events;
	create table ut_acs_event_party_map as
		  select * from acs_event_party_map;

	-- Auxiliary tables, so we do not mess up existing data (but.. why would you want to run
	-- a regression test on a site with important data?)
	create table ut_timespan_ids as
	          select timespan_id from timespans;
	create table ut_activity_ids as
	          select activity_id from acs_activities;
	create table ut_recurrence_ids as
	          select recurrence_id from recurrences;
	create table ut_event_ids as
	          select event_id from acs_events;


	return 0;

end;' language 'plpgsql';


create function ut__teardown()
returns integer as '
begin

	raise notice ''Tearing down acs-events-test...'';

	-- remove copies of the tables
	-- cascade does not work?
        drop table ut_acs_events;
        drop table ut_acs_event_party_map;
	drop table ut_timespan_ids;
	drop table ut_activity_ids;
	drop table ut_recurrence_ids;
	drop table ut_event_ids;

	return 0;

end;' language 'plpgsql';

-- This is an example of a simple custom recurrence function: recur every three days
create function recur_every3(timestamptz,integer)
returns timestamptz as '
declare
	recur_every3__date	alias for $1;
	recur_every3__interval	alias for $2;
begin
	return  recur_every3__date + to_interval(3*recur_every3__interval,''days'');

end;' language 'plpgsql';



-- The test of insert_instances has been augmented to test 
-- other routines.  Specifically new, delete, delete_all, 
-- timespan_set, activity_set, get_name, get_description, 
-- party_map, party_unmap, recurs_p, instances_exist_p
create function ut__insert_instances()
returns integer as '
declare
	date1						timestamptz := ''2000-03-23 13:00'';
	date2						timestamptz := ''2000-03-23 14:00'';
	insert_instances__timespan_id			acs_events.timespan_id%TYPE;
	insert_instances__activity_id			acs_events.activity_id%TYPE;
	insert_instances__recurrence_id			acs_events.recurrence_id%TYPE;
	insert_instances__event_id			acs_events.event_id%TYPE;
	v_instance_count				integer;
	rec_events					record;
	v_dummy_id					integer;
begin

	raise notice ''Testing INSERT_INSTANCES...'';

	-- Create event components
	insert_instances__timespan_id := timespan__new(date1, date2);
	insert_instances__recurrence_id := recurrence__new(''week'',
						           1,
							   ''1 3'',
							   to_date(''2000-04-21'',''YYYY-MM-DD''),
							   null
							   );
							   
        -- Note to self: we still need to test acs-activity API
	insert_instances__activity_id := acs_activity__new(null,
							      ''Testing (pre-edit)'',
							      ''Making sure the acs_activity code works (pre-edit)'',
							      ''t'',
                                                              null,
							      ''acs_activity'',
							      now(),
							      null,
							      null,
							      null
							      );

	-- Check acs_activity__name
	PERFORM ut_assert__eq (''Test of activity__name'',
			       acs_activity__name(insert_instances__activity_id),
			       ''Testing (pre-edit)''
			       );


	-- Check acs_activity__edit
	PERFORM acs_activity__edit(insert_instances__activity_id,''Testing (edited)'',null,null);
	PERFORM ut_assert__eq (''Test of activity__edit'',
			       acs_activity__name(insert_instances__activity_id),
			       ''Testing (edited)''
			       );

        -- Since there is no API for getting the description and html_p...
	for rec_events in 
	    select * from acs_activities
		where activity_id = insert_instances__activity_id
	loop
	    PERFORM ut_assert__eq (''Test of activity__edit (description)'',
			            rec_events.description,
			           ''Making sure the acs_activity code works (pre-edit)'');

	    PERFORM ut_assert__eq (''Test of activity__edit (html_p)'',
			            rec_events.html_p,
			           ''t'');
	end loop;

        -- Try to edit everything instead
	PERFORM  acs_activity__edit(insert_instances__activity_id,
				    ''Testing'',
				    ''Making sure the acs_activity code works'',
				    ''f'');

	PERFORM ut_assert__eq (''Test of activity__edit'',
			       acs_activity__name(insert_instances__activity_id),
			       ''Testing''
			       );

        -- Since there is no API for getting the description and html_p...
	for rec_events in 
	    select * from acs_activities
		where activity_id = insert_instances__activity_id
	loop
	    PERFORM ut_assert__eq (''Test of activity__edit (description)'',
			            rec_events.description,
			           ''Making sure the acs_activity code works'');

	    PERFORM ut_assert__eq (''Test of activity__edit (html_p)'',
			            rec_events.html_p,
			           ''f'');
	end loop;


        -- We test mapping of objects.  We choose some object from acs_objects table to map.
	-- Since we know that the activity object was just created, we might as well pick that one
	-- (i.e., map activity to itself).
	PERFORM  acs_activity__object_map(insert_instances__activity_id,
					  insert_instances__activity_id);


	-- There should be one entry in the mapping table
	PERFORM ut_assert__eqquery (''Test count of object mappings in acs_activity_object_map'',
				    ''select count(*) from acs_activity_object_map
				      where activity_id = '' || insert_instances__activity_id,
				    ''select 1 from dual''
				    );

	-- Create a null event for test of existence functions
	insert_instances__event_id := acs_event__new(null,
				                     null,
				                     null,
                                                     null,
						     null,
						     null,
						     null,
						     null,
						     ''acs_event'',
						     now(),
						     null,
						     null,
						     null
						     );



	-- Do some testing while we are here
	PERFORM ut_assert__eq (''Test of INSTANCES_EXIST_P f within INSERT_INSTANCES'',
			       acs_event__instances_exist_p(insert_instances__recurrence_id),
			       ''f''
			       );

	insert into ut_acs_events (event_id)
	values (insert_instances__event_id);

	PERFORM ut_assert__eqtable (''Test of NEW within INSERT_INSTANCES'',
				    ''ut_acs_events'',
				    ''acs_events''
				    );

	PERFORM ut_assert__isnull (''Test of GET_NAME null within INSERT_INSTANCES'',
				   acs_event__get_name(insert_instances__event_id)
				   );
					
	PERFORM ut_assert__isnull (''Test of GET_DESCRIPTION null within INSERT_INSTANCES'',
				   acs_event__get_description(insert_instances__event_id)
				   );
					
	PERFORM ut_assert__eq (''Test of RECURS_P f within INSERT_INSTANCES'',
			       acs_event__recurs_p(insert_instances__event_id),
			       ''f''
			       );


	-- We now put values into the acs_events table
	PERFORM acs_event__timespan_set(insert_instances__event_id, insert_instances__timespan_id);
	PERFORM acs_event__activity_set(insert_instances__event_id, insert_instances__activity_id);

	-- No acs_event__recurrence_set?
	update acs_events
	set recurrence_id = insert_instances__recurrence_id
	where event_id = insert_instances__event_id;
	
	-- Fill up the shadow table
	update ut_acs_events
	set timespan_id = insert_instances__timespan_id,
		activity_id = insert_instances__activity_id,
		recurrence_id = insert_instances__recurrence_id
	where event_id = insert_instances__event_id;

	-- Check if functions performed accordingly
	PERFORM ut_assert__eqtable (''Test of SET procedures within INSERT_INSTANCES'',
				    ''ut_acs_events'',
				    ''acs_events''
				    );

	-- If so, we should now be able to get the activity name
	PERFORM ut_assert__eq (''Test of GET_NAME from activity within INSERT_INSTANCES'',
			       acs_event__get_name(insert_instances__event_id),
			       ''Testing''
			       );
				
	-- and the description	
	PERFORM ut_assert__eq (''Test of GET_DESCRIPTION from activity within INSERT_INSTANCES'',
			       acs_event__get_description(insert_instances__event_id),
			       ''Making sure the acs_activity code works''
			       );

	
	-- More testing of acs-events value insertion 
	update acs_events
	set name = ''Further Testing'',
	    description = ''Making sure the code works correctly.''
	where event_id = insert_instances__event_id;

	PERFORM ut_assert__eq (''Test of GET_NAME from event within INSERT_INSTANCES'',
			       acs_event__get_name(insert_instances__event_id),
			       ''Further Testing''
	);
					
	PERFORM ut_assert__eq (''Test of GET_DESCRIPTION from event within INSERT_INSTANCES'',
			       acs_event__get_description(insert_instances__event_id),
			       ''Making sure the code works correctly.''
			       );

	-- Insert instances
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2000-06-02''
					    );

	-- Test for instances
	PERFORM ut_assert__eq (''Test of RECURS_P t within INSERT_INSTANCES'',
		               acs_event__recurs_p(insert_instances__event_id),
			       ''t''
			       );

	PERFORM ut_assert__eq (''Test of INSTANCES_EXIST_P t within INSERT_INSTANCES'',
			       acs_event__instances_exist_p(insert_instances__recurrence_id),
			       ''t''
			       );



	-- Count instances
	select count(*) 
	into v_instance_count
	from acs_events
	where recurrence_id =  insert_instances__recurrence_id;

	raise notice ''Instances: %'',v_instance_count;

	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 9 from dual''
				    );
	
	-- Check that instances match except for dates
	PERFORM ut_assert__eqquery (''Test instances in INSERT_INSTANCES'',
				    ''select count(*) from (select name, description, activity_id 
							    from acs_events
							    where recurrence_id = '' || 
							    insert_instances__recurrence_id ||
							   '' group by name, description, activity_id) as temp'',
				     ''select 1 from dual''
				     );


	----------------------------------------------------------------------------------------------------
	-- Check date recurrence by the week
	-- Just print them out and eyeball them for now.

	raise notice ''Check of recurrence: same day of the week (Mon and Wed), every week '';
	raise notice ''Do not forget DST starts on first Sunday in April and ends last Sunday in October.'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through %'',rec_events.name, 
			     rec_events.start_date,rec_events.end_date;
	end loop;



	-- Another test of weekly recurrence
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-10-21 09:00:00'',
						       timestamptz ''2001-10-23 10:00:00'');

	-- Check month by date (recur for the same date of the month specified in time interval)
	insert_instances__recurrence_id := recurrence__new(''week'',
						           1,
							   ''4 6'',
							   to_date(''2001-12-01'',''YYYY-MM-DD''),
							   null);

	insert_instances__event_id  := acs_event__new(null,''Weekly'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	

	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-12-25''
					    );

	-- There should be 13 instances of the weekly event
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 13 from dual''
				    );
	

	raise notice ''Check of recurrence: same day of the week (Thursday and Saturday), every week '';
	raise notice ''Do not forget DST starts on first Sunday in April and ends last Sunday in October.'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : %  through % '',rec_events.name, 
			     rec_events.start_date,rec_events.end_date;
	end loop;

	----------------------------------------------------------------------------------------------------------

	
	-- Test month_by_date recurrence
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-03-21 09:00:00'',
						       timestamptz ''2001-03-23 10:00:00'');

	-- Check month by date (recur for the same date of the month specified in time interval)
	insert_instances__recurrence_id := recurrence__new(''month_by_date'',
						           1,
							   null, -- irrelevant
							   to_date(''2001-05-01'',''YYYY-MM-DD''),
							   null);

	insert_instances__event_id  := acs_event__new(null,''month_by_date'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	

	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-04-25 00:00:00''
					    );

	-- There should be two instances (including the original), even if the cut-off date is between
	-- the last event.
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 2 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.


	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;

	-- Test month_by_date recurrence
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-10-21 09:00:00'',
						       timestamptz ''2001-10-23 10:00:00'');

	-- Check month by date (recur for the same date of the month specified in time interval)
	insert_instances__recurrence_id := recurrence__new(''month_by_date'',
						           1,
							   null, -- irrelevant
							   to_date(''2002-02-01'',''YYYY-MM-DD''),
							   null);

	insert_instances__event_id  := acs_event__new(null,''month_by_date'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	

	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2002-04-25 00:00:00''
					    );

	-- There should be four instances (including the original), even if the cut-off date is between
	-- the last event.
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 4 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;



	----------------------------------------------------------------------------------------------------------



	-- Check another recurrence type (daily recurrence)
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-03-26 09:00:00'',
						       timestamptz ''2001-03-26 10:00:00'');

	-- Check month by date (recur every day, skip every second interval)
	insert_instances__recurrence_id := recurrence__new(''day'',
						           2,    -- skip a day
							   null, -- Irrelevant
							   to_date(''2001-04-13'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''every 2 days'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-04-05 00:00:00''
					    );

	-- There should be six instances (including the original)
	-- JS: Note that 4/01/2001 is the DST switch back date, which is one of the dates in the recurrence.
	-- JS: The time format that Postres reports is still the DST format, but if we convert to non-DST 
	-- JS: then the time is ok.  In particular, Postgres reports 10:00am GMT-4, which converts to
	-- JS: the expected 9:00 GMT-5 in the non-DST format that should apply on 4/01/2001. 
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 6 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;


	-- Check another recurrence type (daily recurrence)
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-10-26 09:00:00'',
						       timestamptz ''2001-10-26 10:00:00'');

	-- Check month by date (recur every day, skip every second interval)
	insert_instances__recurrence_id := recurrence__new(''day'',
						           2,
							   null, -- Irrelevant
							   to_date(''2001-11-13'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''every 2 days'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-11-05 00:00:00''
					    );

	-- There should be five instances (including the original)
	-- JS: roblem here.  The recurrence includes 10/28/2001, which is the switchover to
	-- JS: DST in the US.  
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 6 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;

	----------------------------------------------------------------------------------------------------------


	-- Check another recurrence type (same date every year)
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-04-01 09:00:00'',
						       timestamptz ''2001-04-01 10:00:00'');

	-- Check month by date (recur every day, skip every second interval)
	insert_instances__recurrence_id := recurrence__new(''year'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2002-04-10'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''yearly (one DST day)'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2002-04-05 00:00:00''
					    );

	-- There should be two instance (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 2 from dual''
				    );


	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;


	-- Check another recurrence type (same date every year)
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-04-03 09:00:00'',
						       timestamptz ''2001-04-03 10:00:00'');

	-- Check month by date (recur every day, skip every second interval)
	insert_instances__recurrence_id := recurrence__new(''year'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2002-04-10'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''yearly (non-DST)'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2002-04-05 00:00:00''
					    );

	-- There should be two instance (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 2 from dual''
				    );



	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;


	-- Check another recurrence type (same date every year)
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-10-28 09:00:00'',
						       timestamptz ''2001-10-28 10:00:00'');

	-- Check month by date (recur every day, skip every second interval)
	insert_instances__recurrence_id := recurrence__new(''year'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2002-10-30'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''yearly (DST)'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2002-10-30 00:00:00''
					    );

	-- There should be two instance (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 2 from dual''
				    );

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;
	----------------------------------------------------------------------------------------------------------



	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-02-06 09:00:00'',
						       timestamptz ''2001-02-07 10:00:00'');

	insert_instances__recurrence_id := recurrence__new(''last_of_month'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2001-12-10'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''last_of_month'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-12-10 00:00:00''
					    );

	-- There should be three instances (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 10 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	raise notice ''Check of recurrence: every end of the month, same day as event, starting next month.'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;



	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-08-06 09:00:00'',
						       timestamptz ''2001-08-07 10:00:00'');

	insert_instances__recurrence_id := recurrence__new(''last_of_month'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2002-05-10'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''last_of_month'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2002-05-20 00:00:00''
					    );

	-- There should be three instances (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 9 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	raise notice ''Check of recurrence: every end of the month, same day as event, starting next month.'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;


	----------------------------------------------------------------------------------------------------------
	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-08-06 09:00:00'',
						       timestamptz ''2001-08-07 10:00:00'');

	insert_instances__recurrence_id := recurrence__new(''custom'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2001-08-20'',''YYYY-MM-DD''),
							   ''recur_every3'');


	insert_instances__event_id  := acs_event__new(null,''custom'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-08-30 00:00:00''
					    );

	-- There should be three instances (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 5 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	raise notice ''Check of recurrence: custom'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;


	----------------------------------------------------------------------------------------------------------

	-- First, we need a new timespan,recurrence  and activity
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-02-06 09:00:00'',
						       timestamptz ''2001-02-07 10:00:00'');

	insert_instances__recurrence_id := recurrence__new(''month_by_day'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2001-12-10'',''YYYY-MM-DD''),
							   null);


	insert_instances__event_id  := acs_event__new(null,''month_by_day'',null, null, null,
				      insert_instances__timespan_id,
				      insert_instances__activity_id,
				      insert_instances__recurrence_id,
				      ''acs_event'',now(),null,null,null
				      );

	
	-- Cut-off date should have no effect
	PERFORM acs_event__insert_instances (insert_instances__event_id,
					    timestamptz ''2001-12-20 00:00:00''
					    );

	-- There should be three instances (including the original).
	PERFORM ut_assert__eqquery (''Test count of instances in INSERT_INSTANCES'',
				    ''select count(*) from acs_events
				      where recurrence_id = '' || insert_instances__recurrence_id,
				    ''select 11 from dual''
				    );


	-- Check dates
	-- Just print them out and eyeball them for now.

	raise notice ''Check of recurrence: every month, same week and day of the month'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % (%,%)'',rec_events.name, rec_events.start_date,rec_events.end_date,
							  rec_events.event_id,rec_events.recurrence_id;
	end loop;


	-- While we are here, let us test shift_all
	-- Let us shift the start date of event by two days, end date by two days
	PERFORM acs_event__shift_all(insert_instances__event_id,2,3);


	-- Let us eyeball for now.
	raise notice ''Test of shift: after shift of start date by one day, end date by three days.'';

	for rec_events in 
	    select * from acs_events_dates
		where recurrence_id = insert_instances__recurrence_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;



	----------------------------------------------------------------------------------------------------------

	-- Timespan to shift
	insert_instances__timespan_id := timespan__new(timestamptz ''2001-02-06 09:00:00'',
						       timestamptz ''2001-02-07 10:00:00'');


	-- Insert one recurrence so that recurrence__delete will have something to delete (since recurrences
	-- are deleted if associated with an event).
	insert_instances__recurrence_id := recurrence__new(''month_by_day'',
						           1,
							   null,  -- Irrelevant
							   to_date(''2000-06-01'',''YYYY-MM-DD''),
							   null
							   );

	-- Insert two non-recurring event to test acs_event__delete, using acs_event__new alone
	PERFORM acs_event__new(null,null,null,null,null,null,null,null,''acs_event'',now(),null,null,null);
	insert_instances__event_id := acs_event__new(null,''Another event'',''Yet another event description'', null, null,
			                             insert_instances__timespan_id,null,null,''acs_event'',now(),null,null,null);


	-- If so, we should now be able to get the activity name
	PERFORM ut_assert__eq (''Test of GET_NAME from activity within INSERT_INSTANCES'',
			       acs_event__get_name(insert_instances__event_id),
			       ''Another event''
			       );
				
	-- and the description	
	PERFORM ut_assert__eq (''Test of GET_DESCRIPTION from activity within INSERT_INSTANCES'',
			       acs_event__get_description(insert_instances__event_id),
			       ''Yet another event description''
			       );

	-- Let us eyeball for now.
	raise notice ''Test of shift: before'';

	for rec_events in 
	    select * from acs_events_dates
		where event_id = insert_instances__event_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;

	-- Let us shift the start date of event by one day, end date by two days
	PERFORM acs_event__shift(insert_instances__event_id,1,2);


	-- Let us eyeball for now.
	raise notice ''Test of shift: after shift of start date by one day, end date by two days.'';

	for rec_events in 
	    select * from acs_events_dates
		where event_id = insert_instances__event_id
	loop
		raise notice '' % : % through % '',rec_events.name, rec_events.start_date,rec_events.end_date;
	end loop;



        -- We test mapping of events to parties.  We choose some party from parties table to map.
	-- Since we know that the party with party_id of -1 always exists, we map this.
	PERFORM  acs_event__party_map(insert_instances__event_id,-1);


	-- There should be one entry in the mapping table
	PERFORM ut_assert__eqquery (''Test count of party mappings in acs_event_party_map'',
				    ''select count(*) from acs_event_party_map
				      where event_id = '' || insert_instances__event_id,
				    ''select 1 from dual''
				    );


	return 0;

end;' language 'plpgsql';


create function ut__delete_instances()
returns integer as '
declare
	rec_timespans					record;
	rec_recurrences					record;
	rec_activities					record;
	rec_events					record;
	v_dummy						integer;
begin

	-- Remember the activity object mapping?  Unfortunately, we can only do the unmapping in a 
	-- separate transaction. Since we inserted only one mapping, we expect only one entry.
	select activity_id into v_dummy
	from acs_activity_object_map
	where activity_id = object_id;

	PERFORM  acs_activity__object_unmap(v_dummy,v_dummy);


	-- There should be no entry in the mapping table
	PERFORM ut_assert__eqquery (''Test count of object unmappings in acs_activity_object_map'',
				    ''select count(*) from acs_activity_object_map
				      where activity_id = '' || v_dummy,
				    ''select 0 from dual''
				    );

	-- Remember the event-party mapping?  Unfortunately, we can only do the unmapping in a 
	-- separate transaction. Since we inserted only one mapping, we expect only one entry.
	select event_id into v_dummy
	from acs_event_party_map
	where party_id = -1;

	PERFORM  acs_event__party_unmap(v_dummy,-1);


	-- There should be no entry in the mapping table
	PERFORM ut_assert__eqquery (''Test count of party unmappings in acs_event_party_map'',
				    ''select count(*) from acs_event_party_map
				      where event_id = '' || v_dummy,
				    ''select 0 from dual''
				    );



	-- Clean up recurring events.  Note that we need to subset the events to only nonrecurring events
	-- since acs_event__delete_all will do nothing for non-recurring events (and this the test will fail
	-- if we also test acs_event__delete_all for non-recurring events).
	FOR rec_events IN
	       select * 
	       from acs_events
	       where recurrence_id is not null
	       and event_id not in (select event_id from ut_event_ids)
	LOOP
		-- This should delete only recurring events
		PERFORM acs_event__delete_all(rec_events.event_id);

	        PERFORM ut_assert__eqquery (''Test deletion of events by acs_event__delete_all'',
				    ''select count(*) from acs_events
				      where event_id ='' ||  rec_events.event_id,
				    ''select 0 from dual''
				    );

	END LOOP;


	-- Clean up non-recurring events (all recurring events should be deleted above)
	FOR rec_events IN
	       select * 
	       from acs_events
	       where event_id not in (select event_id from ut_event_ids)
	LOOP
		-- This should delete recurring and nonrecurring events
		PERFORM acs_event__delete(rec_events.event_id);

	        -- There should be no entry in the events table with this event_id
		-- Unlike the test above, there is no deletion of recurrences here.
	        PERFORM ut_assert__eqquery (''Test deletion of events by acs_event__delete'',
				    ''select count(*) from acs_events
				      where event_id ='' ||  rec_events.event_id,
				      ''select 0 from dual''
				      );

	END LOOP;



	-- Clean up remaining activities in the regression
	FOR rec_activities IN
	       select * 
	       from acs_activities
	       where activity_id not in (select activity_id from ut_activity_ids)
	LOOP
		PERFORM acs_activity__delete(rec_activities.activity_id);

	       -- There should be no entry in the activities table with this activity_od
	       PERFORM ut_assert__eqquery (''Test deletion of events by acs_activity__delete'',
				    ''select count(*) from acs_activities
				      where activity_id = '' || rec_activities.activity_id,
				    ''select 0 from dual''
				    );
	END LOOP;



	-- Clean up regression recurrences
	FOR rec_recurrences IN
	       select * 
	       from recurrences
	       where recurrence_id not in (select recurrence_id from ut_recurrence_ids)
	LOOP
		PERFORM recurrence__delete(rec_recurrences.recurrence_id);

		-- There should be no entry in the recurrence table associated with this recurrence_id
		PERFORM ut_assert__eqquery (''Test deletion of recurrences by recurrence__delete'',
				    ''select count(*) from recurrences 
				      where recurrence_id = '' || rec_recurrences.recurrence_id,
				    ''select 0 from dual''
				    );


	END LOOP;

	-- Clean up regression timespans.  Note that timespans API is regression-tested separately,
	-- so no need to redo it here.
	FOR rec_timespans IN
	       select * 
	       from timespans
	       where timespan_id not in (select timespan_id from ut_timespan_ids)
	LOOP
		PERFORM timespan__delete(rec_timespans.timespan_id);

	END LOOP;



	return 0;

end;' language 'plpgsql';


-- Call the regression test
select (case when ut__setup() = 0
             then
	         'Set up a success.'
	     end) as setup_result;

select (case when ut__insert_instances() = 0 
	     then 
               'Insert instances a success.'
             end) as insert_instances_result;

select (case when ut__delete_instances() = 0 
	     then 
               'Delete instances a success.'
             end) as delete_instances_result;

select (case when ut__teardown() = 0
             then
	         'Tear down a success.'
	     end) as teardown_result;

drop function recur_every3(timestamp,integer);

-- This depends on openacs4 installed.
select drop_package('ut');

-- End of regression test
\i utest-drop.sql

