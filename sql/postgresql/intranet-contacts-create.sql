-- contacts-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2004-07-28
-- @cvs-id $Id$
--
--


-- Since all contacts are parties we already have good "group" mechanisms built into the core.
-- However, we do not want people to view all groups at once, for example the calendar instance.
-- Administrator can selectively give certain calendar instances access to certain groups
-- 
-- By default each new contacts instance will be given access to its subsite's group. 
-- For example: All users on a default openacs install are memembers of the "Main Site Members"
-- group. If a calendar instance were mounted under that subsite, all "Main Site Members"
-- would be accessible to that calendar instance.
--
-- Just as is the case with the calendar package all "users" of contacts (i.e. users that
-- have write access to at least one contacts instance will be assigned a private calendar)
--
-- Which calendars can be viewed by which calendar instance is handled via parameters - unlike
-- many packages. This allows for more flexable instance and sharing management - where
-- one instances shared calendar can also be accesible to another instance.

create table contact_groups (
	group_id		integer
				constraint contact_groups_id_fk 
				references groups(group_id)
				constraint contact_groups_id_nn not null,
	default_p		boolean default 'f'
				constraint contact_groups_default_p_nn not null,
	user_change_p	boolean default 'f'
				constraint contact_groups_user_change_p_nn not null,
	notifications_p	boolean default 'f'
				constraint contact_groups_notifications_p_nn not null,
	package_id		integer
				constraint contact_groups_package_id_fk 
				references apm_packages(package_id)
				constraint contact_groups_package_id_nn not null,
	unique(group_id,package_id)
);

comment on table contact_groups is '
This mapping table notes what groups (this is acs groups) are can be used in a specific contacts package and therefore have special attributes.
';

comment on column contact_groups.group_id is '
ACS Group ID which is linked to the contacts instance
';

comment on column contact_groups.package_id is '
Package ID of the contacts instance the group is linked to
';

comment on column contact_groups.default_p is '
Is this group a default group? This means that all contacts entered through this contacts instance are automatically added to this group
';

comment on column contact_groups.user_change_p is '
Can a user change this his own attributes in this group?
';

create table contact_groups_allowed_rels (
	group_id		integer
				constraint contact_groups_id_fk 
				references groups(group_id)
				constraint contact_groups_id_nn not null,
	rel_type		varchar(100)
				constraint contact_groups_allowed_rels_type_fk 
				references acs_rel_types(rel_type),
	package_id		integer
				constraint contact_groups_package_id_fk 
				references apm_packages(package_id)
				constraint contact_groups_package_id_nn not null,
	unique(group_id,package_id)
);


create table contact_signatures (
	signature_id		integer
				constraint contact_signatures_id_pk primary key,
	title			varchar(255)
				constraint contact_signatures_title_nn not null,
	signature		varchar(1000)
				constraint contact_signatures_signature_nn not null,
	default_p		boolean default 'f'
				constraint contact_signatures_default_p_nn not null,
	party_id		integer
				constraint contact_signatures_party_id_fk 
				references parties(party_id)
				constraint contact_signatures_party_id_nn not null,
	unique(party_id,title,signature)
);


comment on table contact_signatures is '
Contacts supports signatures for each party_id. This is where they are stored. The signature is attached to each mailing the party sends out, if selected. A party can have multiple signatures, in this situation a select box is shown. The default signature is selected by default (if there is any).
';

comment on column contact_signatures.signature_id is '
Primary key for identifying a signature
';

comment on column contact_signatures.title is '
Title of the signature for nice display of the it.
';

comment on column contact_signatures.signature is '
The signature itself. This will be attached to the mailing (if selected).
';

comment on column contact_signatures.default_p is '
Is the signature the default signature.
';

comment on column contact_signatures.party_id is '
Party_id of the user who is creating the mailing. This is not the signature for the recipient, but the sender of the mailing.
';

-- this view greatly simplifies getting available roles for various contact types
create view contact_rel_types as 
(	select	rel_type,
		object_type_one as primary_object_type,
		role_one as primary_role,
		object_type_two as secondary_object_type,
		role_two as secondary_role
	from
		acs_rel_types
	where
		rel_type in ( 
			select object_type 
			from acs_object_types 
			where supertype in ('contact_rel','im_biz_object_member')
		)
)
UNION
(	select	rel_type,
		object_type_two as primary_object_type,
		role_two as primary_role,
		object_type_one as secondary_object_type,
		role_one as secondary_role
	from
		acs_rel_types
	where
		rel_type in ( 
			select object_type 
			from acs_object_types 
			where supertype in ('contact_rel', 'im_biz_object_member')
		)
)
;

create table contact_deleted_history (
	party_id		integer
				constraint contact_deleted_history_party_id_fk 
				references parties(party_id) on delete cascade
				constraint contact_deleted_history_party_id_nn not null,
	object_id		integer
				constraint contact_deleted_history_object_id_fk 
				references acs_objects(object_id) on delete cascade
				constraint contact_deleted_history_object_id_nn not null,
	deleted_by		integer
				constraint contact_deleted_history_deleted_by_fk 
				references users(user_id) on delete cascade
				constraint contact_deleted_history_deleted_by_nn not null,
	deleted_date		timestamptz default now()
				constraint contact_deleted_history_deleted_date not null,
	unique(party_id,object_id)
);

-- Table that allows you to control the privacy of
-- a contact. This prevents you from contacting a
-- contact in a way the that is not liked if enabled
-- via a parameter

create table contact_privacy (
	party_id	integer primary key
			constraint contact_privacy_party_id_fk 
			references parties(party_id) on delete cascade,
	email_p		boolean not null default 't',
	mail_p		boolean not null default 't',
	phone_p		boolean not null default 't',
	gone_p		boolean not null default 'f' -- if a person is deceased or an organization is closed down
			constraint contact_privacy_gone_p_ck check (
				( gone_p is TRUE AND ( mail_p is FALSE and email_p is FALSE and phone_p is FALSE ))
				or ( gone_p is FALSE )
			)
);

-- pre populate the contact_privacy table with
-- all of the parties already in the system
insert into contact_privacy ( 
	party_id, email_p, mail_p, phone_p, gone_p 
)
select	party_id, 
	't'::boolean, 
	't'::boolean, 
	't'::boolean, 
	'f'::boolean
from
	parties
where
	party_id not in ( select party_id from contact_privacy )
order by 
	party_id;


create or replace function im_country_from_code(varchar)
returns varchar as '
DECLARE
	v_varchar	alias for $1;
	v_result	varchar;
BEGIN
	select country_name into v_result from country_codes 
	where iso = v_varchar;
	
	return v_result;
END;' language 'plpgsql';


-- Make sure im_biz_object_members have a default which is full member
alter table im_biz_object_members alter column object_role_id set default 1300;
alter table im_biz_object_members alter column object_role_id drop not null;
delete from users_contact where user_id not in (select person_id from persons);
-- insert into users_contact (user_id) select person_id from persons where person_id not in (select user_id from users_contact);

\i contacts-package-create.sql
\i contacts-search-create.sql
\i contacts-messages-create.sql
\i contacts-list-create.sql
\i groups-notifications-init.sql
