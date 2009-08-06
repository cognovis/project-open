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

create table im_audit (
	audit_id		integer
				constraint im_audit_pk
				primary key,
	audit_user_id		integer
				constraint im_audit_user_fk
				references users
				constraint im_audit_user_nn
				not null,
	audit_date		timestamptz
				constraint im_audit_date_nn
				not null,
	audit_ip		varchar(50)
				constraint im_audit_ip_nn
				not null,
	audit_last_id		integer
				constraint im_audit_last_fk
				references im_audit,
	audit_ref_object_id	integer
				constraint im_audit_reference_fk
				references acs_objects,
	audit_value		text
				constraint im_audit_value_nn
				not null,
	audit_diff		text
				constraint im_audit_diff_nn
				not null,
	audit_note		text,
	audit_hash		text
);

-- Add a link for every object to the ID of the last audit entry
alter table acs_objects add column last_audit_id integer references im_audit;


comment on table im_audit is '
 Generic audit table. A new row is created everytime that the value
 of the object is updated.
';


comment on column im_audit.audit_user_id is '
 Who has performed the change?
';

comment on column im_audit.audit_date is '
 When was the change performed?
';

comment on column im_audit.audit_ip is '
 IP address of the connection initiating the change.
';

comment on column im_audit.audit_last_id is '
 Pointer to the last last audit of the object or NULL
 before the first update. Used to quickly find the old
 values for calculating a diff.
';

comment on column im_audit.audit_ref_object_id is '
 Optional reference to an object who initiated the change.
';

comment on column im_audit.audit_value is '
 List of the object fields after the update.
';

comment on column im_audit.audit_diff is '
 Difference between the audit_value of the audit_value
 of the audit_last_id and the new audit_value.
';

comment on column im_audit.audit_note is '
 Additional note by the user. Optional.
';

comment on column im_audit.audit_hash is '
 Crypto hash to ensure the integrity of the audit log.
 The hash value includes the hash of the audit_last_id,
 so that any modification in the audit log can be 
 identified.
 In the case of a complete recalculation of all hashs,
 the PostgreSQL OIDs will witness these changes.
';



