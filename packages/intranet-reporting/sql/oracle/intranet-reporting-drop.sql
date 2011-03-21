-- /packages/intranet-invoices/sql/oracle/intranet-invoices-drop.sql
--
-- Copyright (C) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


BEGIN
    select im_menu.del_module('intranet-invoices');
END;
-- 
commit;

delete from im_report_variables;
delete from im_reports;
delete from acs_rels where object_id_two in (select report_id from im_reports);

-- drop sequence im_report_variables_seq;
drop sequence im_report_variables_seq;

-- drop tables
drop table im_report_variables;
drop table im_reports;

delete from acs_permissions 
where object_id in (
		select object_id 
		from acs_objects 
		where object_type='im_report'
);
delete from acs_objects where object_type='im_report';
drop package im_report;
begin
    acs_object_type.drop_type('im_report');
end;
/

commit;
