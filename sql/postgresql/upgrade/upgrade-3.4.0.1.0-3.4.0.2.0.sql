-- upgrade-3.4.0.1.0-3.4.0.2.0.sql



select acs_privilege__create_privilege('edit_project_status','Edit Project Status','Edit Project Status');
select acs_privilege__add_child('admin', 'edit_project_status');

select im_priv_create('edit_project_status','Accounting');
select im_priv_create('edit_project_status','P/O Admins');
select im_priv_create('edit_project_status','Senior Managers');


