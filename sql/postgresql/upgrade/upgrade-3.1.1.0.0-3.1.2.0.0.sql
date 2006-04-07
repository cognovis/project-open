-- -----------------------------------------------------
-- Add permissions to handle the default permissions on
-- empty filestorages

select acs_privilege__create_privilege('fs_root_view','Default view permission for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_view');

select acs_privilege__create_privilege('fs_root_read','Default read permission for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_read');

select acs_privilege__create_privilege('fs_root_write','Default write permission for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_write');

select acs_privilege__create_privilege('fs_root_admin','Default admin permission for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_admin');


-- View Permissions
--
select im_priv_create('fs_root_view',        'Employees');
select im_priv_create('fs_root_view',        'Accounting');
select im_priv_create('fs_root_view',        'P/O Admins');
select im_priv_create('fs_root_view',        'Project Managers');
select im_priv_create('fs_root_view',        'Senior Managers');


-- Read Permissions
--
select im_priv_create('fs_root_read',        'Employees');
select im_priv_create('fs_root_read',        'Accounting');
select im_priv_create('fs_root_read',        'P/O Admins');
select im_priv_create('fs_root_read',        'Project Managers');
select im_priv_create('fs_root_read',        'Senior Managers');


-- Write Permissions
--
select im_priv_create('fs_root_write',        'Employees');
select im_priv_create('fs_root_write',        'Accounting');
select im_priv_create('fs_root_write',        'P/O Admins');
select im_priv_create('fs_root_write',        'Project Managers');
select im_priv_create('fs_root_write',        'Senior Managers');


-- Admin Permissions
--
select im_priv_create('fs_root_admin',        'Employees');
select im_priv_create('fs_root_admin',        'Accounting');
select im_priv_create('fs_root_admin',        'P/O Admins');
select im_priv_create('fs_root_admin',        'Project Managers');
select im_priv_create('fs_root_admin',        'Senior Managers');

