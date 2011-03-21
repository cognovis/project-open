<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="update_revisions">      
      <querytext>
      
      update cr_revisions
        set content = empty_blob()
        where revision_id = $revision_id
        returning content into :1
      </querytext>
</fullquery>

 
</queryset>
