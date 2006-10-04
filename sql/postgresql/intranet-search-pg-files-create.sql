-- /packages/intranet-search-pg-files/sql/postgresql/intranet-search-pg-files-create.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- im_fs_files

create or replace function inline_0 ()
returns integer as '
declare
        v_exists_p      varchar;
begin
        select  count(*)
        into    v_exists_p
        from    acs_object_types
        where   object_type = ''im_fs_file'';

        if 0 = v_exists_p then

	    perform acs_object_type__create_type (
		''im_fs_file'',		-- object_type
		''Filestorage File'',	-- pretty_name
		''Filestorage Files'',	-- pretty_plural
		''acs_object'',		-- supertype
		''im_fs_files'',	-- table_name
		''file_id'',		-- id_column
		''intranet-filestorage'', -- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		''im_fs_files.name''	-- name_method
	    );
	end if;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



insert into im_search_object_types values (6,'im_fs_file');


-----------------------------------------------------------
-- Business Object View URLs

-- remove potential old entries
delete from im_biz_object_urls
where object_type = 'im_fs_file';

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_fs_file','view','/intranet-filestorage/index?file_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_fs_file','edit','/intranet-filestorage/index??file_id=');




create or replace function im_fs_files_tsearch ()
returns trigger as '
declare
	v_string	varchar;
	v_string2	varchar;
	oid		integer;
begin
	select
		coalesce(f.filename, '''') || '' '',
		ff.object_id
	into
		v_string, oid
	from
		im_fs_files f,
		im_fs_folders ff
	where
		f.folder_id = ff.folder_id
		and file_id = new.file_id;

	perform im_search_update(new.file_id, ''im_fs_file'', oid, v_string);

	return new;
end;' language 'plpgsql';


CREATE TRIGGER im_fs_files_tsearch_tr
AFTER INSERT or UPDATE
ON im_fs_files
FOR EACH ROW
EXECUTE PROCEDURE im_fs_files_tsearch();


