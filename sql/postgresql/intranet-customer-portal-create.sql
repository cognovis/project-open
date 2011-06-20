-- /packages/intranet-customer-portal/sql/postgres/intranet-customer-portal-create.sql
--
-- Copyright (C) 2011-2012 ]project-open[ 
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
--
-- @author klaus.hofeditz@project-open.com

-- Create table for inquiries 

create sequence im_inquiries_customer_portal_seq start 1;
create table im_inquiries_customer_portal (
        inquiry_id              integer
                                primary key,
        first_names             varchar(50),
        last_names              varchar(80),
        email	                varchar(50),
        company_name            varchar(80),
        phone			varchar(20),
        security_token 		varchar(40),
	company_id		integer,
	status_id		integer,
	session_id		varchar(200)
);

create sequence im_inquiries_files_seq start 1;
create table im_inquiries_files (
        inquiry_files_id        integer
                                primary key,
        inquiry_id              integer,
        file_name               varchar(50)
                                not null,
	source_language 	varchar(4) 
                                not null,
	target_languages	varchar(200)
                                not null, 
	deliver_date		date,
	project_id		integer,
	file_path		varchar(200)
);

-- Create DynView for project list  

delete from im_view_columns where view_id = 960; 
delete from im_views where view_id = 960; 

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (960, 'project-list-customer-portal', 'view_projects', 1415);

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS '
declare
        v_count                 integer;
begin
	select column_id+1 into v_count from im_view_columns order by column_id desc limit 1;

	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for, ajax_configuration) values (v_count,960,NULL,''[lang::message::lookup "" intranet-core.Project "Project"]'',
	''project_name'','''','''',1,'''', ''def '');

        return 1;

end;' LANGUAGE 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();


