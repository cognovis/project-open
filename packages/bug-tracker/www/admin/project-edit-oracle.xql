<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="project_search">
  <querytext>
        select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
        from   cc_users u
        where  upper(nvl(u.first_names || ' ', '') 
               || nvl(u.last_name || ' ', '')
               || u.email || ' ' ||
               nvl(u.screen_name, '')) like upper('%'||:value||'%')
        order  by name
  </querytext>
</fullquery>
 
</queryset>
