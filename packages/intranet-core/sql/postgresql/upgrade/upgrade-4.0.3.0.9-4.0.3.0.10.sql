-- 
-- 
-- 
-- Copyright (c) 2013, cognovís GmbH, Hamburg, Germany
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
-- @creation-date 2013-01-18
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.9-4.0.3.0.10.sql','');

-- Update Views with a label column
alter table im_views add column view_label varchar(1000);

update im_views set view_label = replace(view_name,'_',' ');

-- Add a new DynView Type for the invoice list page.
SELECT im_category_new ('1451', 'List - Project', 'Intranet DynView Type');

-- Update the existing list type
update im_views set view_type_id = 1451 where view_name = 'project_list';
update im_views set view_label = 'Project List' where view_name = 'project_list';

-- Add project revenue view
insert into im_views (view_id, view_name, view_label, view_type_id)
values (1020, 'project_revenue', 'Project Revenue', 1451);
