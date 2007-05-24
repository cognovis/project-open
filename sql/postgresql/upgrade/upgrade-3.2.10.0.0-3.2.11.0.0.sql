-- upgrade-3.2.10.0.0-3.2.11.0.0.sql


-- New Privilege to allow accounting guys to change hours
select acs_privilege__create_privilege('edit_hours_all','Edit Hours All','Edit Hours All');
select acs_privilege__add_child('admin', 'edit_hours_all');

select im_priv_create('edit_hours_all', 'Accounting');
select im_priv_create('edit_hours_all', 'P/O Admins');
select im_priv_create('edit_hours_all', 'Senior Managers');

