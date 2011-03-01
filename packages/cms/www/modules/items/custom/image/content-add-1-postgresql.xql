<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="update_revisions">      
      <querytext>

      update cr_revisions
        set content = empty_lob()
        where revision_id = $revision_id

      </querytext>
</fullquery>

 
</queryset>
