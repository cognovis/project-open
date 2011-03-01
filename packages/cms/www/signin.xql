<?xml version="1.0"?>
<queryset>

<fullquery name="get_info">      
      <querytext>
      select user_id, salt, password 
      from users
      where screen_name = :screen_name      

      </querytext>
</fullquery>

 
</queryset>
