------------------------------------------------------------
-- Forums
------------------------------------------------------------

-- Get everything about a Forum Topic
select
	t.*
	t.object_id,
	m.read_p,
	m.folder_id,
	m.receive_updates,
	im_category_from_id(t.topic_status_id) as topic_status,
	im_category_from_id(t.topic_type_id) as topic_type,
	im_name_from_user_id(t.owner_id) as owner_name,
	im_name_from_user_id(t.asignee_id) as asignee_name,
	acs_object__name(t.object_id) as object_name
from
	im_forum_topics t
	LEFT JOIN (
		select * 
		from im_forum_topic_user_map 
		where user_id = :user_id
	) m USING (topic_id)
where
	t.topic_id=:topic_id;

-- Get a list of topics for the current user
select
	t.*,
	to_char(t.due_date, :date_format) as due_date,
	CASE 	WHEN due_date < now() and t.topic_type_id in (1102, 1104)
		THEN 1 
		ELSE 0 
	END as overdue,
	acs_object__name(t.object_id) as object_name,
	m.read_p,
	m.folder_id,
	f.folder_name,
	m.receive_updates,
	u.url as object_view_url,
	im_initials_from_user_id(t.owner_id) as owner_initials,
	im_initials_from_user_id(t.asignee_id) as asignee_initials,
	im_category_from_id(t.topic_type_id) as topic_type,
	im_category_from_id(t.topic_status_id) as topic_status
from
	im_forum_topics t
	LEFT JOIN 
	   (select * from im_forum_topic_user_map where user_id=:user_id) m using (topic_id)
	LEFT JOIN 
	   im_forum_folders f using (folder_id)
	LEFT JOIN
	(	select 1 as p, 
			object_id_one as object_id 
		from 	acs_rels
		where	object_id_two = :user_id
	) member_objects using (object_id)
	LEFT JOIN
	(	select 1 as p, 
			r.object_id_one as object_id 
		from 	acs_rels r,
			im_biz_object_members m
		where	r.object_id_two = :user_id
			and r.rel_id = m.rel_id
			and m.object_role_id in (1301, 1302, 1303)
	) admin_objects using (object_id),
	acs_objects o
	LEFT JOIN 
	   (select * from im_biz_object_urls where	url_type='view') u using (object_type)
where
	(t.parent_id is null or t.parent_id=0)
	and t.object_id != 1
	and t.object_id = o.object_id



-- Get the list of Sub-Topics for a given Topic
-- (hierarchical query).
select
	t.*,
	acs_object__name(t.object_id) as project_name,
	tr.indent_level,
	(10-tr.indent_level) as colspan_level,
	im_name_from_user_id(ou.user_id) as owner_name,
	im_name_from_user_id(au.user_id) as asignee_name
from
	(select
		children.topic_id,
		children.tree_sortkey,
		tree_level(children.tree_sortkey) -
	tree_level(parent.tree_sortkey) as indent_level
	from
		im_forum_topics parent,	
		im_forum_topics children
	where
		children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.topic_id = :topic_id
	) tr,
	users ou,
	im_forum_topics t
      LEFT JOIN
	users au ON t.asignee_id=au.user_id
where
	tr.topic_id = t.topic_id
	and t.owner_id=ou.user_id
order by tr.tree_sortkey



-- move_to_deleted
update im_forum_topic_user_map
set folder_id = 1
where
	user_id=:user_id
	$topic_in_clause;

-- move_to_inbox
update im_forum_topic_user_map
set folder_id = 0
where   user_id=:user_id
	$topic_in_clause;

-- mark_as_read
update im_forum_topic_user_map
set read_p = 't'
where   user_id=:user_id
	$topic_in_clause;

-- mark_as_unread
update im_forum_topic_user_map
set read_p = 'f'
where   user_id=:user_id
	$topic_in_clause;

--  task_accept
update im_forum_topics
set topic_status_id = [im_topic_status_id_accepted]
where   (owner_id = :user_id OR asignee_id = :user_id)
	and topic_type_id in ([im_topic_type_id_task], [im_topic_type_id_incident])
	$topic_in_clause;

-- task_reject
update im_forum_topics
set topic_status_id = [im_topic_status_id_rejected]
where   (owner_id = :user_id OR asignee_id = :user_id)
	and topic_type_id in ([im_topic_type_id_task], [im_topic_type_id_incident])
	$topic_in_clause;

-- task_close
set topic_status_id = [im_topic_status_id_closed]
where   (owner_id = :user_id OR asignee_id = :user_id)
	and topic_type_id in ([im_topic_type_id_task], [im_topic_type_id_incident])
	$topic_in_clause;



-- Forum Permissions - who should see what
-- 
select	t.*
from	im_forum_items t
where	1 = im_forum_permission(
		:user_id,
		t.owner_id,
		t.asignee_id,
		t.object_id,
		t.scope,
		member_objects.p,
		admin_objects.p,
		:user_is_employee_p,
		:user_is_customer_p
	)
;


-- Who has the right to see tis Forum Topic.
-- The query is complex because of exceptions, such
-- as a freelancer who might have been assigned to a
-- Topic to resolve it, breaking all "conventional"
-- security.
--
select
	p.party_id as user_id
from
	acs_rels r,
	-- get the members and admins of object_id
	(       select  1 as member_p,
			(CASE WHEN m.object_role_id = 1301
			       or m.object_role_id = 1302
			       or m.object_role_id = 1303
			THEN 1
			ELSE 0 END
			) as admin_p,
			r.object_id_two as user_id
		from    acs_rels r,
			im_biz_object_members m
		where   r.object_id_one = :object_id
			and r.rel_id = m.rel_id
	) o_mem,
	parties p
      LEFT JOIN
	(select m.member_id as user_id,
		1 as p
	 from group_distinct_member_map m
	 where  m.group_id = [im_customer_group_id]
	) customers ON p.party_id=customers.user_id
      LEFT JOIN
	(select m.member_id as user_id,
		1 as p
	 from group_distinct_member_map m
	 where  m.group_id = [im_employee_group_id]
	) employees ON p.party_id=employees.user_id
where
	r.object_id_one = :object_id
	and r.object_id_two = p.party_id
	and o_mem.user_id = p.party_id
	and 1 = im_forum_permission(
		p.party_id,
		:user_id,
		:asignee_id,
		:object_id,
		:scope,
		o_mem.member_p,
		o_mem.admin_p,
		employees.p,
		customers.p
	)
;

-- Create a new forum topic
-- This only creates the basic information necessary.
-- You need an update to complete the information.
-- Forum Topics are NOT acs_objects right now.
insert into im_forum_topics (
	topic_id, object_id, topic_type_id,
	topic_status_id, owner_id, subject
) values (
	:topic_id, :object_id, :topic_type_id,
	:topic_status_id, :owner_id, :subject
);


update im_forum_topics set
	object_id=:object_id,
	parent_id=:parent_id,
	topic_type_id=:topic_type_id,
	topic_status_id=:topic_status_id,
	posting_date=:today,
	owner_id=:owner_id,
	scope=:scope,
	subject=:subject,
	message=:message,
	priority=:priority,
	asignee_id=:asignee_id,
	due_date=:due
where topic_id=:topic_id




-----------------------------------------------------------
-- Topics
--

create sequence im_forum_topics_seq start 1;
create table im_forum_topics (
	-- administrative information
	topic_id	integer
			constraint im_forum_topics_pk primary key,
	topic_name	varchar(200),
	topic_path	varchar(200),
	object_id	integer not null 
			constraint im_forum_topics_object_fk
			references acs_objects,
	-- Hierarchy of messages
	parent_id	  integer
			  constraint im_forum_topics_parent_fk
			  references im_forum_topics,
	tree_sortkey      varbit,
	max_child_sortkey varbit,

	topic_type_id	integer not null
			constraint im_forum_topics_type_fk
			references im_categories,
	topic_status_id	integer
			constraint im_forum_topics_status_fk
			references im_categories,
	posting_date	date default current_timestamp,
	owner_id	integer not null
			constraint im_forum_topics_owner_fk
			references users,
	scope		varchar(20) default 'group'
			constraint im_forum_topics_scope_ck
			check (scope in ('pm', 'group','public','client','staff','not_client')),
	-- message content
	subject		text not null,
	message		text,
	-- task and incident specific fields
	priority	numeric(1,0) default 5,
	due_date	timestamptz default current_timestamp,
	asignee_id	integer
			constraint im_forum_topics_asignee_fk
			references users
);


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
