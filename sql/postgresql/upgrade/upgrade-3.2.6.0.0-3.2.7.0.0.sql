-- upgrade-3.2.6.0.0-3.2.7.0.0.sql


-- ------------------------------------------------------
-- Privileges
-- ------------------------------------------------------

select acs_privilege__create_privilege('wf_reassign_tasks','Reassign tasks to other users','');
select acs_privilege__add_child('admin', 'wf_reassign_tasks');


select im_priv_create('wf_reassign_tasks','Accounting');
select im_priv_create('wf_reassign_tasks','P/O Admins');
select im_priv_create('wf_reassign_tasks','Senior Managers');


