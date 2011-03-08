<?xml version="1.0"?>
<queryset>

<fullquery name="get_user_info">      
      <querytext>

    select
      p.first_names, p.last_name, 
      pp.email, pp.url, 
      u.screen_name,
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


<fullquery name="edit_user_1">      
      <querytext>
      
    update users $users_update where user_id = :item_id
  
      </querytext>
</fullquery>

 
<fullquery name="edit_user_2">      
      <querytext>
      
    update persons set first_names=:first_names, last_name = :last_name 
      where person_id=:item_id
  
      </querytext>
</fullquery>

 
<fullquery name="edit_user_3">      
      <querytext>
      
    update parties set email=:email, url=:url where party_id = :item_id
  
      </querytext>
</fullquery>

 
</queryset>
