<?xml version="1.0"?>
<queryset>

<fullquery name="spam_get_party_list">      
      <querytext>

    select email, first_names || ' ' || last_name as name
      from parties
      left join persons on parties.party_id = person_id
      join ($sql_query) p2 on p2.party_id = parties.party_id

      </querytext>
</fullquery>

 
</queryset>
