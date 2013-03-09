SELECT acs_log__debug('/packages/intranet-csv-import/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.2.sql','');


update im_menus
set url = '/intranet-csv-import/index?object_type=im_project'
where label = 'projects_admin_csv_import';

