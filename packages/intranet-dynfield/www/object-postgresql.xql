<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_previous_sort_orders">
  <querytext>
        update contact_attribute_object_map set sort_order = '-1' where object_id = :object_id
  </querytext>
</fullquery>

<fullquery name="get_attributes">
  <querytext>
        select attribute_id from contact_attribute_object_map where object_id = :object_id 
  </querytext>
</fullquery>

<fullquery name="update_sort_order">
  <querytext>
        update contact_attribute_object_map set sort_order = :sort_order_temp where object_id = :object_id and attribute_id = :attribute_id
  </querytext>
</fullquery>


</queryset>
