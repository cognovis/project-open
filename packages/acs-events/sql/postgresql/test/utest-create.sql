-- packages/acs-events/sql/postgresql/test/utest-create.sql
--
-- Regression tests for timespan API
-- Separated from time_interval-test.sql
--
-- @author jowell@jsabino.com
--
-- @creation-date 2001-06-26
--
-- $Id$

-- /* 
-- GNU General Public License for utPLSQL
--     
-- Copyright (C) 2000 
-- Steven Feuerstein, steven@stevenfeuerstein.com
-- Chris Rimmer, chris@sunset.force9.co.uk
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program (see license.txt); if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-- */

-- JS: Ported/copied shamelessly from the utplsql package.  
-- JS: This package is grossly incomplete, but quite useful (for me, anyways). 

create function ut_assert__expected (
      varchar,	-- IN VARCHAR,
      varchar,	-- IN VARCHAR,
      varchar	-- IN VARCHAR
)
returns varchar as '
declare
      expected__msg		alias for $1;
      expected__check_this	alias for $2;
      expected__against_this	alias for $3;
begin

      return expected__msg || 
	     '': expected '' ||
	     '''''''' ||
	     expected__against_this ||
	     '''''''' ||
	     '', got '' || 
	     '''''''' ||
	     expected__check_this ||
	     '''''''';

end;' language 'plpgsql';

create function ut_assert__this (
      varchar,	-- IN VARCHAR,
      boolean,	-- IN BOOLEAN,
      boolean,	-- IN BOOLEAN default false,
      boolean	-- IN BOOLEAN default false
)
returns integer as '
declare
      this__msg		   alias for $1;
      this__check_this     alias for $2;
      this__null_ok	   alias for $3; -- default FALSE
      this__raise_exc      alias for $4; -- default FALSE
begin

      -- We always output the message (usually the result of the test)
      raise notice ''%'',this__msg;

      if not this__check_this
         or ( this__check_this is null
               and not this__null_ok )
      then

	 -- Raise an exception if a failure
         if this__raise_exc
         then
	    -- We should make the message more informative.
            raise exception ''FAILURE''; 
	 else
	    raise notice ''FAILURE, but forced to continue.'';
         end if;

      end if;

      -- Continue if success;
      return 0;

end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__this (
      varchar,	-- IN VARCHAR,
      boolean	-- IN BOOLEAN,
)
returns integer as '
declare
      this__msg		   alias for $1;
      this__check_this     alias for $2;
begin

      return ut_assert__this(this_msg,this_check_this,''f'',''f'');
     
end;' language 'plpgsql';

create function ut_assert__eq (
      varchar,	-- IN VARCHAR2,
      varchar,	-- IN VARCHAR2,
      varchar,	-- IN VARCHAR2,
      boolean,	-- IN VARCHAR := FALSE,
      boolean	-- IN BOOLEAN := FALSE
)
returns integer as '
declare
      eq__msg	        alias for $1;
      eq__check_this    alias for $2;
      eq__against_this  alias for $3;
      eq__null_ok       alias for $4; -- default FALSE,
      eq__raise_exc     alias for $5; -- defaultFALSE
begin
	return ut_assert__this (
		 ut_assert__expected (eq__msg, eq__check_this, eq__against_this),
		 eq__check_this = eq__against_this,
		 eq__null_ok,
		 eq__raise_exc
		 );
	
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eq (
      varchar,	-- IN VARCHAR2,
      varchar,	-- IN VARCHAR2,
      varchar	-- IN VARCHAR2,
)
returns integer as '
declare
      eq__msg	        alias for $1;
      eq__check_this    alias for $2;
      eq__against_this  alias for $3;
begin

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,''f'',''f'');

end;' language 'plpgsql';


create function ut_assert__b2v (
       boolean	-- IN BOOLEAN
)
returns varchar as '
declare
	bool_exp      alias for $1;
begin

      if bool_exp
      then
         return ''true'';
      else if not bool_exp
           then
              return ''false'';
           else
              return ''null'';
           end if;
      end if;

end;' language 'plpgsql';

create function ut_assert__eq (
      varchar,
      boolean,
      boolean,
      boolean,
      boolean
)
returns integer as '
declare
      eq__msg		alias for $1;
      eq__check_this	alias for $2;
      eq__against_this	alias for $3;
      eq__null_ok	alias for $4; -- default false
      eq__raise_exc	alias for $5; -- defualt false
begin
     
     return  ut_assert__this (
		       ut_assert__expected (
				 eq__msg,
				 ut_assert__b2v(eq__check_this),
				 ut_assert__b2v(eq__against_this)
				 ),
		       ut_assert__b2v (eq__check_this) = ut_assert__b2v (eq__against_this),
		       eq__null_ok,
		       eq__raise_exc
		       );
			

end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eq (
      varchar,	-- IN VARCHAR2,
      boolean,
      boolean
)
returns integer as '
declare
      eq__msg	        alias for $1;
      eq__check_this    alias for $2;
      eq__against_this  alias for $3;
begin

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,''f'',''f'');

end;' language 'plpgsql';

create function ut_assert__eq (
      varchar,
      timestamptz,
      timestamptz,
      boolean,
      boolean
)
returns integer as '
declare
      eq__msg	        alias for $1;
      eq__check_this    alias for $2;
      eq__against_this	alias for $3;
      eq__null_ok	alias for $4; -- default false
      eq__raise_exc	alias for $5; -- default false
      c_format		constant varchar := ''MONTH DD, YYYY HH24MISS'';
      v_check		varchar;
      v_against		varchar;
begin

      v_check := to_char (eq__check_this, c_format);
      v_against := to_char (eq__against_this, c_format);

      return ut_assert__this (
                       ut_assert__expected (eq__msg, v_check, v_against),
		       v_check = v_against,
		       eq__null_ok,
		       eq__raise_exc
		       );

end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eq (
      varchar,	-- IN VARCHAR2,
      timestamptz,
      timestamptz
)
returns integer as '
declare
      eq__msg	        alias for $1;
      eq__check_this    alias for $2;
      eq__against_this  alias for $3;
begin

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,''f'',''f'');

end;' language 'plpgsql';

create function ut_assert__ieqminus (
      varchar,
      varchar,
      varchar,
      varchar,
      boolean
)
returns varchar as '
declare
      ieqminus__msg	      alias for $1;
      ieqminus__query1	      alias for $2;
      ieqminus__query2	      alias for $3;
      ieqminus__minus_desc    alias for $4;
      ieqminus__raise_exc     alias for $5;
      v_query		      varchar;
      rec_tableminus	      record;
      v_eq		      boolean := ''t'';

begin

	v_query := '' ( '' ||
		   ieqminus__query1 ||
		   '' except '' ||
		   ieqminus__query2 ||
		   '' ) '' ||
		   '' union '' ||
		   '' ( '' ||
		   ieqminus__query2 ||
		   '' except '' ||
		   ieqminus__query1 ||
		   '' ) '';

	for  rec_tableminus in execute v_query;

	   -- Will not go in this loop if v_query result is null, so
	   -- we need to set the default value of v_eq to true.
	   if found
	   then
	      v_eq := ''f'';
	   end if;

	   -- One is enough
	   exit;

	end loop;

      return ut_assert__this (
                       ut_assert__expected (ieqminus__msg || '' '' || ieqminus__minus_desc,
					    ieqminus__query1, 
					    ieqminus__query2
					    ),
		       v_eq,
		       ''f'',
		       ieqminus__raise_exc
		       );

end;' language 'plpgsql';

create function ut_assert__eqtable (
       varchar,
       varchar,
       varchar,
       varchar,
       varchar,
       boolean
)
returns integer as '
declare
      eqtable__msg	      alias for $1;
      eqtable__check_this     alias for $2;
      eqtable__against_this   alias for $3;
      eqtable__check_where    alias for $4; -- default null
      eqtable__against_where  alias for $5; -- default null
      eqtable__raise_exc      alias for $6; -- default false
begin
      return ut_assert__ieqminus (eqtable__msg,
			  ''SELECT * FROM '' || eqtable__check_this || ''  WHERE '' ||
			  coalesce (eqtable__check_where, ''1=1''),
			  ''SELECT * FROM '' || eqtable__against_this || ''  WHERE '' ||
			  coalesce (eqtable__against_where, ''1=1''),
			  ''Table Equality'',
			  eqtable__raise_exc
			  );
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eqtable (
       varchar,
       varchar,
       varchar
)
returns integer as '
declare
      eqtable__msg	      alias for $1;
      eqtable__check_this     alias for $2;
      eqtable__against_this   alias for $3;
begin

      return ut_assert__eqtable(eqtable__msg,eqtable__check_this,eqtable__against_this,null,null,''f'');

end;' language 'plpgsql';


create function ut_assert__eqtabcount (
       varchar,
       varchar,
       varchar,
       varchar,
       varchar,
       boolean
)
returns integer as '
declare
      eqtabcount__msg		 alias for $1;
      eqtabcount__check_this     alias for $2;
      eqtabcount__against_this   alias for $3;
      eqtabcount__check_where    alias for $4; -- default null
      eqtabcount__against_where  alias for $5; -- default null
      eqtabcount__raise_exc      alias for $6; -- default false
begin
      return ut_assert__ieqminus (eqtabcount__msg,
			  ''SELECT COUNT(*) FROM '' || eqtabcount__check_this || ''  WHERE '' ||
			  coalesce (eqtabcount__check_where, ''1=1''),
			  ''SELECT COUNT(*) FROM '' || eqtabcount__against_this || ''  WHERE '' ||
			  coalesce (eqtabcount__against_where, ''1=1''),
			  ''Table Count Equality'',
			  eqtabcount__raise_exc
			  );
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eqtabcount (
       varchar,
       varchar,
       varchar
)
returns integer as '
declare
      eqtabcount__msg		 alias for $1;
      eqtabcount__check_this     alias for $2;
      eqtabcount__against_this   alias for $3;
begin

      return ut_assert__eqtabcount(eqtabcount__msg,eqtabcount__check_this,eqtabcount__against_this,null,null,''f'');

end;' language 'plpgsql';

create function ut_assert__eqquery (
       varchar,
       varchar,
       varchar,
       boolean
)
returns integer as '
declare
      eqquery__msg	      alias for $1;
      eqquery__check_this     alias for $2;
      eqquery__against_this   alias for $3;
      eqquery__raise_exc      alias for $4; -- default null
begin
      return ut_assert__ieqminus (eqquery__msg,
			          eqquery__check_this,
				  eqquery__against_this,
				  ''Query Equality'',
				  eqquery__raise_exc
				  );
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__eqquery (
       varchar,
       varchar,
       varchar
)
returns integer as '
declare
      eqquery__msg	      alias for $1;
      eqquery__check_this     alias for $2;
      eqquery__against_this   alias for $3;
begin

      return ut_assert__eqquery(eqquery__msg,eqquery__check_this,eqquery__against_this,''f'');

end;' language 'plpgsql';

create function ut_assert__isnotnull (
      varchar,
      varchar,
      boolean,
      boolean
) returns integer as '
declare
      isnotnull__msg		alias for $1;
      isnotnull__check_this	alias for $2;
      isnotnull__null_ok	alias for $3; -- default false
      isnotnull__raise_exc	alias for $4; -- default false
begin
      return ut_assert__this (
	        ''IS NOT NULL: '' || isnotnull__msg,
		isnotnull__check_this IS NOT NULL,
		isnotnull__null_ok,
		isnotnull__raise_exc
		);
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__isnotnull (
       varchar,
       varchar
)
returns integer as '
declare
      isnotnull__msg	        alias for $1;
      isnotnull__check_this     alias for $2;
begin

      return ut_assert__isnotnull(isnotnull__msg,isnotnull__check_this,''f'',''f'');

end;' language 'plpgsql';


create function ut_assert__isnull (
      varchar,
      varchar,
      boolean,
      boolean
) returns integer as '
declare
      isnull__msg		alias for $1;
      isnull__check_this	alias for $2;
      isnull__null_ok		alias for $3; -- default false
      isnull__raise_exc		alias for $4; -- default false
begin
      return ut_assert__this (
	        ''IS NULL: '' || isnull__msg,
		isnull__check_this IS NULL,
		isnull__null_ok,
		isnull__raise_exc
		);
end;' language 'plpgsql';


-- Overload for calls with default values
create function ut_assert__isnull (
       varchar,
       varchar
)
returns integer as '
declare
      isnull__msg	     alias for $1;
      isnull__check_this     alias for $2;
begin

      return ut_assert__isnull(isnull__msg,isnull__check_this,''f'',''f'');

end;' language 'plpgsql';

create function ut_assert__isnotnull (
      varchar,
      boolean,
      boolean,
      boolean
) returns integer as '
declare
      isnotnull__msg		alias for $1;
      isnotnull__check_this	alias for $2;
      isnotnull__null_ok	alias for $3; -- default false
      isnotnull__raise_exc	alias for $4; -- default false
begin
      return ut_assert__this (
	        ''IS NOT NULL: '' || isnotnull__msg,
		isnotnull__check_this IS NOT NULL,
		isnotnull__null_ok,
		isnotnull__raise_exc
		);
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__isnotnull (
       varchar,
       boolean
)
returns integer as '
declare
      isnotnull__msg	        alias for $1;
      isnotnull__check_this     alias for $2;
begin

      return ut_assert__isnotnull(isnotnull__msg,isnotnull__check_this,''f'',''f'');

end;' language 'plpgsql';

create function ut_assert__isnull (
      varchar,
      boolean,
      boolean,
      boolean
) returns integer as '
declare
      isnull__msg		alias for $1;
      isnull__check_this	alias for $2;
      isnull__null_ok		alias for $3; -- default false
      isnull__raise_exc		alias for $4; -- default false
begin
      return ut_assert__this (
	        ''IS NULL: '' || isnull__msg,
		isnull__check_this IS NULL,
		isnull__null_ok,
		isnull__raise_exc
		);
end;' language 'plpgsql';

-- Overload for calls with default values
create function ut_assert__isnull (
       varchar,
       boolean
)
returns integer as '
declare
      isnull__msg	     alias for $1;
      isnull__check_this     alias for $2;
begin

      return ut_assert__isnull(isnull__msg,isnull__check_this,''f'',''f'');

end;' language 'plpgsql';






