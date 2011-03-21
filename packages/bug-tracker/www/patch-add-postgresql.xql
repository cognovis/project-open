<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_patch">
  <querytext>
    
            select bt_patch__new(
                :patch_id,
                :package_id,
                :component_id,
                :summary,
                :description,
                :description_format,
                :content,
                :version_id,
                :user_id,
                :ip_address
            )

  </querytext>
</fullquery>


</queryset>
