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




-------------------------------------------------------------------
-- Compatibility
-------------------------------------------------------------------

-- AMS Compatibility view
create or replace view ams_lists as
select
	c.category_id as list_id,
	'contacts'::varchar as package_key,
	aot.object_type,
	c.category as list_name,
	c.category as pretty_name,
	''::varchar as description,
	'text/plain'::varchar as description_mime_type
from
	acs_object_types aot,
	im_categories c
where
	aot.type_category_type is not null
	and aot.type_category_type = c.category_type;

-- AMS Compatibility view
create or replace view ams_list_attribute_map as
select
	tam.object_type_id as list_id,
	da.acs_attribute_id as attribute_id,
	0::integer as sort_order,
	false::boolean as required_p,
	''::varchar as section_heading,
	''::varchar as html_options
from
	im_dynfield_type_attribute_map tam,
	im_dynfield_attributes da
where
	tam.attribute_id = da.attribute_id;




-------------------------------------------------------------------
-- Menus
-------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
BEGIN
	select group_id into v_employees from groups where group_name = ''Employees'';
	select menu_id into v_main_menu	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-contacts'',		-- package_name
		''contacts'',			-- label
		''CRM'',			-- name
		''/intranet-contacts/'',	-- url
		20,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-------------------------------------------------------------------
-- DynField Widgets
-------------------------------------------------------------------


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'employee_status',			-- widget_name
	'#intranet-hr.Employee_Status#',	-- pretty_name
	'#intranet-hr.Employee_Status#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Employee Pipeline State"}}}'			-- Parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'salutation',			-- widget_name
	'#intranet-contacts.Salutation#',	-- pretty_name
	'#intranet-contacts.Salutation#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Salutation"}}}'			-- Parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'supervisors',			-- widget_name
	'#intranet-hr.Supervisor#',	-- pretty_name
	'#intranet-hr.Supervisor#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'generic_sql',	-- widget
	'integer',		-- sql_datatype
	'{{custom {sql "select 
                0 as user_id,
                ''No Supervisor (CEO)'' as user_name
        from dual
    UNION
        select 
                u.user_id,
                im_name_from_user_id(u.user_id) as user_name
        from 
                users u,
                group_distinct_member_map m
        where 
                m.member_id = u.user_id
                and m.group_id = (select group_id from groups where group_name = ''Employee'')"}}}'			-- Parameters
);





-------------------------------------------------------------------
-- Create DynFields
-------------------------------------------------------------------



-- im_dynfield_attribute_new (o_type, column, pretty_name, widget_name, data_type, required_p, pos, also_hard_coded_p)

SELECT im_dynfield_attribute_new ('person', 'first_names', '#acs-subsite.first_names#', 'textbox_medium', 'string', 't', 0, 't');
SELECT im_dynfield_attribute_new ('person', 'last_name', '#acs-subsite.last_name#', 'textbox_medium', 'string', 't', 1, 't');
SELECT im_dynfield_attribute_new ('party', 'email', '#acs-subsite.Email#', 'textbox_medium', 'string', 't', 2, 't');
SELECT im_dynfield_attribute_new ('party', 'url', '#acs-subsite.URL#', 'textbox_medium', 'string', 't', 3, 't');



-- Salutation
SELECT im_dynfield_attribute_new ('person', 'salutation_id', '#intranet-contacts.Salutation#', 'salutation', 'integer', 'f', 4, 'f');

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns 
	where	lower(table_name) = ''persons'' and lower(column_name) = ''salutation_id'';
	IF 0 != v_count THEN return 0; END IF;

	alter table persons 
	add column salutation_id integer
	constraint persons_salutation_fk
	references im_categories;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-------------------------------------------------------------------
-- Create relationships between BizObject and Persons
-------------------------------------------------------------------


-------------------------------------------------------------------
-- "Employee of a Company" relationship
-- It doesn't matter if it's the "internal" company, a customer
-- company or a provider company.
-- Instances of this relationship are created whenever ...??? ToDo
-- Usually included DynFields:
--	- Position
--
-- ]po[ HR information is actually attached to a specific subtype
-- of this rel "internal employee"
-- In ]po[ we will create a "im_company_employee_rel" IF:
--	- The user is an "Employee" and its the "internal" company.
--	- The user is a "Customer" and the company is a "customer".
--	- The user is a "Freelancer" and the company is a "provider".

SELECT acs_rel_type__create_role('employee', '#acs-translations.role_employee#', '#acs-translations.role_employee_plural#');
SELECT acs_rel_type__create_role('employer', '#acs-translations.role_employer#', '#acs-translations.role_employer_plural#');

SELECT acs_object_type__create_type(
	'im_company_employee_rel',
	'#intranet-contacts.company_employee_rel#',
	'#intranet-contacts.company_employee_rels#',
	'im_biz_object_member',
	'im_company_employee_rels',
	'company_employee_rel_id',
	'intranet-contacts.comp_emp', 
	'f',
	null,
	NULL
);

create table im_company_employee_rels (
	company_employee_rel_id	integer
				REFERENCES acs_objects(object_id)
				ON DELETE CASCADE
	CONSTRAINT im_company_employee_rel_id_pk PRIMARY KEY
);


insert into acs_rel_types (
	rel_type, object_type_one, role_one,
	min_n_rels_one, max_n_rels_one,
	object_type_two, role_two,min_n_rels_two, max_n_rels_two
) values (
	'im_company_employee_rel', 'im_company', 'employer', 
	'1', NULL,
	'person', 'employee', '1', NULL
);


-- Insert our own employees into that relationship
insert into im_company_employee_rels
select 
	r.rel_id 
from
	acs_rels r,
	im_biz_object_members bom
where
	r.rel_id = bom.rel_id and
	r.object_id_two in (
		select member_id 
		from group_approved_member_map 
		where group_id = (select group_id from groups where group_name = 'Employees')
	) and 
	r.object_id_one in (select company_id from im_companies where company_path = 'internal') and
	r.rel_id not in (select company_employee_rel_id from im_company_employee_rels)
;

-- Insert any employee of any other commpany into that relationship
insert into im_company_employee_rels
select 
	r.rel_id 
from
	acs_rels r,
	im_biz_object_members bom
where
	r.rel_id = bom.rel_id and
	r.object_id_two in (
		select member_id 
		from group_approved_member_map 
		where group_id not in (select group_id from groups where group_name = 'Employees')
	) and 
	r.object_id_one in (select company_id from im_companies where company_path != 'internal') and
	r.rel_id not in (select company_employee_rel_id from im_company_employee_rels)
;


-- Update the type of the relationship
update acs_rels set rel_type = 'im_company_employee_rel' where rel_id in (select company_employee_rel_id from im_company_employee_rels);




-------------------------------------------------------------------
-- "Key Account Manager" relationship
--
-- A "key account" is a member of group "Employees" who is entitled
-- to manage a customer or provider company.
--
-- Typical extension field for this relationship:
--	- Contract Value (to be signed by this key account)
--
-- Instances of this rel are created by ]po[ if and only if we
-- create a im_biz_object_membership rel with type "Key Account".

SELECT acs_rel_type__create_role('key_account', '#acs-translations.role_key_account#', '#acs-translations.role_key_account_plural#');
SELECT acs_rel_type__create_role('company', '#acs-translations.role_company#', '#acs-translations.role_company_plural#');

SELECT acs_object_type__create_type(
	'im_key_account_rel',
	'#intranet-contacts.key_account_rel#',
	'#intranet-contacts.key_account_rels#',
	'im_biz_object_member',
	'im_key_account_rels',
	'key_account_rel_id',
	'intranet-contacts.key_account', 
	'f',
	null,
	NULL
);

create table im_key_account_rels (
	key_account_rel_id	integer
				REFERENCES acs_objects(object_id)
				ON DELETE CASCADE
	CONSTRAINT im_key_account_rel_id_pk PRIMARY KEY
);


insert into acs_rel_types (
	rel_type, object_type_one, role_one,
	min_n_rels_one, max_n_rels_one,
	object_type_two, role_two,min_n_rels_two, max_n_rels_two
) values (
	'im_key_account_rel', 'im_company', 'company',
	'1', NULL,
	'person', 'key_account', '1', NULL
);


-- Insert our employees that manage customers or providers
insert into im_key_account_rels
select
	r.rel_id 
from
	acs_rels r,
	im_biz_object_members bom
where
	r.rel_id = bom.rel_id and
	r.object_id_two in (
		select member_id 
		from group_approved_member_map 
		where group_id in (select group_id from groups where group_name = 'Employees')
	) and 
	r.object_id_one in (select company_id from im_companies where company_path != 'internal') and
	r.rel_id not in (select key_account_rel_id from im_key_account_rels)
;


update acs_rels set rel_type = 'im_key_account_rel' where rel_id in (select key_account_rel_id from im_key_account_rels);

