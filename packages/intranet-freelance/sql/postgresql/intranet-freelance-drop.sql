-- /packages/intranet-freelance/sql/oracle/intranet-freelance-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

-----------------------------------------------------
-- Drop menus and components defined by the module

select    im_menu__del_module('intranet-freelance');

select    im_component_plugin__del_module('intranet-freelance');



-----------------------------------------------------------
-- Menu Modifications
--
-- Modify the menu back to the original "Users" / "Freelancers" 
-- entry
update im_menus
set url='/intranet/users/index?user_group_name=Freelancers'
where label='users_freelancers';



-----------------------------------------------------------
-- Delete Views

-- 'user_view_freelance'
delete from im_view_columns where column_id >= 5100 and column_id < 5199;

-- 'user_list_freelance'
delete from im_view_columns where column_id >= 5000 and column_id < 5099;


delete from im_view_columns where view_id >= 50 and view_id < 60;
delete from im_views where view_id >= 50 and view_id < 60;




-----------------------------------------------------------
-- Delete Categories


delete from im_freelance_skills;


-- Freelance LOC Tools & Operating Systems
delete from im_categories where category_id >= 2300 and category_id < 2400;

-- Languages experience
delete from im_categories where category_id >= 2200 and category_id < 2300;

-- Freelance TM Tools
delete from im_categories where category_id >= 2100 and category_id < 2200;

-- Freelance Skill Types
delete from im_categories where category_id >= 2000 and category_id < 2100;


-----------------------------------------------------------
-- Delete Views


drop function im_freelance_skill_list (integer, integer);
drop view im_freelance_skill_types;
drop table im_freelance_skills;
drop table im_freelancers;



-----------------------------------------------------------
-- Remove backup views
--
delete from im_view_columns where view_id = 120;
delete from im_views where view_id = 120;

delete from im_view_columns where view_id = 121;
delete from im_views where view_id = 121;
