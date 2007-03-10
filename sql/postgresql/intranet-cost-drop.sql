-- /packages/intranet-cost/sql/oracle/intranet-cost-drop.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

select im_menu__del_module('intranet-cost');
select im_component_plugin__del_module('intranet-cost');



--------------------------------------------------------------

DROP TRIGGER im_projects_project_cache_del_tr ON im_projects;
DROP TRIGGER im_projects_project_cache_up_tr ON im_projects;
DROP TRIGGER im_costs_project_cache_del_tr ON im_costs;
DROP TRIGGER im_costs_project_cache_up_tr ON im_costs;
DROP TRIGGER im_costs_project_cache_ins_tr ON im_costs;

drop function im_cost_project_cache_invalidator (integer);

drop function im_cost_project_cache_up_tr ();
drop function im_cost_project_cache_del_tr ();
drop function im_cost_project_cache_ins_tr ();
drop function im_project_project_cache_up_tr ();
drop function im_project_project_cache_del_tr ();




--------------------------------------------------------------


alter table im_projects drop column cost_quotes_cache;
alter table im_projects drop column cost_invoices_cache;
alter table im_projects drop column cost_timesheet_pladned_cache;

alter table im_projects drop column cost_purchase_orders_cache;
alter table im_projects drop column cost_bills_cache;
alter table im_projects drop column cost_timesheet_logged_cache;


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
  



-------------------------------------------------------------
-- Cost Centers

drop view im_departments;
delete from im_category_hierarchy where (parent_id >= 3000 and parent_id < 3100) or (child_id >= 3000 and child_id < 3100);
delete from im_categories where category_id >= 3000 and category_id < 3100;
delete from im_category_hierarchy where (parent_id >= 3100 and parent_id < 3200) or (child_id >= 3100 and child_id < 3200);
delete from im_categories where category_id >= 3100 and category_id < 3200;


delete from im_biz_object_urls where object_type='im_cost_center';

-- drop package im_cost_center;
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


-------------------------------------------------------------
-- Costs

delete from im_view_columns where view_id in (220, 221);
delete from im_views where view_id in (220, 221);

-- before remove priviliges remove granted permissions
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
BEGIN
     lock table acs_permissions_lock;

     delete from acs_permissions
     where privilege = p_priv_name;
     delete from acs_privilege_hierarchy
     where child_privilege = p_priv_name;
     return 0;

end;' language 'plpgsql';

-- begin
   select inline_revoke_permission ('view_costs');
   select acs_privilege__drop_privilege ('view_costs');
   select inline_revoke_permission ('add_costs');
   select acs_privilege__drop_privilege ('add_costs');
-- end;


delete from im_biz_object_urls where object_type='im_cost';

-- drop package im_cost;

drop view im_cost_status;
drop view im_cost_types;
delete from im_category_hierarchy where (parent_id >= 3700 and parent_id < 3799) or (child_id >= 3700 and child_id < 3799);
delete from im_categories where category_id >= 3700 and category_id < 3799;
delete from im_category_hierarchy where (parent_id >= 3800 and parent_id < 3899) or (child_id >= 3800 and child_id < 3899);
delete from im_categories where category_id >= 3800 and category_id < 3899;



-------------------------------------------------------------
-- "Investments"

delete from im_category_hierarchy where (parent_id >= 3500 and parent_id < 3599) or (child_id >= 3500 and child_id < 3599);
delete from im_categories where category_id >= 3500 and category_id < 3599;
delete from im_category_hierarchy where (parent_id >= 3400 and parent_id < 3500) or (child_id >= 3400 and child_id < 3500);
delete from im_categories where category_id >= 3400 and category_id < 3500;

delete from im_biz_object_urls where object_type='im_investment';


-- begin
delete from im_biz_object_urls where object_type = 'im_cost_center';
-- end;

-- Drop tables

drop table im_investments;
drop table im_repeating_costs;
drop table im_costs;
drop table im_prices;
drop table im_cost_centers;

-- Drop object types

-- begin
select acs_object_type__drop_type('im_investment', 'f');
select acs_object_type__drop_type('im_repeating_cost', 'f');
select acs_object_type__drop_type('im_cost', 'f');
select acs_object_type__drop_type('im_cost_center','f');
-- end;