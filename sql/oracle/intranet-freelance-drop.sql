-- /packages/intranet-freelance/sql/oracle/intranet-freelance-drop.sql
--
-- Removes the freelance data model from the database
--
-- @author Frank Bergmann (fraber@fraber.de)
-- @author guillermo.belcic@project-open.com
--


-----------------------------------------------------
-- Drop menus and components defined by the module

BEGIN
    im_menu.del_module(module_name => 'intranet-freelance');
END;
/
show errors



BEGIN
    im_component_plugin.del_module(module_name => 'intranet-freelance');
END;
/
show errors

commit;



-- 'user_view_freelance'
delete from im_view_columns where column_id >= 5100 and column_id < 5199;

-- 'user_list_freelance'
delete from im_view_columns where column_id >= 5000 and column_id < 5099;

-- Freelance LOC Tools & Operating Systems
delete from categories where category_id >= 2300 and category_id < 2400;

-- Languages experience
delete from categories where category_id >= 2200 and category_id < 2300;

-- Freelance TM Tools
delete from categories where category_id >= 2100 and category_id < 2200;

-- Freelance Skill Types
delete from categories where category_id >= 2000 and category_id < 2100;

delete from im_views where view_id >= 50 and view_id < 60;

drop function im_freelance_skill_list;
drop view im_freelance_skill_types;
drop table im_freelance_skills;
drop table im_freelancers;
