-- /packages/intranet-forum/sql/oracle/intranet-forum-sc-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
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
drop trigger users_tsearch_tr on users;
drop trigger im_invoices_tsearch_tr on im_invoices;


drop function im_forum_topics_tsearch ();
drop function users_tsearch ();
drop function im_projects_tsearch ();
drop function im_companies_tsearch ();
drop function im_search_update (integer, varchar, integer, varchar);

drop table im_search_objects;
drop table im_search_object_types;

delete from im_biz_object_urls
where object_type = 'im_forum_topic';

-- Now use a modified drop script to get tsearch2
-- out of the database again.

\i untsearch2.sql

