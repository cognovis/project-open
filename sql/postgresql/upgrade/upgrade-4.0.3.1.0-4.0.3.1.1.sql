-- upgrade-4.0.3.1.0-4.0.3.1.1.sql

SELECT acs_log__debug('/packages/intranet-cost-center/sql/postgresql/upgrade/upgrade-4.0.3.1.0-4.0.3.1.1.sql','');


select acs_privilege__create_privilege('view_projects_dept','View Department Projects','View Department Projects');
select acs_privilege__add_child('admin', 'view_projects_dept');
select acs_privilege__create_privilege('edit_projects_dept','Edit Department Projects','Edit Department Projects');
select acs_privilege__add_child('admin', 'edit_projects_dept');



