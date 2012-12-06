-- /packages/intranet-hr/sql/postgresql/intranet-hr-create-resource-availability.sql
--
-- ]project-open[ HR Module
--
-- frank.bergmann@project-open.com,
-- malte.sussdorff@cognovis.de
--
-- Copyright (C) 2012 by Authors
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.


----------------------------------------------------
-- Availability of resources (users, skill profiles, conf_items, ...)
-- over time.
--


create sequence im_resource_availability_seq;

create table im_resource_availability (
       	     			-- primary key
	availability_id		integer
				constraint im_resource_availability_pk 
				primary key
				default (next_val('im_resource_availability_seq')),

				-- "input fields" - defines the object and the time dimension
				-- please make sure that the time dimension does not have "holes"
	resource_id		integer 
				constraint im_resource_availability_object_fk
				references im_biz_objects,
	start_date		timestamptz,
	end_date		timestamptz,

				-- "output fields" - availability of resource to various
				-- external objects. You need to sum up availabilities
				-- for a given constraint (for example: cost_center_id),
				-- because there may be multiple entries per skill_profile_id)
	availability_percent	numeric(12,2)
				constraint im_resource_availability_availability_ck
				(availability_percent between 0.0 and 100.0),

	cost_center_id		integer 
				constraint im_resource_availability_cost_center_fk
				references im_cost_centers,
	office_id		integer
				constraint im_resource_availability_office_fk
				references im_offices,
	skill_profile_id	integer 
				constraint im_resource_availability_skill_profile_fk
				references parties
);


