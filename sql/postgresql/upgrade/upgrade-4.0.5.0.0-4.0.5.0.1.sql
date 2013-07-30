-- upgrade-4.0.5.0.0-4.0.5.0.1.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.5.0.0-4.0.5.0.1.sql','');


update im_menus
set url = '/intranet/admin/consistency-check'
where label = 'admin_consistency_check';

