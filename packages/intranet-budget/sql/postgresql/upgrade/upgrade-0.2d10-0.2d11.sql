-- 
-- packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d10-0.2d11.sql
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
-- @creation-date 2011-05-24
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d10-0.2d11.sql','');

select acs_privilege__create_privilege('approve_budgets','Approve Budgets','Approve Budgets');
select acs_privilege__add_child('admin', 'approve_budgets');
