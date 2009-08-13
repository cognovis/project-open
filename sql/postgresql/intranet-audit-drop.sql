-- /packages/intranet-audit/sql/postgresql/intranet-audit-create.sql
--
-- Copyright (c) 2007 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-audit');
select  im_menu__del_module('intranet-audit');


-----------------------------------------------------------
-- Drop main structures info

-- Drop functions
drop table im_audits;

-- Drop ID sequence
drop sequence im_audit_seq;


