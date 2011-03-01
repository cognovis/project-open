-- upgrade-3.2.3.0.0-3.2.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-filestorage/sql/postgresql/upgrade/upgrade-3.2.3.0.0-3.2.4.0.0.sql','');


-- -----------------------------------------------------
-- Update the date field of im_fs_actions from date to timestamp
--
-- This upgrade doesn't work directly in PG 7.4.x,
-- so we take the long way here.

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
	v_type		varchar;
begin
	select lower(trim(data_type)) into v_type
	from user_tab_columns where table_name = ''IM_FS_ACTIONS'' and column_name = ''ACTION_DATE'';
	if v_type = ''timestamptz'' then return 0; end if;

	RAISE NOTICE ''upgrade-3.2.3.0.0-3.2.4.0.0.sql: inline_0: v_type=%'', v_type;

	-- Delete everything, because we dont get the unique key otherwise.
	delete from im_fs_actions;
		
	alter table im_fs_actions drop column action_date;
		
	alter table im_fs_actions add action_date timestamptz;
		
	update im_fs_actions set action_date = now();
		
	alter table im_fs_actions alter column action_date set not null;
		
	alter table im_fs_actions add constraint im_fs_actions_pkey
		primary key (user_id, action_date, file_name);
		
	alter table im_fs_files add fti_content text;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

