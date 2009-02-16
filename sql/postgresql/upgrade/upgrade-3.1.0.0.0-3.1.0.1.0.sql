-- upgrade-3.1.0.0.0-3.1.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.1.0.0.0-3.1.0.1.0.sql','');


\i ../../../../intranet-core/sql/postgresql/upgrade/upgrade-3.0.0.0.first.sql


-- -----------------------------------------------------
-- Add privileges for freelance_skills and freelance_skills_hours
--
select acs_privilege__create_privilege('add_freelance_skills','Add Freelance Skills','Add Freelance Skills');
select acs_privilege__add_child('admin', 'add_freelance_skills');

select acs_privilege__create_privilege('view_freelance_skills','View Freelance Skills','View Freelance Skills');
select acs_privilege__add_child('admin', 'view_freelance_skills');

select im_priv_create('view_freelance_skills','Accounting');
select im_priv_create('view_freelance_skills','P/O Admins');
select im_priv_create('view_freelance_skills','Project Managers');
select im_priv_create('view_freelance_skills','Senior Managers');
select im_priv_create('view_freelance_skills','Freelance Managers');
select im_priv_create('view_freelance_skills','Employees');

select im_priv_create('add_freelance_skills','Accounting');
select im_priv_create('add_freelance_skills','P/O Admins');
select im_priv_create('add_freelance_skills','Senior Managers');
select im_priv_create('add_freelance_skills','Project Managers');
select im_priv_create('add_freelance_skills','Freelance Managers');

select im_priv_create('view_freelance_skills','Freelancers');
select im_priv_create('add_freelance_skills','Freelancers');



select acs_privilege__create_privilege('add_freelance_skillconfs','Add Freelance Skillconfs','Add Freelance Skillconfs');
select acs_privilege__add_child('admin', 'add_freelance_skillconfs');

select acs_privilege__create_privilege('view_freelance_skillconfs','View Freelance Skillconfs','View Freelance Skillconfs');
select acs_privilege__add_child('admin', 'view_freelance_skillconfs');

select im_priv_create('view_freelance_skillconfs','Accounting');
select im_priv_create('view_freelance_skillconfs','P/O Admins');
select im_priv_create('view_freelance_skillconfs','Project Managers');
select im_priv_create('view_freelance_skillconfs','Senior Managers');
select im_priv_create('view_freelance_skillconfs','Freelance Managers');
select im_priv_create('view_freelance_skillconfs','Employees');

select im_priv_create('add_freelance_skillconfs','Accounting');
select im_priv_create('add_freelance_skillconfs','P/O Admins');
select im_priv_create('add_freelance_skillconfs','Senior Managers');
select im_priv_create('add_freelance_skillconfs','Project Managers');
select im_priv_create('add_freelance_skillconfs','Freelance Managers');



