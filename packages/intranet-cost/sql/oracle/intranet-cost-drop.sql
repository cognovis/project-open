-- /packages/intranet-cost/sql/oracle/intranet-cost-drop.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

BEGIN
    im_menu.del_module(module_name => 'intranet-cost');
    im_component_plugin.del_module(module_name => 'intranet-cost');
END;
/
show errors

commit;


delete from im_view_columns where view_id >= 220 and view_id <= 229;
delete from im_views where view_id >= 220 and view_id <= 229;


delete from im_prices;
delete from im_repeating_costs;
delete from im_costs;
delete from acs_objects where object_type = 'im_cost';
delete from im_investments;
delete from acs_objects where object_type = 'im_investment';
delete from im_cost_centers;
delete from acs_objects where object_type = 'im_cost_center';


-------------------------------------------------------------
-- Costs

delete from im_view_columns where view_id in (220, 221);
delete from im_views where view_id in (220, 221);


begin
    acs_privilege.drop_privilege('view_costs');
    acs_privilege.drop_privilege('add_costs');
end;
/

delete from im_biz_object_urls where object_type='im_cost';

drop package im_cost;

drop view im_cost_status;
drop view im_cost_type;
delete from im_category_hierarchy where (parent_id >= 3700 and parent_id < 3799) or (child_id >= 3700 and child_id < 3799);
delete from im_categories where category_id >= 3700 and category_id < 3799;
delete from im_category_hierarchy where (parent_id >= 3800 and parent_id < 3899) or (child_id >= 3800 and child_id < 3899);
delete from im_categories where category_id >= 3800 and category_id < 3899;

drop table im_costs;

-------------------------------------------------------------
-- "Investments"

delete from im_category_hierarchy where (parent_id >= 3500 and parent_id < 3599) or (child_id >= 3500 and child_id < 3599);
delete from im_categories where category_id >= 3500 and category_id < 3599;
delete from im_category_hierarchy where (parent_id >= 3400 and parent_id < 3500) or (child_id >= 3400 and child_id < 3500);
delete from im_categories where category_id >= 3400 and category_id < 3500;

delete from im_biz_object_urls where object_type='im_investment';
begin
	acs_object_type.drop_type('im_investment', 'f');
end;
drop table im_investments;

begin
    acs_object_type.drop_type(object_type => 'im_cost_center');
end;
/

-------------------------------------------------------------
-- Repeating Costs
delete from im_category_hierarchy where parent_id in
       (select category_id from im_categories where category_type = 'Intranet Investment Type')
or child_id in
        (select category_id from im_categories where category_type = 'Intranet Investment Type');
delete from im_categories where category_type = 'Intranet Investment Type';
delete from im_category_hierarchy where parent_id in
       (select category_id from im_categories where category_type = 'Intranet Investment Status')
or child_id in
        (select category_id from im_categories where category_type = 'Intranet Investment Status');
delete from im_categories where category_type = 'Intranet Investment Status';

delete from im_biz_object_urls where object_type='im_cost';
begin
	acs_object_type.drop_type('im_cost', 'f');
end; 
drop table im_prices;

drop table im_repeating_costs;



-------------------------------------------------------------
-- Cost Centers

drop view im_departments;
delete from im_category_hierarchy where (parent_id >= 3000 and parent_id < 3100) or (child_id >= 3000 and child_id < 3100);
delete from im_categories where category_id >= 3000 and category_id < 3100;
delete from im_category_hierarchy where (parent_id >= 3100 and parent_id < 3200) or (child_id >= 3100 and child_id < 3200);
delete from im_categories where category_id >= 3100 and category_id < 3200;


delete from im_biz_object_urls where object_type='im_cost_center';

drop table im_cost_centers;
drop package im_cost_center;
delete from im_category_hierarchy where parent_id in
       (select category_id from im_categories where category_type = 'Intranet Cost Center Type')
or child_id in
        (select category_id from im_categories where category_type = 'Intranet Cost Center Type');
delete from im_categories where category_type = 'Intranet Cost Center Type';
delete from im_category_hierarchy where parent_id in
       (select category_id from im_categories where category_type = 'Intranet Cost Center Status')
or child_id in
        (select category_id from im_categories where category_type = 'Intranet Cost Center Status');
delete from im_categories where category_type = 'Intranet Cost Center Status';

begin
    acs_object_type.drop_type(object_type => 'im_cost_center');
end;
/
