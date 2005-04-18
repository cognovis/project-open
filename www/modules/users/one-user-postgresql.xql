<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select
    p.first_names, p.last_name, 
    pp.email, pp.url, 
    u.screen_name,
    to_char(u.last_visit, 'YYYY/MM/DD HH24:MI') as last_visit,
    to_char(u.no_alerts_until, 'YYYY/MM/DD') as no_alerts_until
  from
    persons p, parties pp, users u
  where
    p.person_id = :id
  and
    pp.party_id = :id
  and
    u.user_id = :id

      </querytext>
</fullquery>

 
</queryset>
