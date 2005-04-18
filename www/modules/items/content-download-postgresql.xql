<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select
    item_id, mime_type, content_revision__is_live( revision_id ) as is_live
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
