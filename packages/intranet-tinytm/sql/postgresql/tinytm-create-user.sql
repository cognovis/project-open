-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-anonymous.sql
--
-- Copyright (c) 2008 ]project-open[
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- Please see the GNU General Public License for more details.
--
-- @author      frank.bergmann@project-open.com


-----------------------------------------------------------------------------------------------------
-- Create a user with the necessary access to TinyTM
-----------------------------------------------------------------------------------------------------


CREATE USER bbigboss WITH PASSWORD 'ben';

GRANT SELECT ON acs_magic_objects TO bbigboss;
GRANT SELECT ON tinytm_groups TO bbigboss;
GRANT SELECT ON tinytm_segment_types TO bbigboss;
GRANT SELECT ON tinytm_languages TO bbigboss;
GRANT SELECT ON tinytm_subject_areas TO bbigboss;
GRANT SELECT ON tinytm_customers TO bbigboss;
GRANT SELECT ON tinytm_tags TO bbigboss;

GRANT SELECT ON tinytm_segments TO bbigboss;
GRANT INSERT ON tinytm_segments TO bbigboss;

GRANT SELECT ON tinytm_segments_seq TO bbigboss;
GRANT UPDATE ON tinytm_segments_seq TO bbigboss;

