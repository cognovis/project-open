-- Drop the cal_item object and all related tables, 
-- views, and package
--
-- @author Gary Jin (gjin@arsdigita.com)
-- @creation-date Nov 17, 2000
-- @cvs-id $Id$
--


---------------------------------------------------------- 
--  drop cal_item
----------------------------------------------------------

  -- drop attributes and acs_object_type
begin
  acs_attribute.drop_attribute ('cal_item','on_which_calendar');
  acs_object_type.drop_type ('cal_item');
end;
/
show errors


  -- drop package	  
drop package cal_item;


drop index cal_items_on_which_cal_idx;

  -- drop table  
drop table cal_items;



