<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="relate">      
      <querytext>
      begin 
      :rel_id := content_item.relate (
          item_id       => :item_id,
          object_id     => :related_id,
          relation_tag  => :relation_tag,
          order_n       => :order_n,
          relation_type => :relation_type
      );
    end;
      </querytext>
</fullquery>

 
<fullquery name="get_title">      
      <querytext>
      
  select content_item.get_title(:item_id) from dual
      </querytext>
</fullquery>

 
</queryset>
