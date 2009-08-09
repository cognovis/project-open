-- /packages/intranet-audit/sql/postgresql/intranet-audit-create.sql
--
-- Copyright (c) 2007 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-- ----------------------------------------------------------------
-- intranet-audit
--
-- Keeps track of 
-- ----------------------------------------------------------------

create sequence im_audit_seq;

create table im_audits (
	audit_id		integer
				constraint im_audits_pk
				primary key,
	audit_object_id		integer
				constraint im_audits_object_fk
				references acs_objects
				constraint im_audits_object_nn
				not null,
	audit_user_id		integer
				constraint im_audits_user_fk
				references users
				constraint im_audits_user_nn
				not null,
	audit_date		timestamptz
				constraint im_audits_date_nn
				not null,
	audit_ip		varchar(50)
				constraint im_audits_ip_nn
				not null,
	audit_last_id		integer
				constraint im_audits_last_fk
				references im_audits,
	audit_ref_object_id	integer
				constraint im_audits_reference_fk
				references acs_objects,
	audit_value		text
				constraint im_audits_value_nn
				not null,
	audit_diff		text
				constraint im_audits_diff_nn
				not null,
	audit_note		text,
	audit_hash		text
);

-- Add a link for every object to the ID of the last audit entry
alter table acs_objects add column last_audit_id integer;

-- Add a foreign key constraint on last_audit_id:
alter table acs_objects 
add constraint acs_objects_last_audit_id_fkey 
foreign key (last_audit_id) references im_audits;

-- Create an index for fast access of the changes of an object
create index im_audits_audit_object_id_idx on im_audits(audit_object_id);

comment on table im_audits is '
 Generic audit table. A new row is created everytime that the value
 of the object is updated.
';


comment on column im_audits.audit_user_id is '
 Who has performed the change?
';

comment on column im_audits.audit_date is '
 When was the change performed?
';

comment on column im_audits.audit_ip is '
 IP address of the connection initiating the change.
';

comment on column im_audits.audit_last_id is '
 Pointer to the last last audit of the object or NULL
 before the first update. Used to quickly find the old
 values for calculating a diff.
';

comment on column im_audits.audit_ref_object_id is '
 Optional reference to an object who initiated the change.
';

comment on column im_audits.audit_value is '
 List of the object fields after the update.
';

comment on column im_audits.audit_diff is '
 Difference between the audit_value of the audit_value
 of the audit_last_id and the new audit_value.
';

comment on column im_audits.audit_note is '
 Additional note by the user. Optional.
';

comment on column im_audits.audit_hash is '
 Crypto hash to ensure the integrity of the audit log.
 The hash value includes the hash of the audit_last_id,
 so that any modification in the audit log can be 
 identified.
 In the case of a complete recalculation of all hashs,
 the PostgreSQL OIDs will witness these changes.
';





-----------------------------------------------------------
-- Component Plugins
--

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Conf Items',	-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-confdb/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $org_conf_item_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Conf Items'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Projects',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $project_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Projects'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

