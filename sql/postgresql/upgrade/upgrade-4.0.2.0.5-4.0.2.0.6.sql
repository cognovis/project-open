-- upgrade-4.0.2.0.5-4.0.2.0.6.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.2.0.5-4.0.2.0.6.sql','');



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from pg_constraint
	where  lower(conname) = 'im_audits_object_status_fk';
	IF v_count = 0 THEN return 0; END IF;

	alter table im_audits 
	drop constraint im_audits_object_status_fk;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from pg_constraint
	where  lower(conname) = 'im_audits_status_fk';
	IF v_count = 0 THEN return 0; END IF;

	alter table im_audits 
	drop constraint im_audits_status_fk;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

