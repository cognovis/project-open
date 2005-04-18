<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_folder">      
      <querytext>
      begin content_folder.del(:id); end;
      </querytext>
</fullquery>

 
<fullquery name="check_empty">      
      <querytext>
      
  select content_folder.is_empty(:id) from dual

      </querytext>
</fullquery>

 
</queryset>
