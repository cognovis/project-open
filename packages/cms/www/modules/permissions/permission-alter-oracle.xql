<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select 
    acs_object.name(:object_id) as object_name, 
    acs_object.name(:grantee_id) as grantee_name,
    acs_permission.permission_p(:object_id, :user_id, 'cm_perm') as user_cm_perm
  from
    dual
      </querytext>
</fullquery>

 
</queryset>
