<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="spam_get_party_list">      
      <querytext>
      
    select email, first_names || ' ' || last_name as name
      from parties, ($sql_query) p2, persons
    where parties.party_id = person_id(+) 
      and p2.party_id = parties.party_id

      </querytext>
</fullquery>

 
</queryset>
