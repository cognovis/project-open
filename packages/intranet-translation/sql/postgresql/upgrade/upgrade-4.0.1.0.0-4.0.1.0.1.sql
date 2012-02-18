-- 
-- packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d11-0.2d12.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-01-22
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where 
              table_name = ''im_trans_tasks'' 
              and column_name = ''trans_end_date'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_trans_tasks add column trans_end_date timestamptz;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where 
              table_name = ''im_trans_tasks'' 
              and column_name = ''edit_end_date'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_trans_tasks add column edit_end_date timestamptz;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where 
              table_name = ''im_trans_tasks'' 
              and column_name = ''proof_end_date'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_trans_tasks add column proof_end_date timestamptz;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where 
              table_name = ''im_trans_tasks'' 
              and column_name = ''other_end_date'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_trans_tasks add column other_end_date timestamptz;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();