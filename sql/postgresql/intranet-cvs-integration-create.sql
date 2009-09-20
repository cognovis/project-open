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



-----------------------------------------------------------
-- DynFields
--
-- Define fields necessary for CVS repository access



alter table im_conf_items add cvs_system text;
alter table im_conf_items add cvs_protocol text;
alter table im_conf_items add cvs_user text;
alter table im_conf_items add cvs_password text;
alter table im_conf_items add cvs_hostname text;
alter table im_conf_items add cvs_port integer;
alter table im_conf_items add cvs_path text;


SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_system', 'CVS System', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_protocol', 'CVS Protocol', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_user', 'CVS User', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_password', 'CVS Password', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_hostname', 'CVS Hostname', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_port', 'CVS Port', 'integer', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_path', 'CVS Path', 'textbox_medium', 'string', 'f');
