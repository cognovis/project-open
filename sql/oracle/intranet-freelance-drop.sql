-- /packages/intranet-freelance/sql/oracle/intranet-freelance-drop.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com

-----------------------------------------------------
-- Drop menus and components defined by the module

BEGIN
    im_menu.del_module(module_name => 'intranet-freelance');
END;
/

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-freelance');
END;
/
commit;


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

-- Freelance LOC Tools & Operating Systems
delete from im_categories where category_id >= 2300 and category_id < 2400;

-- Languages experience
delete from im_categories where category_id >= 2200 and category_id < 2300;

-- Freelance TM Tools
delete from im_categories where category_id >= 2100 and category_id < 2200;

-- Freelance Skill Types
delete from im_categories where category_id >= 2000 and category_id < 2100;

delete from im_views where view_id >= 50 and view_id < 60;

drop function im_freelance_skill_list;
drop view im_freelance_skill_types;
drop table im_freelance_skills;
drop table im_freelancers;
