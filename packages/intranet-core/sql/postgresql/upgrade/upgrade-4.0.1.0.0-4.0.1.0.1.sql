-- 
-- packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql
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
-- @creation-date 2011-03-28
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql','');

-- Introduce variable_name field
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_view_columns' and lower(column_name) = 'variable_name';
        IF v_count > 0 THEN return 0; END IF;

	alter table im_view_columns add variable_name varchar(100);

        return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

-- Introduce variable_name field
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_view_columns' and lower(column_name) = 'datatype';
        IF v_count > 0 THEN return 0; END IF;

	alter table im_view_columns add datatype varchar(100);

        return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();
