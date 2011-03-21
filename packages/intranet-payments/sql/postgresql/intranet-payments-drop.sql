-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
--
-- This program is free software. You can redistribute it 
-- and/or modify it under the terms of the GNU General 
-- Public License as published by the Free Software Foundation; 
-- either version 2 of the License, or (at your option) 
-- any later version. This program is distributed in the 
-- hope that it will be useful, but WITHOUT ANY WARRANTY; 
-- without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU General Public License for more details.

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
   select inline_revoke_permission ('view_payments');
   select acs_privilege__drop_privilege ('view_payments');
   select inline_revoke_permission ('add_payments');
   select acs_privilege__drop_privilege ('add_payments');
-- end;


-- BEGIN
    select im_component_plugin__del_module('intranet-payments');
    select im_menu__del_module('intranet-payments');
-- END;

-- commit;

delete from im_view_columns where column_id > 3200 and column_id < 3299;
delete from im_views where view_id=32;

drop sequence im_payments_id_seq;
-- fraber 050225: Disabled because of problems with PostgreSQL
-- to delete payments
-- drop trigger im_payments_audit_tr on im_payments;
-- drop function im_payments_audit_tr ();
drop view im_payment_type;
drop view im_invoice_payment_method;

drop table im_payments_audit;
drop table im_payments;

delete from im_categories where category_id >= 1000 and category_id < 1100;
