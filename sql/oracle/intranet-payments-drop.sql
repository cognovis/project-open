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


BEGIN
    im_component_plugin.del_module(module_name => 'intranet-payments');
    im_menu.del_module(module_name => 'intranet-payments');
END;
/
commit;

delete from im_view_columns where column_id > 3200 and column_id < 3299;
delete from im_views where view_id=32;

drop sequence im_payments_id_seq;
drop trigger im_payments_audit_tr;
drop view im_payment_type;
drop view im_invoice_payment_method;

drop table im_payments_audit;
drop table im_payments;

delete from im_categories where category_id >= 1000 and category_id < 1100;
