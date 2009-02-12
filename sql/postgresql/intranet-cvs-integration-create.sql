-- /packages/intranet-cvs-integration/sql/postgresql/intranet-cvs-integration.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Integrate with CVS
--
-- We setup a database table to be filled with records
-- being returned from the CVS "rlog" command
-- Together with the "cvs_user" field in "persons"
-- this allows us to track how many lines have been
-- written on what project by a developer.

drop sequence im_cvs_activity_line_seq;
drop table im_cvs_activity;

create sequence im_cvs_activity_line_seq start 1;
create table im_cvs_activity (
	line_id			integer
				constraint im_cvs_activity_pk
				primary key,
	cvs_project		text,
	filename		text,
	revision		text,
	date			timestamptz,
	author			text,
	state			text,
	lines_add		integer,
	lines_del		integer,
	note			text,
		constraint im_cvs_activity_filname_un
		unique (filename, date, revision)
);
