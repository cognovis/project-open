-- upgrade-4.0.3.4.0-4.0.3.4.1.sql

SELECT acs_log__debug('/packages/intranet-mail-import/sql/postgresql/upgrade/upgrade-4.0.3.4.0-4.0.3.4.1.sql','');

-- Access permission 'Mail Dispatcher' 
select acs_privilege__create_privilege('admin_mail_dispatcher','Admin Mail Dispatcher','Admin Mail Dispatcher');
select acs_privilege__add_child('admin', 'admin_mail_dispatcher');

select im_priv_create('admin_mail_dispatcher', 'P/O Admins');
select im_priv_create('admin_mail_dispatcher', 'Senior Managers');

-- View mails all 
select acs_privilege__create_privilege('view_mails_all','View Mails All','View Mails All');
select acs_privilege__add_child('admin', 'view_mails_all');

select im_priv_create('view_mails_all', 'P/O Admins');
select im_priv_create('view_mails_all', 'Senior Managers');
