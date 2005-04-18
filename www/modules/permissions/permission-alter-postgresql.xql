<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select 
    acs_object__name(:object_id) as object_name, 
    acs_object__name(:grantee_id) as grantee_name,
    acs_permission__permission_p(:object_id, :user_id, 'cm_perm') as user_cm_perm
  from
    dual
      </querytext>
</fullquery>

 
</queryset>
