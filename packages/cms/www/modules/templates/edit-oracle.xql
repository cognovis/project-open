<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_path">      
      <querytext>

        select content_item.get_path(:template_id) from dual

      </querytext>
</fullquery>
 
</queryset>
