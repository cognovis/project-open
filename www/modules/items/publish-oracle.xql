<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="set_live_revision">      
      <querytext>
      
     begin 
       content_item.set_live_revision( 
         revision_id => :revision_id 
       );
     end;
      </querytext>
</fullquery>

 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select
    item_id,
    content_item.is_publishable( item_id ) as publish_p
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
