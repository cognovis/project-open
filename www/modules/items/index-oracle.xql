<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_item_id">      
      <querytext>
      
  select content_symlink.resolve(:item_id) from dual

      </querytext>
</fullquery>

 
</queryset>
