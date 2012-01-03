-- 
-- packages/intranet-freelance-invoices/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql
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
-- @author <yourname> (<your email>)
-- @creation-date 2012-01-03
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-freelance-invoices/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql','');

alter table im_trans_tasks drop column trans_end_date;
alter table im_trans_tasks add column trans_end_date timestamptz;
alter table im_trans_tasks drop column edit_end_date;
alter table im_trans_tasks add column edit_end_date timestamptz;
alter table im_trans_tasks drop column proof_end_date;
alter table im_trans_tasks add column proof_end_date timestamptz;
alter table im_trans_tasks drop column other_end_date;
alter table im_trans_tasks add column other_end_date timestamptz;