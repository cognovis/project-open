<?xml version="1.0"?>

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="object_name_for_one_object_id">
    <querytext>select acs_object__name(:object_id) from dual</querytext>
  </fullquery>

  <fullquery name="spam_full_sql">
      <querytext>

    select
	parties.email as user_email,
	persons.first_names as user_first_names, 
	persons.last_name as user_last_name,
	persons.first_names || ' ' || persons.last_name as user_name
    from
	parties
      	left join persons on parties.party_id = person_id
    where
	parties.party_id in ($sql_query)

      </querytext>
  </fullquery>

</queryset>
