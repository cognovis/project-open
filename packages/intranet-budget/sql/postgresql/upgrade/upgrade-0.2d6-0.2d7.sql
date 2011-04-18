-- 
-- packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d6-0.2d7.sql
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
-- @creation-date 2011-04-18
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d6-0.2d7.sql','');

update im_view_columns set column_name = '#intranet-budget.Priority#' where column_id = 92015;
update im_view_columns set column_name = '#intranet-budget.Project_ID#' where column_id = 92016;
update im_view_columns set column_name = '#intranet-core.Project#' where column_id = 92025;
update im_view_columns set column_name = '#intranet-budget.Operational_Priority#' where column_id = 92026;
update im_view_columns set column_name = '#intranet-budget.Strategic_Priority#' where column_id = 92027;
update im_view_columns set column_name = '#intranet-core.Project_Status#' where column_id = 1003;