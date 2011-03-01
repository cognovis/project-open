-- upgrade-3.2.8.0.0-3.2.9.0.0.sql

SELECT acs_log__debug('/packages/intranet-filestorage/sql/postgresql/upgrade/upgrade-3.2.8.0.0-3.2.9.0.0.sql','');


-- Add new fields to files for Files FTS
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''folder_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add folder_id integer;
	alter table im_fs_files add constraint im_fs_files_folder_fk
		FOREIGN KEY (folder_id) references im_fs_folders;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''owner_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add owner_id integer;
	alter table im_fs_files add constraint im_fs_files_owner_fk
		FOREIGN KEY (owner_id) references persons;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''filename'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add filename text not null;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''language_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add language_id integer;
	alter table im_fs_files add constraint im_fs_files_lang_fk
		FOREIGN KEY (language_id) references im_categories;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''binary_hash'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add binary_hash character(40);

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''text_hash'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add text_hash character(40);

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''downloads_cache'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add downloads_cache integer;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''exists_p'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add exists_p char(1);
	alter table im_fs_files alter column exists_p set default ''1'';

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_fs_files'' and lower(column_name) = ''ft_indexed_p'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_fs_files add ft_indexed_p char(1);
	alter table im_fs_files alter column ft_indexed_p set default ''0'';
	alter table im_fs_files add constraint im_fs_files_ft_indexed_ck
			check (ft_indexed_p in (''0'',''1''));

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



