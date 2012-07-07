<?xml version="1.0"?>
<queryset>

<fullquery name="get_num_recipients">      
      <querytext>
      
    select count(*) from ($sql_query) user_query

      </querytext>
</fullquery>

<fullquery name="spam_get_party_list">      
      <querytext>

    select 
	parties.email, 
	persons.first_names || ' ' || persons.last_name as name
    from
	parties
      	left join persons on parties.party_id = person_id
        join ($sql_query) p2 on p2.party_id = parties.party_id

      </querytext>
</fullquery>

 
</queryset>
