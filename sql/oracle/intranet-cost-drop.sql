-- /packages/intranet-cost/sql/oracle/intranet-cost-drop.sql
--
-- Project/Open Cost Core
-- 040207 fraber@fraber.de
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

drop table im_repeating_costs;
drop table im_prices;
drop table im_costs;
drop table im_investments;
drop table im_cost_centers;

drop package im_cost;
drop package im_cost_center;

delete from im_categories where category_type = 'Intranet Cost Center Type';
delete from im_categories where category_type = 'Intranet Cost Center Status';
delete from im_categories where category_type = 'Intranet Investment Type';
delete from im_categories where category_type = 'Intranet Investment Status';


begin
    acs_object_type.drop_type(object_type => 'im_cost_center');
end;
/
