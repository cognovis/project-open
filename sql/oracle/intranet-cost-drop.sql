-- /packages/intranet-cost/sql/oracle/intranet-cost-drop.sql
--
-- Project/Open Cost Core
-- 040207 fraber@fraber.de
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

delete from im_centers;
drop table im_centers;
drop package im_center;

-- we don't touch the categories here, because they
-- are taken care of in the *-create.sql script, because
-- they are changes so frequently.
-- delete from categories where category_id >= 3000 and category_id < 3200;



begin
    acs_object_type.drop_type(object_type => 'im_center');
end;
/

delete from acs_objects where object_type='im_center';

