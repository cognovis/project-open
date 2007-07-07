-- /packages/intranet-hr/sql/oracle/intranet-hr-create.sql
--
-- ]project[ Dashboard Module
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com

----------------------------------------------------
-- Aggregated im_costs view

-- create or replace view im_costs_aggreg as
-- select	*,
-- 	CASE 
-- 	    WHEN cost_type_id in (3700, 3702) THEN 1
-- 	    WHEN cost_type_id in (3704, 3706, 3712, 3718) THEN -1
-- 	    ELSE 0
-- 	END as signum,
-- 	to_date(to_char(effective_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') + payment_days as due_date,
-- 	to_char(to_date(to_char(effective_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') + payment_days, 'YYYY-MM') as due_month
-- from	im_costs
-- where	cost_status_id not in (3812)	-- not in deleted
-- ;

