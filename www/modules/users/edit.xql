<?xml version="1.0"?>
<queryset>

<fullquery name="edit_group_1">      
      <querytext>
      
    update groups 
      set group_name = :group_name
      where group_id = :group_id
      </querytext>
</fullquery>

 
<fullquery name="edit_group_2">      
      <querytext>
      
    update parties
      set email = :email, url = :url
      where party_id = :group_id
      </querytext>
</fullquery>

<fullquery name="get_group_info">      
      <querytext>

    select
      g.group_name, p.url, p.email
    from
      groups g, parties p
    where
      g.group_id = :id
    and
      p.party_id = :id

     </querytext>
</fullquery>
 
</queryset>
