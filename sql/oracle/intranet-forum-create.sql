-----------------------------------------------------------
-- Tasks, Incidents, News and Discussions (TIND)
--
-- A simplified version of the ACS BBOARD module,
-- related to groups (project, customers, ...).
-- The idea is to provide project members with a
-- unified communication medium.

-----------------------------------------------------------
-- Topics
--

create sequence im_forum_topics_seq start with 1;
create table im_forum_topics (
	-- administrative information
	topic_id	integer
			constraint im_forum_topics_pk primary key,
	topic_name	varchar(200),
	topic_path	varchar(200),
	object_id	integer not null 
			constraint im_forum_topics_object_fk
			references acs_objects,
	parent_id	integer
			constraint im_forum_topics_parent_fk
			references im_forum_topics,
	topic_type_id	integer not null
			constraint im_forum_topics_type_fk
			references im_categories,
	topic_status_id	integer
			constraint im_forum_topics_status_fk
			references im_categories,
	posting_date	date,
	owner_id	integer not null
			constraint im_forum_topics_owner_fk
			references users,
	scope		varchar(20) default 'group'
			constraint im_forum_topics_scope_ck
			check (scope in ('pm', 'group','public','client','staff','not_client')),
	-- allow to comment on non-group items if on_which_table not null
	on_what_id	integer,
	on_which_table	varchar(50),
	-- message content
	subject		varchar(200) not null,
	message		clob,
	-- task and incident specific fields
	priority	number(1),
	due_date	date,
	asignee_id	integer
			constraint im_forum_topics_asignee_fk
			references users
);
create index im_forum_topics_object_idx on im_forum_topics (object_id);

-----------------------------------------------------------
-- Folders for Intranet users
--
-- folder_id in (0 or NULL) indicates "Inbox" items
-- folder_id = 1 indicates "Deleted" items
-- folder_id < 10 is reserved for system folders (user_id=NULL)
-- folder_id for users start with 10

create table im_forum_folders (
	folder_id	integer
			constraint im_forum_folders_pk
			primary key,
	user_id		integer
			constraint im_forum_folders_user_fk
			references users,
	parent_id	integer
			constraint im_forum_folders_parent_fk
			references im_forum_folders,
	folder_name	varchar(200)
);


-----------------------------------------------------------
-- Map between topics and users:
-- Remembers the interaction between a user and a topic.
--
-- Please note that this map is outer-joined with every
-- im_forum_topics "select", leading to many NULL values,
-- becuase this topic-user-map is not defined. So NULL
-- values have to be considered "default".

create table im_forum_topic_user_map (
	topic_id	integer
			constraint im_forum_topics_um_topic_fk
			references im_forum_topics,
	user_id		integer
			constraint im_forum_topics_um_user_fk
			references users,
	-- read_p in ('f' or NULL) indicates "New" items
	read_p		char(1) default 't'
			constraint im_forum_topics_um_read_ck
			check (read_p in ('t','f')),
	-- folder_id in (0 or NULL) indicates "Inbox" items
	-- folder_id = 1 indicates "Deleted" items
	-- folder_id for users start with 10
	folder_id	integer default 0
			constraint im_forum_topics_um_folder_fk
			references im_forum_folders,
	receive_updates	varchar(20) default 'major'
			constraint im_forum_topics_um_rec_ck check (
			receive_updates in ('all','none','major')),
	constraint im_forum_topics_um_rec_pk
	primary key (topic_id, user_id)
);

-----------------------------------------------------------
-- Uploaded Files
--

create sequence im_forum_files_seq start with 1;
create table im_forum_files (
	msg_id			integer 
				constraint im_forum_files_pk
				primary key,
	n_bytes			integer,
	client_filename		varchar(4000),
	filename_stub		varchar(200),
	caption			varchar(200),
	content			clob
);


-----------------------------------------------------------
-- Setup the default folders
--
-- folder_id in (0 or NULL) indicates "Inbox" items
-- folder_id = 1 indicates "Deleted" items
-- folder_id for users start with 10


insert into im_forum_folders values (0, null, null, 'Inbox');
insert into im_forum_folders values (1, null, null, 'Deleted');
insert into im_forum_folders values (2, null, null, 'Sys2');
insert into im_forum_folders values (3, null, null, 'Sys3');
insert into im_forum_folders values (4, null, null, 'Sys4');
insert into im_forum_folders values (5, null, null, 'Sys5');
insert into im_forum_folders values (6, null, null, 'Sys6');
insert into im_forum_folders values (7, null, null, 'Sys7');
insert into im_forum_folders values (8, null, null, 'Sys8');
insert into im_forum_folders values (9, null, null, 'Sys9');


-- Forum Topic Types
delete from im_categories where category_type = 'Intranet Topic Type';

INSERT INTO im_categories VALUES (1100,'News',
'News item that may or may not be commented.',
'Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1102,'Incident',
'Critical task that needs rapid resolution',
'Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1104,'Task',
'Task that needs to be performed',
'Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1106,'Discussion',
'Request for response/interaction',
'Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1108,'Note',
'Calling attention about something',
'Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1110,'Help Request',
'Help Request','Intranet Topic Type','category','t','f');

INSERT INTO im_categories VALUES (1190,'Reply',
'Reply','Intranet Topic Type','category','t','f');

commit;
-- reserved until 1199


create or replace view im_forum_topic_types as 
select 
	category_id as topic_type_id, 
	category as topic_type
from im_categories 
where category_type = 'Intranet Topic Type';


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Project/Open Core
-- to render the forum components in the Home, Users, Projects 
-- and Customer pages.
--
-- The TCL code in the "component_tcl" field is executed
-- via "im_component_bay" in an "uplevel" statemente, exactly
-- as if it would be written inside the .adp <%= ... %> tag.
-- I know that's relatively dirty, but TCL doesn't provide
-- another way of "late binding of component" ...


-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-forum');
    im_menu.del_module(module_name => 'intranet-forum');
END;
/
show errors

commit;





-- Setup the "Forum" main menu entry
--
declare
    v_menu		integer;
begin
    v_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet-forum',
	name =>		'Forum',
	url =>		'/intranet-forum/',
	sort_order =>	20,
	parent_menu_id => null
    );
end;
/
show errors

commit;
	

-- Show the forum component in project page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Forum Component',
	package_name =>	'intranet-forum',
        page_url =>     '/intranet/projects/view',
        location =>     'right',
        sort_order =>   10,
        component_tcl => 
	'im_table_with_title \
		[im_forum_create_bar \
			"<B>Forum Items<B>" \
			$project_id \
			$return_url \
		] \
		[im_forum_component \
			$user_id \
			$project_id \
			$current_url \
			$return_url \
			[list \
				project_id \
				forum_start_idx \
				forum_order_by \
				forum_how_many \
				forum_view_name \
			] \
			project \
			[im_opt_val forum_view_name] \
			[im_opt_val forum_order_by] \
			"f" \
			0 \
			0 \
			0 \
			0 \
			1 \
			1 \
			0 \
		]'

    );
end;
/
show errors

commit;

-- ad_proc im_forum_component {user_id group_id current_page_url return_url export_var_list {view_name "forum_list_short"} {forum_order_by "priority"} {restrict_to_mine_p f} {restrict_to_topic_type_id 0} {restrict_to_topic_status_id 0} {restrict_to_asignee_id 0} {max_entries_per_page 0} {start_idx 1} {restrict_to_new_topics 0} {restrict_to_folder 0} }


-- Show the forum component in customer page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Customers Forum Component',
	package_name =>	'intranet-forum',
        page_url =>     '/intranet/customers/view',
        location =>     'right',
        sort_order =>   10,
        component_tcl => 
	'im_table_with_title \
		[im_forum_create_bar \
			"<B>Forum Items<B>" \
			$customer_id \
			$return_url \
		] \
		[im_forum_component \
			$user_id \
			$customer_id \
			$current_url \
			$return_url \
			[list \
				customer_id \
				forum_start_idx \
				forum_order_by \
				forum_how_many \
				forum_view_name \
			] \
			customer \
			[im_opt_val forum_view_name] \
			[im_opt_val forum_order_by] \
			"f" \
			0 \
			0 \
			0 \
			0 \
			1 \
			1 \
			0 \
		]'

    );
end;
/
show errors

commit;

-- ad_proc im_forum_component {user_id group_id current_page_url return_url export_var_list {view_name "forum_list_short"} {forum_order_by "priority"} {restrict_to_mine_p f} {restrict_to_topic_type_id 0} {restrict_to_topic_status_id 0} {restrict_to_asignee_id 0} {max_entries_per_page 0} {start_idx 1} {restrict_to_new_topics 0} {restrict_to_folder 0} }


-- Show the forum component in home page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Home Forum Component',
	package_name =>	'intranet-forum',
        page_url =>     '/intranet/index',
        location =>     'right',
        sort_order =>   10,
        component_tcl => 
	'im_table_with_title \
		[im_forum_create_bar \
			"<B>Forum Items<B>" \
			0 \
			$return_url \
		] \
		[im_forum_component \
			$user_id \
			0 \
			$current_url \
			$return_url \
			[list \
				forum_start_idx \
				forum_order_by \
				forum_how_many \
				forum_view_name \
			] \
			home \
			[im_opt_val forum_view_name] \
			[im_opt_val forum_order_by] \
			"t" \
			0 \
			0 \
			0 \
			0 \
			1 \
			1 \
			0 \
		]'

    );
end;
/
show errors

commit;

-- ad_proc im_forum_component {user_id group_id current_page_url return_url export_var_list {view_name "forum_list_short"} {forum_order_by "priority"} {restrict_to_mine_p f} {restrict_to_topic_type_id 0} {restrict_to_topic_status_id 0} {restrict_to_asignee_id 0} {max_entries_per_page 0} {start_idx 1} {restrict_to_new_topics 0} {restrict_to_folder 0} }



-- Intranet Topic Status
delete from im_categories where category_type = 'Intranet Topic Status';

INSERT INTO im_categories VALUES (1200,'Open',
'A topic has been generated, but is not assigned to anybody (discussion, ...)',
'Intranet Topic Status','category','t','f');

INSERT INTO im_categories VALUES (1202,'Assigned',
'A task has been assigned to someone, but this person has not confirmed yet.',
'Intranet Topic Status','category','t','f');

INSERT INTO im_categories VALUES (1204,'Accepted',
'The asignee has confirmed that he will be responsible for the task',
'Intranet Topic Status','category','t','f');

INSERT INTO im_categories VALUES (1206,'Rejected',
'The asignee has rejected to take responsability for the task',
'Intranet Topic Status','category','t','f');

INSERT INTO im_categories VALUES (1208,'Needs Clarify',
'The asignee passes the task back to the owner for clarification',
'Intranet Topic Status','category','t','f');

INSERT INTO im_categories VALUES (1210,'Closed',
'The owner has canceled the task or the asignee has finished the task',
'Intranet Topic Status','category','t','f');

commit;
-- reserved until 1299


create or replace view im_forum_topic_status as 
select 	category_id as topic_type_id, 
	category as topic_type
from im_categories 
where category_type = 'Intranet Topic Status';
	

create or replace view im_forum_topic_status_active as 
select 	category_id as topic_type_id, 
	category as topic_type
from im_categories 
where	category_type = 'Intranet Topic Status'
	and category_id not in (1202, 1204, 1206);



-- views to "forum" items: 40-49
insert into im_views (view_id, view_name, visible_for) values (40, 'forum_list_home', 'view_forums');
insert into im_views (view_id, view_name, visible_for) values (41, 'forum_list_project', 'view_forums');
insert into im_views (view_id, view_name, visible_for) values (42, 'forum_list_forum', 'view_forums');
insert into im_views (view_id, view_name, visible_for) values (43, 'forum_list_extended', 'view_forums');
insert into im_views (view_id, view_name, visible_for) values (44, 'forum_list_short', 'view_forums');
insert into im_views (view_id, view_name, visible_for) values (45, 'forum_list_customer', 'view_forums');


-- ForumList for home page
--
delete from im_view_columns where column_id >= 4000 and column_id < 4099;
insert into im_view_columns values (4000,40,NULL,'P',
'$priority','','',2,'im_permission $user_id view_forums');
insert into im_view_columns values (4002,40,NULL,'Type',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
[im_gif $topic_type]</a>"',
'','',4,'im_permission $user_id view_forums');
insert into im_view_columns values (4003,40,NULL,'Project',
'"<a href=/intranet/projects/view?project_id=$project_id>$project_nr</a>"',
'','',5,'im_permission $user_id view_forums');
insert into im_view_columns values (4004,40,NULL,'Subject',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
$subject</a>"','','',6,'im_permission $user_id view_forums');
insert into im_view_columns values (4006,40,NULL,'Due',
'$due_date','','',8,'im_permission $user_id view_forums');
insert into im_view_columns values (4010,40,NULL,
'"[im_gif help "Select topics here for processing"]"',
'"<input type=checkbox name=topic_id.$topic_id>"',
'','',12,'im_permission $user_id view_forums');
commit;



-- ForumList for ProjectViewPage or CustomerViewPage
--
delete from im_view_columns where column_id >= 4100 and column_id < 4199;
insert into im_view_columns values (4100,41,NULL,'P',
'$priority','','',2,'im_permission $user_id view_forums');
insert into im_view_columns values (4102,41,NULL,'Type',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
[im_gif $topic_type]</a>"',
'','',4,'im_permission $user_id view_forums');
insert into im_view_columns values (4104,41,NULL,'Subject',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
$subject</a>"','','',6,'im_permission $user_id view_forums');
insert into im_view_columns values (4106,41,NULL,'Due',
'$due_date','','',8,'im_permission $user_id view_forums');
insert into im_view_columns values (4107,41,NULL,'Own',
'"<a href=/intranet/users/view?user_id=$owner_id>$owner_initials</a>"',
'','',9,'im_permission $user_id view_forums');
insert into im_view_columns values (4108,41,NULL,'Ass',
'"<a href=/intranet/users/view?user_id=$asignee_id>$asignee_initials</a>"',
'','',10,'im_permission $user_id view_forums');
insert into im_view_columns values (4110,41,NULL,
'"[im_gif help "Select topics here for processing"]"',
'"<input type=checkbox name=topic_id.$topic_id>"',
'','',12,'im_permission $user_id view_forums');
commit;


-- ForumList for the forum index page (all projects with a lot of space)
--
delete from im_view_columns where column_id >= 4200 and column_id < 4299;
insert into im_view_columns values (4200,42,NULL,'P',
'$priority','','',2,'im_permission $user_id view_forums');
insert into im_view_columns values (4201,42,NULL,'Project',
'"<a href=/intranet/projects/view?project_id=$project_id>$project_nr</a>"',
'','',3,'im_permission $user_id view_forums');
insert into im_view_columns values (4202,42,NULL,'Type',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
[im_gif $topic_type]</a>"',
'','',4,'im_permission $user_id view_forums');
insert into im_view_columns values (4204,42,NULL,'Subject',
'"<a href=/intranet/forum/new-tind?[export_url_vars topic_id return_url]>\
$subject</A>"','','',6,'im_permission $user_id view_forums');
insert into im_view_columns values (4206,42,NULL,'Due',
'$due_date','','',8,'im_permission $user_id view_forums');
insert into im_view_columns values (4207,42,NULL,'Own',
'"<a href=/intranet/users/view?user_id=$owner_id>$owner_initials</a>"',
'','',9,'im_permission $user_id view_forums');
insert into im_view_columns values (4208,42,NULL,'Ass',
'"<a href=/intranet/users/view?user_id=$asignee_id>$asignee_initials</a>"',
'','',10,'im_permission $user_id view_forums');
insert into im_view_columns values (4209,42,NULL,'Read',
'$read','','',11,'im_permission $user_id view_forums');
insert into im_view_columns values (4210,42,NULL,
'"[im_gif help "Select topics here for processing"]"',
'"<input type=checkbox name=topic_id.$topic_id>"',
'','',12,'im_permission $user_id view_forums');
insert into im_view_columns values (4212,42,NULL,'Folder',
'$folder_name','','',14,'im_permission $user_id view_forums');
commit;


