-- /packages/intranet-expenses/sql/postgresql/intranet-expenses-drop.sql
--
-- Project/Open intranet Expenses Core
-- 060419 avila@digiteix.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


delete from im_expenses;
delete from im_costs where cost_id in (select object_id from acs_objects where object_type = 'im_expenses');
delete from acs_objects where object_type = 'im_expenses';



-------------------------------------------------------------
-- Intranet Expenses Type

drop view im_expense_payment_type;
drop view im_expense_type;

delete from im_category_hierarchy where (parent_id >= 4000 and parent_id < 4100) or (child_id >= 4000 and child_id < 4100);
delete from im_categories where category_id >= 4000 and category_id < 4100;

delete from im_category_hierarchy where (parent_id >= 4100 and parent_id < 4200) or (child_id >= 4100 and child_id < 4200);
delete from im_categories where category_id >= 4100 and category_id < 4200;

delete from im_biz_object_urls where object_type='im_expense';


---------------------------------------------------------------
-- drop menu item

-- BEGIN
    select im_menu__del_module('intranet-expenses');
    select im_component_plugin__del_module('intranet-expenses');
-- END;



-------------------------------------------------------------
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
   select inline_revoke_permission ('view_expenses_all');
   select acs_privilege__drop_privilege ('view_expenses_all');

   select inline_revoke_permission ('view_expenses');
   select acs_privilege__drop_privilege ('view_expenses');

   select inline_revoke_permission ('add_expense_invoice');
   select acs_privilege__drop_privilege ('add_expense_invoice');

   select inline_revoke_permission ('add_expenses');
   select acs_privilege__drop_privilege ('add_expenses');

-- end;


-- Drop tables

   drop table im_expenses;

-- Drop object types

-- begin
   select acs_object_type__drop_type('im_expense', 'f');
-- end;