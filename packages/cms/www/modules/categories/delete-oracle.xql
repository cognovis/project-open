<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_keyword">      
      <querytext>
      begin :1 := content_keyword.del(:id); end;
      </querytext>
</fullquery>

 
<fullquery name="get_empty_status">      
      <querytext>
      
  select content_keyword.is_leaf(:id) from dual

      </querytext>
</fullquery>

 
</queryset>
