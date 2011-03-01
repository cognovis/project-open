-- upgrade-3.4.0.1.0-3.4.0.2.0.sql

SELECT acs_log__debug('/packages/intranet-search-pg-files/sql/postgresql/upgrade/upgrade-3.4.0.1.0-3.4.0.2.0.sql','');

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count 
	from	pg_constraint
	where	conname = ''im_fs_files_owner_fk'';
	if v_count = 0 then return 0; end if;

	alter table im_fs_files drop constraint im_fs_files_owner_fk;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count 
	from im_search_object_types
	where object_type = ''im_fs_file'';
	if v_count > 0 then return 0; end if;

	insert into im_search_object_types values (6,''im_fs_file'',0.1);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
