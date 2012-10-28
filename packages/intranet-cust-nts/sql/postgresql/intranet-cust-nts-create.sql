-- 
-- packages/intranet-cust-nts/sql/postgresql/intranet-cust-nts-create.sql
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
-- @creation-date 2012-10-28
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cust-nts/sql/postgresql/intranet-cust-nts-create.sql','');

-- Create the dynfields for employees

-- WIDGET: Intranet Employee Pipeline State
SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'employee_pipeline_status',		-- widget_name
		'#intranet-core.Employee_Pipeline_Status#',	-- pretty_name
		'#intranet-core.Employee_Pipeline_Status#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'im_category_tree',		-- widget
		'integer',		-- sql_datatype
		'{custom {category_type "Intranet Employee Pipeline State"}}', 
		'im_name_from_id'
);

-- SELECT im_dynfield_attribute_new ('person', 'cost_center_id', '#intranet-core.Cost_Center#', 'cost_centers', 'integer', 't', 10, 't', 'im_employees');