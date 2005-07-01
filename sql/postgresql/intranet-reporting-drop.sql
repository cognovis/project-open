-- /packages/intranet-invoices/sql/postgresql/intranet-reporting-drop.sql
--
-- Copyright (C) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- BEGIN
    select im_menu__del_module('intranet-reporting');
-- END;
-- 
-- commit;

delete from im_biz_object_urls where object_type='im_invoice';
select acs_object_type__drop_type('im_report', 'f');
delete from acs_rels where object_id_two in (select report_id from im_reports);
delete from im_report_variables;
delete from im_reports;

-- drop sequence im_report_variables_seq;
drop sequence im_report_variables_seq;

-- drop tables
drop table im_report_variables;
drop table im_reports;


