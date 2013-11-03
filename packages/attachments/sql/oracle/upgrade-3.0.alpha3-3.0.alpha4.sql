-- /packages/intranet-freelance/sql/oracle/upgrade-3.0.alpha3-3.0.alpha4.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- removed the "select ... from im_freelancers" into .xql file
update im_view_columns set
	extra_from = '',
	extra_where = '',
	extra_select = ''
where
	column_id = 5200
;

delete from im_view_columns
where column_id = 5203
;

