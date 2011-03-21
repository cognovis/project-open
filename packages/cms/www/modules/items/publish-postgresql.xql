<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="set_live_revision">      
      <querytext>

       select content_item__set_live_revision( 
         :revision_id 
       );
    
      </querytext>
</fullquery>

 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select
    item_id,
    content_item__is_publishable( item_id ) as publish_p
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
