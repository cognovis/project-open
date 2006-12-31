-- Drop the cal_item object and all related tables, 
-- views, and package
--
-- @author Gary Jin (gjin@arsdigita.com)
-- @creation-date Nov 17, 2000
-- @cvs-id $Id$
--

-- ported by Lilian Tong (tong@ebt.ee.usyd.edu.au)

---------------------------------------------------------- 
--  drop cal_item
----------------------------------------------------------

-- drop functions
drop function cal_item__new (
    integer,
    integer,
    varchar,
    varchar,
    boolean,
    varchar,
    integer,
    integer,
    integer,
    varchar,
    integer,
    timestamptz,
    integer,
    varchar
);

drop function cal_item__delete (integer);

drop index cal_items_on_which_calendar_idx;

drop table cal_items;
--drop objects
delete from acs_objects where object_type='cal_item';

  -- drop attributes and acs_object_type
begin;
  -- drop attibutes
	select acs_attribute__drop_attribute (
           'cal_item',
           'on_which_calendar'
        );
  
  --drop type
	select acs_object_type__drop_type(
           'cal_item',
           'f'
        );  
end;

