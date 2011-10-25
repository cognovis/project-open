-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');


create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from pg_constraint
	where  lower(conname) = 'im_audits_action_ck';
	IF v_count = 0 THEN return 0; END IF;

	alter table im_audits 
	drop constraint im_audits_action_ck;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();


-- --------------------------------------------------
-- Setup a new constraint
-- --------------------------------------------------

update im_audits set audit_action = 'before_update' where audit_action = 'update';
update im_audits set audit_action = 'before_update' where audit_action = 'pre_update';
update im_audits set audit_action = 'before_nuke' where audit_action = 'nuke';
update im_audits set audit_action = 'before_nuke' where audit_action = 'before_delete';
update im_audits set audit_action = 'after_create' where audit_action = 'create';

alter table im_audits
add constraint im_audits_action_ck
check (audit_action in ('after_create','before_update','after_update','before_nuke', 'baseline'));


