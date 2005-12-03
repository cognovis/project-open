-- packages/acs-events/sql/postgresql/test/timespan-test.sql
--
-- Regression tests for timespan API
-- Separated from time_interval-test.sql
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id$

-- Note: These tests use the semi-ported utPLSQL regression package
\i utest-create.sql

-- Set-up the regression test
create function ut__setup()
returns integer as '
begin

	raise notice ''Setting up timespans test...'';

	-- create copies of the tables (shadow tables) to verify API operations
	-- No need for execute here?
	create table ut_timespans as select * from timespans;

	-- For testing purposes, both tables should still be empty
	PERFORM ut_assert__eqtable (''Comparing copied data for time interval'',
				    ''timespans'',
				    ''ut_timespans''
				    );

	-- Store keys that are in the table prior to the regresion test
	create table ut_interval_ids as select interval_id from time_intervals;
	create table ut_timespan_ids as select timespan_id from timespans;

	return 0;

end;' language 'plpgsql';


-- Clean up the mess that regression testing did
create function ut__teardown()
returns integer as '
begin

	raise notice ''Tearing down timespans test...'';

	-- Delete intervals added by tests
	-- cascade delete in timespans should delete corresponding entries in that table
	-- Note that we exclude deleting rows that existed prior to regression test
	delete from timespans
	where timespan_id not in (select timespan_id
			          from ut_timespan_ids);

	-- This is sufficient, actually.
	delete from time_intervals
	where interval_id not in (select interval_id
			          from ut_interval_ids);

				

	-- Drop test tables
	-- cascade option does not work?
	drop table ut_timespans;
	drop table ut_interval_ids;
	drop table ut_timespan_ids;

	return 0;

end;' language 'plpgsql';


-- Postgres has this weird behavior that you cannot change a row twice
-- within a transaction.  


-- We test the creation of a time interval entry
create function ut__new(
       integer	-- time_intervals.interval_id%TYPE;
)
returns integer as '
declare
	new__interval_id    alias for $1;
	v_interval_id	    time_intervals.interval_id%TYPE;
	v_timespan_id	    timespans.timespan_id%TYPE;
begin

	-- The new function will create a copy on the time_intervals table
	v_timespan_id := timespan__new(new__interval_id);

	-- Since the timespan__new function creates a copy of the interval
	-- we need the copied interval_id
	select interval_id into v_interval_id
	from timespans
	where timespan_id = v_timespan_id;

	-- Create shadow entries, too.
	insert into ut_timespans (timespan_id,interval_id)
	values (v_timespan_id,v_interval_id);

	-- The new function will create a copy on the time_intervals table
	-- We do two test.  First, we check whether the copying mechanism is ok
	PERFORM ut_assert__eq (''Test of timespan__new copying mechanism: '',
			       time_interval__eq(v_interval_id, new__interval_id),
			       true
			       );

	-- Second, we check whether the timespans table is properly populated
	PERFORM ut_assert__eqtable (''Test of timespan__new entry in timespans table: '',
				    ''ut_timespans'',
				    ''timespans''
				    );

	-- If successful, interval id is correct
	return v_timespan_id;

end;' language 'plpgsql';

-- We test the creation of a time interval entry
create function ut__new(
       timestamptz,
       timestamptz
)
returns integer as '
declare
	new__date1	    alias for $1;
	new__date2	    alias for $2;
	v_interval_id	    time_intervals.interval_id%TYPE;
begin

	-- We first want to create an entry in the time interval table
	-- because the timespan_new function copies this interval
	v_interval_id := time_interval__new(new__date1, new__date2);

	-- Create a new timespan using the function above
	return ut__new(v_interval_id);

end;' language 'plpgsql';


-- Check the deletion of a time interval
create function ut__delete(
       integer	-- timespans.timespan_id%TYPE
)
returns integer as '
declare
	delete__timespan_id  alias for $1;
begin

	-- Delete the row from actual table
	PERFORM timespan__delete(delete__timespan_id);

	PERFORM ut_assert__eqtable (''Testing timespan__delete: '',
				    ''ut_timespans'',
				    ''timespans''
				    );

	-- Delete entry from shadow table
	-- JS: Aha, a demonstration of the effect of transactions to foreign keys
	-- JS: It seems that while timespan__delete would remove the row from
	-- JS: time_intervals, the cascade delete removal of the corresponding row
	-- JS: in timespans is not yet done until the transation is complete.  Thus,
	-- JS: deleting the row in the shadow table within this function/transaction 
	-- JS: will cause the comparison of the timespans table and the shadow table 
	-- JS: to fail (since delete will immediately remove the row from the shadow 
	-- JS: table). We do the delete outside this function/transaction instead.
	-- Delete from shadow table
	-- delete from ut_timespans
	-- where timespan_id = delete__timespan_id;


	-- If successful, interval id is correct
	return 0;

end;' language 'plpgsql';


create function ut__join_interval (
       integer,	     -- timespans.timespan_id%TYPE;
       integer,	     -- time_intervals.interval_id%TYPE;
       boolean	     -- copy_p (if false, create new)
)
returns integer as '
declare
	join_interval__timespan_id	alias for $1;
	join_interval__interval_id	alias for $2;
	join_interval__copy_p		alias for $3;
	v_interval_id			 time_intervals.interval_id%TYPE;
	v_interval_id_ck		 time_intervals.interval_id%TYPE;
	v_interval_id_cp		 time_intervals.interval_id%TYPE;
begin

	-- Get interval id of orginal interval (before join)
	select interval_id into v_interval_id
	from timespans
	where timespan_id = join_interval__timespan_id;

	-- Join the supplied interval with existing interval
	-- Return the interval_id being joined (will be different if copy_p = true)
	v_interval_id_cp := timespan__join_interval(join_interval__timespan_id, 
					 join_interval__interval_id,
					 join_interval__copy_p);

	-- Dont forget to put the newly created timepsan into the shadow table
	insert into ut_timespans (timespan_id,interval_id)
	values (join_interval__timespan_id,v_interval_id_cp);

	-- Check if there are now two intervals with the same timespan_id in timespans table
	PERFORM ut_assert__eqquery (''Testing timespan__join with two intervals (2 entries): '',
				    ''select count(*) 
				      from timespans
				      where timespan_id = '' || join_interval__timespan_id,
				    ''select 2 from dual''
				    );

	-- This is probably a more robust check, since we want to compare the resulting timespan table
	PERFORM ut_assert__eqtable (''Testing timespan__join: table comparison test: '',
				    ''ut_timespans'',
				    ''timespans''
				    );

				   
	-- Did not do the interval check since it is dependent upon join_interval__copy_p
	-- Besides, it seems silly to me: since there are only two intervals, checking table equality
	-- AND checking that only two intervals are in the time span should be enough!
	return 0;

end;' language 'plpgsql';

create function ut__join(
       integer,   -- timespans.timespan_id%TYPE;
       integer	  -- timespans.timespan_id%TYPE;
)
returns integer as '
declare
	join__timespan_id_1 alias for $1;
	join__timespan_id_2 alias for $2;
	rec_timespan	    record;
begin

	PERFORM timespan__join(join__timespan_id_1,join__timespan_id_2);

	-- Joining means that the intervals in join__timespan_id_2 are
	-- included in the intervals in join__timespan_id_1
	FOR rec_timespan IN
		select *
		from timespans
		where timespan_id = join__timespan_id_2
	LOOP
		insert into ut_timespans (timespan_id,interval_id)
		values (join__timespan_id_1,rec_timespan.interval_id);
	END LOOP;


	-- Check equality of tables
	PERFORM	 ut_assert__eqtable (''Testing timespan__join by specifying timespan_id: '',
				     ''ut_timespans'',
				     ''timespans''
				     );
	return 0;
end;' language 'plpgsql';

create function ut__join(
       integer,    -- timespans.timespan_id%TYPE;
       timestamptz,  -- time_intervals.start_date%TYPE;
       timestamptz  -- time_intervals.end_date%TYPE;
)
returns integer as '
declare
	join__timespan_id alias for $1;
	join__start_date  alias for $2;
	join__end_date	  alias for $3;
	v_interval_id	  time_intervals.interval_id%TYPE;
begin



	v_interval_id := timespan__join(join__timespan_id,join__start_date,join__end_date);

	-- Joining means that the interval becomes part 
	-- of the timespan specified by join__timespan_id
	insert into ut_timespans (timespan_id,interval_id)
	values (join__timespan_id,v_interval_id);

	-- Check equality of tables
	PERFORM	 ut_assert__eqtable (''Testing timespan__join by specifying start and end dates: '',
				     ''ut_timespans'',
				     ''timespans''
				     );
	return 0;
end;' language 'plpgsql';

create function ut__copy(
       integer,	-- timespans.timespan_id%TYPE
       interval	-- offset
)
returns integer as '
declare
	copy__timespan_id	alias for $1;
	copy__offset		alias for $2;
	v_timespan_id		timespans.timespan_id%TYPE;
	v_interval_id		time_intervals.interval_id%TYPE;
	v_interval_id_ck	time_intervals.interval_id%TYPE;
	rec_timespan		record;
begin

	v_timespan_id := timespan__copy(copy__timespan_id,copy__offset);

	-- Put copy in shadow table. There may be more than one interval in a 
	-- time interval so we need to loop through all
	for rec_timespan in
	    select * 
	    from timespans
	    where timespan_id = v_timespan_id
	loop
		-- Populate the shadow table
		insert into ut_timespans (timespan_id,interval_id)
		values (rec_timespan.timespan_id,rec_timespan.interval_id);
	end loop;

	-- Check proper population of shadow table
	PERFORM ut_assert__eqtable (''Testing timespan__copy: '',
				    ''ut_timespans'',
				    ''timespans''
				    );

	return v_timespan_id;

end;' language 'plpgsql';


create function ut__exists_p (
       integer,	-- timespans.timespan_id%TYPE;
       boolean
)
returns integer as '
declare
	exists_p__timespan_id	alias for $1;
	exists_p__result	alias for $2;
begin

	PERFORM ut_assert__eq (''Testing timespan__exists_p: '',
			       timespan__exists_p(exists_p__timespan_id),
			       exists_p__result
			       );
			       
	return 0;

end;' language 'plpgsql';

create function ut__multi_interval_p (
       integer,  -- timespans.timespan_id%TYPE
       boolean   -- result
)
returns integer as '
declare
	multi_interval_p__timespan_id   alias for $1;
	multi_interval_p__result   alias for $2;
begin

      return ut_assert__eq (''Testing timespan__multi_interval_p: '',
			    timespan__multi_interval_p(multi_interval_p__timespan_id),
			    multi_interval_p__result
			    );
end;' language 'plpgsql';


create function ut__overlaps_interval_p(
       integer,		-- timespans.timespan_id%TYPE;
       integer,		-- time_intervals.interval_id%TYPE;
       boolean
)
returns integer as '
declare
	overlaps_interval_p__timespan_id alias for $1;
	overlaps_interval_p__interval_id alias for $2;
	overlaps_interval_p__result	 alias for $3;
begin

      return ut_assert__eq (''Testing timespan__overlaps_interval_p: '',
			    timespan__overlaps_interval_p(overlaps_interval_p__timespan_id,
							  overlaps_interval_p__interval_id),
			    overlaps_interval_p__result
			    );
end;' language 'plpgsql';

create function ut__overlaps_p(
       integer,		-- timespans.timespan_id%TYPE;
       integer,		-- timespans.timespan_id%TYPE;
       boolean
)
returns integer as '
declare
	overlaps_p__timespan_1_id alias for $1;
	overlaps_p__timespan_2_id alias for $2;
	overlaps_p__result	  alias for $3;
begin

      return ut_assert__eq (''Testing timespan__overlaps_p, timespan vs. timespan: '',
			    timespan__overlaps_p(overlaps_p__timespan_1_id,
						 overlaps_p__timespan_2_id),
			    overlaps_p__result
			    );
end;' language 'plpgsql';

create function ut__overlaps_p(
       integer,		-- timespans.timespan_id%TYPE;
       timestamptz,	-- time_intervals.start_date%TYPE;
       timestamptz,	-- time_intervals.end_date%TYPE;
       boolean
)
returns integer as '
declare
	overlaps_p__timespan_id alias for $1;
	overlaps_p__start_date alias for $2;
	overlaps_p__end_date   alias for $3;
	overlaps_p__result     alias for $4;
begin

      return ut_assert__eq (''Test of timespan__overlaps_p, timespan vs. start and end dates: '',
			    timespan__overlaps_p(overlaps_p__timespan_id,
						 overlaps_p__start_date,
						 overlaps_p__end_date),
			    overlaps_p__result
			    );
end;' language 'plpgsql';

create function ut__interval_delete (
       integer,	  -- timespans.timespan_id%TYPE;
       integer    -- time_intervals.interval_id%TYPE;
)
returns integer as '
declare
	  interval_delete__timespan_id	alias for $1;
	  interval_delete__interval_id  alias for $2;
begin

	PERFORM timespan__interval_delete(interval_delete__timespan_id,interval_delete__interval_id);
				
	-- Remove from shadow table
	delete from ut_timespans
	where timespan_id = interval_delete__timespan_id
	      and
	      interval_id = interval_delete__interval_id;

	return ut_assert__eqtable(''Testing timespan__interval_delete: '',
				  ''ut_timespans'',
				  ''timespans''
				  );
end;' language 'plpgsql';


create function ut__regression1()
returns integer as '
declare
	v_result	 integer := 0;
	v_interval_id	 time_intervals.interval_id%TYPE;
	v_interval_id_ck time_intervals.interval_id%TYPE;
	v_timespan_id	 timespans.timespan_id%TYPE;
	v_timespan_id_ck	 timespans.timespan_id%TYPE;
begin

	raise notice ''Regression test, part 1 (creates and edits).'';

	-- First create an interval
	v_interval_id := time_interval__new(timestamptz ''2001-01-01'',timestamptz ''2001-01-20'');

	--Check if creation of timespans work by supplying an interval id to be copied
	PERFORM ut__new(v_interval_id);

	-- We first check if the creation of timespans work
	-- This should be equivalent to what we have above
	v_timespan_id := ut__new(timestamptz ''2001-01-25'',timestamptz ''2001-02-02'');

	-- Test if timespan exists
	PERFORM ut__exists_p(v_timespan_id,true);

	-- Unfortunately, we cannot delete the timespan and then check its non-existence
	-- (transactions). So we check for a known non-existent timespan
	PERFORM ut__exists_p(v_timespan_id+100,false);

	-- Check if multi-interval (obviously not)
	PERFORM ut__multi_interval_p(v_timespan_id,false);

	-- The interval does not overlap the timespan	
	PERFORM ut__overlaps_interval_p(v_timespan_id,v_interval_id,false);

	-- Join the first interval with the second, without making a copy
	PERFORM ut__join_interval(v_timespan_id,v_interval_id,false);

	-- Should now be a multi-interval timespan
	PERFORM ut__multi_interval_p(v_timespan_id,true);

	-- Now that the interval is part of the timespan, they should overlap
	PERFORM ut__overlaps_interval_p(v_timespan_id,v_interval_id,true);

	-- A new timespans
	v_timespan_id := ut__new(timestamptz ''2001-03-05'',timestamptz ''2001-03-31'');
	v_timespan_id_ck := ut__new(timestamptz ''2001-06-05'',timestamptz ''2001-06-30'');

	-- These timespans should not overlap
	PERFORM ut__overlaps_p(v_timespan_id,v_timespan_id_ck,false);

	-- Check overlaps against these known dates
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-02-06'',timestamptz ''2001-03-25'',true);
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-03-07'',timestamptz ''2001-04-01'',true);
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-01-01'',timestamptz ''2001-03-20'',true);
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-01-01'',null,true);
	PERFORM ut__overlaps_p(v_timespan_id,null,timestamptz ''2001-04-01'',true);
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-04-01'',timestamptz ''2001-04-30'',false);
	PERFORM ut__overlaps_p(v_timespan_id,timestamptz ''2001-02-01'',timestamptz ''2001-02-27'',false);


	-- Join the first interval with the second, making a copy
	PERFORM ut__join_interval(v_timespan_id,v_interval_id,true);

	-- Join the two (the joined interval is longer)
	PERFORM ut__join(v_timespan_id_ck,v_timespan_id);

	-- These timespans should now overlap
	PERFORM ut__overlaps_p(v_timespan_id,v_timespan_id_ck,true);

	-- Join an interval instead
	PERFORM ut__join(v_timespan_id_ck,timestamptz ''2001-12-01'',timestamptz ''2001-12-31'');

	-- Copy a timespan (will only contain two)
	PERFORM ut__copy(v_timespan_id,interval ''0 days'');
	
	-- Now try to delete the interval just joined
	PERFORM ut__interval_delete(v_timespan_id,v_interval_id);


	-- We will improve the regression test so there is reporting 
	-- of individual test results.  For now, reaching this far is
	-- enough to declare success.
       	return v_result;

end;' language 'plpgsql';

create function ut__regression2()
returns integer as '
declare
	v_result	 integer := 0;
	rec_timespan	 record;
begin

	raise notice ''Regression test, part 2 (deletes).'';

	-- Remove all entries made by regression test
	-- This also tests the deletion mechanism
	FOR rec_timespan IN 
	   select * from timespans
	   where timespan_id not in (select timespan_id from ut_timespan_ids)
        LOOP
		PERFORM ut__delete(rec_timespan.timespan_id);

	END LOOP;

	-- We will improve the regression test so there is reporting 
	-- of individual test results.  For now, reaching this far is
	-- enough to declare success.
       	return v_result;

end;' language 'plpgsql';

--------------------------------------------------------------------------------
-- Main regression test.  PostgreSQL does not allow multiple changes made to a 
-- primary key inside a transaction if the primary key is referenced by another 
-- table (e.g., insert and delete). As a fix, we break down the regression test 
-- so that row creations and edits are separate from row deletions
--------------------------------------------------------------------------------
select (case when ut__setup() = 0
             then
	         'Regression test properly set up.'
	     end) as setup_result;

select (case when ut__regression1() = 0
             then
	         'Regression test, part 1 successful.'
	     end) as test_result;

 select * from time_intervals;
 select * from timespans;
 select * from ut_timespans;

select (case when ut__regression2() = 0
             then
	         'Regression test, part 2 successful.'
	     end) as test_result;

-- Unfortunately, we need to recheck the deletion since we cannot put
-- actual deletion of entries in the shadow table inside the ut__delete
-- function due to the transactional nature of the functions 
delete from ut_timespans
where timespan_id not in (select timespan_id from ut_timespan_ids);

select (case when ut_assert__eqtable('Recheck of deletion','timespans','ut_timespans') = 0
             then
	         'Recheck of deletion successful.'
	     end) as recheck_result;


select (case when ut__teardown() = 0
             then
	         'Regression test properly torn down.'
	     end) as teardown_result;

-- Clean up created functions.
-- This depends on openacs4 installed.
select drop_package('ut');

--------------------------------------------------------------------------------
-- End of regression test
--------------------------------------------------------------------------------
\i utest-drop.sql








