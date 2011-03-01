-- /packages/intranet-search-pg-files/sql/postgresql/intranet-search-pg-files-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



delete from im_biz_object_urls where object_type = 'im_fs_file';

drop function im_fs_files_tsearch ();
drop TRIGGER im_fs_files_tsearch_tr ON im_fs_files;
drop function im_fs_files_tsearch_del ();
drop TRIGGER im_fs_files_tsearch_del_tr on im_fs_files;
drop table im_search_pg_file_biz_objects;
