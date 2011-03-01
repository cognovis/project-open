-- /packages/intranet-search-pg/sql/postgres/intranet-search-pg-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author pepels@gmail.com
-- @author frank.bergmann@project-open.com
-- @author toni.vila@project-open.com

select im_menu__del_module('intranet-search-pg');
select im_component_plugin__del_module('intranet-search-pg');

drop trigger im_forum_topics_tsearch_tr on im_forum_topics;
drop trigger im_projects_tsearch_tr on im_projects;
drop trigger im_companies_tsearch_tr on im_companies;
drop trigger persons_tsearch_tr on persons;
drop trigger im_invoices_tsearch_tr on im_invoices;


drop function im_forum_topics_tsearch ();
drop function persons_tsearch ();
drop function im_projects_tsearch ();
drop function im_companies_tsearch ();
drop function im_search_update (integer, varchar, integer, varchar);
drop function norm_text (varchar);
drop function norm_text_utf8 (varchar);

drop table im_search_objects;
drop table im_search_object_types;


-- Dont uninstall TSearch2.
-- Done by TCL script during SysConfig
-- \i untsearch2.sql

