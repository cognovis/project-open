-- drop the tracking and aggregating object views...
-- 
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis davis@xarg.net
-- @creation-date 10/22/2003
--
-- @cvs-id $Id: views-drop.sql,v 1.2 2007/08/01 08:59:56 marioa Exp $
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

select drop_package('views');
drop table view_aggregates_by_type;
drop table views_by_type;
drop table view_aggregates;
drop table views_views;
drop function views_views_upd_tr() cascade;
drop function views_views_ins_tr() cascade;
drop function views_by_type_ins_tr() cascade;
drop function views_by_type_upd_tr() cascade;
