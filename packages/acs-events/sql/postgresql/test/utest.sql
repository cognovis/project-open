-- packages/acs-events/sql/postgresql/test/utest.sql
--
-- Regression test of the unit test package (aha, recursion ;-).
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id$

create function inline_0 ()
returns integer  as '
declare
	v_str		varchar;
	v_datetest	timestamp;
	v_dateref	timestamp;
begin

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (equality).'',
		''1'',
		''1'',
		''f'',
		''t''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (equality).'',
		''1'',
		''1''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (inequality).'',
		''1'',
		''0'',
		''f'',
		''f'' -- we dont want to raise an exception here
		);


     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (inequality).'',
		''1'',
		''0''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__b2v (true).'',
		ut_assert__b2v(1+1 = 2),
		''true'',
		''f'',
		''t''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__b2v (true).'',
		ut_assert__b2v(1+1 = 2),
		''true''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__b2v (false).'',
		ut_assert__b2v(1+1 = 1),
		''false'',
		''f'',
		''t''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__b2v (false).'',
		ut_assert__b2v(1+1 = 1),
		''false''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (boolean,boolean).'',
		1+1 = 2,
		''true'',
		''f'',
		''t''
		);


     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (boolean,boolean).'',
		1+1 = 2,
		''true''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (boolean,boolean).'',
		1+1 = 1,
		''false'',
		''f'',
		''t''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (boolean,boolean).'',
		1+1 = 1,
		''false''
		);


     select now() into v_dateref;
     v_datetest := v_dateref;

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (timestamp,timestamp).'',
		v_datetest, 
		v_dateref,
		''f'',
		''f''
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (timestamp,timestamp).'',
		v_datetest, 
		v_dateref
		);

     v_datetest := now() + interval ''1 days'';

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (timestamp,timestamp).'',
		v_datetest,
		v_dateref,
		''f'',
		''f'' -- do not raise exception
		);

     PERFORM ut_assert__eq(
		''Test of ut_assert__eq (timestamp,timestamp).'',
		v_datetest,
		v_dateref
		);

     PERFORM ut_assert__ieqminus(
		''Test of query equality.'',
		''select 1 from dual'',
		''select 1 from dual'',
		''Simple select from dual.'',
		''t'' 
		);

     PERFORM ut_assert__ieqminus(
		''Test of query inequality.'',
		''select 1 from dual'',
		''select 2 from dual'',
		''simple select from dual '',
		''f'' -- do not raise exception since this will fail
		);

      create table ut_temp (
          an_integer   integer,
 	 a_varchar    varchar);
 
      insert into ut_temp values (1,''a'');
      insert into ut_temp values (2,''b'');

     PERFORM ut_assert__ieqminus(
		''Test of query equality.'',
		''select * from ut_temp where an_integer = 1'',
		''select * from ut_temp where a_varchar = '' || '''''''' || ''a'' || '''''''',
		''Simple comparison of two tables.'',
		''t'' 
		);

     PERFORM ut_assert__ieqminus(
		''Test of query inequality.'',
		''select * from ut_temp where an_integer = 2'',
		''select * from ut_temp'',
		''Simple comparison of two unequal tables.'',
		''f'' 
		);
    
      create table ut_another as select * from ut_temp;

      PERFORM ut_assert__eqtable(
                ''Test of simple table equality.'',
		''ut_another'',
		''ut_temp'',
		null,
		null,
		''t''
		);

      PERFORM ut_assert__eqtable(
                ''Test of simple table equality.'',
		''ut_another'',
		''ut_temp''
		);

      PERFORM ut_assert__eqtable(
                ''Test of simple table equality.'',
		''ut_another'',
		''ut_temp'',
		''an_integer = 1'',
		''a_varchar = '' || '''''''' || ''a'' || '''''''',
		''t''
		);

      PERFORM ut_assert__eqtable(
                ''Test of simple table inequality.'',
		''ut_another'',
		''ut_temp'',
		''an_integer = 1'',
		''a_varchar = '' || '''''''' || ''b'' || '''''''',
		''f''
		);

      PERFORM ut_assert__eqtabcount(
                ''Test of simple table count equality.'',
		''ut_another'',
		''ut_temp'',
		null,
		null,
		''t''
		);

      PERFORM ut_assert__eqtabcount(
                ''Test of simple table count equality.'',
		''ut_another'',
		''ut_temp'',
		''an_integer = 1'',
		''a_varchar = '' || '''''''' || ''a'' || '''''''',
		''t''
		);

      PERFORM ut_assert__eqtabcount(
                ''Test of simple table inequality.'',
		''ut_another'',
		''ut_temp'',
		null,
		''a_varchar = '' || '''''''' || ''b'' || '''''''',
		''f''
		);

     PERFORM ut_assert__eqquery(
		''Test of query equality.'',
		''select * from ut_temp where an_integer = 1'',
		''select * from ut_temp where a_varchar = '' || '''''''' || ''a'' || '''''''',
		''t'' 
		);

     PERFORM ut_assert__eqquery(
		''Test of query equality.'',
		''select * from ut_temp where an_integer = 1'',
		''select * from ut_temp where a_varchar = '' || '''''''' || ''a'' || ''''''''
		);

     PERFORM ut_assert__eqquery(
		''Test of query equality.'',
		''select * from ut_temp where an_integer = 2'',
		''select * from ut_temp'',
		''f'' 
		);

     PERFORM ut_assert__eqquery(
		''Test of query equality.'',
		''select * from ut_temp where an_integer = 2'',
		''select * from ut_temp''
		);

      delete from ut_another where an_integer=2;

      PERFORM ut_assert__eqtable(
                ''Test of simple table inequality.'',
		''ut_another'',
		''ut_temp'',
		null,
		null,
		''f''
		);

      PERFORM ut_assert__eqtable(
                ''Test of simple table inequality.'',
		''ut_another'',
		''ut_temp''
		);

     PERFORM ut_assert__isnotnull(
	     ''Degenerate test of non-null'',
	     ''1'',
	     ''f'',
	     ''t''
	     );

     PERFORM ut_assert__isnotnull(
	     ''Degenerate test of non-null'',
	     ''1''
	     );

     PERFORM ut_assert__isnull(
	     ''Degenerate test of null'',
	     null,
	     ''f'',
	     ''t''
	     );
     PERFORM ut_assert__isnull(
	     ''Degenerate test of null'',
	     null
	     );


     -- We already deleted this, so v_str should be null
     select into v_str a_varchar from ut_another where an_integer = 2;

     PERFORM ut_assert__isnull(
	     ''Degenerate test of null'',
	     v_str,
	     ''f'',
	     ''t''
	     );

     PERFORM ut_assert__isnull(
	     ''Degenerate test of null'',
	     v_str
	     );


      -- Still in table, so should be non-null.
     select into v_str a_varchar from ut_another where an_integer = 1;

     PERFORM ut_assert__isnotnull(
	     ''Degenerate test of null'',
	     v_str,
	     ''f'',
	     ''t''
	     );

     PERFORM ut_assert__isnotnull(
	     ''Degenerate test of null'',
	     v_str
	     );

      drop table ut_temp;
      drop table ut_another;

     return 0;

end;' language 'plpgsql';


select (case when inline_0 () = 0 
	     then 
               'Regression test is a success.'
             end) as test_result;
drop function inline_0 ();




