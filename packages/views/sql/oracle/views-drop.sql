-- drop the tracking and aggregating object views...
-- 
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis davis@xarg.net
-- @creation-date 10/22/2003
--
-- @cvs-id $Id: views-drop.sql,v 1.2 2007/08/01 08:59:09 marioa Exp $
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

DROP PACKAGE VIEWS_VIEW;
DROP PACKAGE VIEWS_VIEW_BY_TYPE;
DROP TABLE VIEW_AGGREGATES_BY_TYPE;
DROP TABLE VIEWS_BY_TYPE;
DROP TABLE VIEW_AGGREGATES;
DROP TABLE VIEWS_VIEWS;