-- upgrade-4.0.3.0.4-4.0.3.0.5.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');

create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count
	from	pg_class
	where	lower(relname) = 'im_audits_audit_date_idx';

	IF v_count > 0 THEN return 1; END IF;

	create index im_audits_audit_date_idx on im_audits(audit_date);

        return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

