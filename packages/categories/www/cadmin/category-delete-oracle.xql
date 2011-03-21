<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="check_mapped_objects">      
      <querytext>
      
    select case when count(*) = 0 then 0 else 1 end from dual
    where exists (select 1 from category_object_map
                  where category_id = :id)

      </querytext>
</fullquery>

 
</queryset>
