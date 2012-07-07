<?xml version="1.0"?>
<queryset>

<fullquery name="spam_check_double_click">      
      <querytext>
      
  select count(1) from spam_messages where spam_id=:spam_id
      </querytext>
</fullquery>

 
</queryset>
